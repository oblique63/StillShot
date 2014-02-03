library stillshot;

import "dart:io";
import "package:path/path.dart" as path;
import "package:markdown/markdown.dart" as md;
import "package:mustache/mustache.dart" as mustache;
import "package:yaml/yaml.dart" as yaml;
import "package:intl/intl.dart";

/**
* Takes a template string (such as a Mustache template) and renders it out to an HTML string
* using the given input values/options.
*/
typedef String
TemplateRenderer(String template, Map options);

/**
* Can be set to define a custom [rendering function](TemplateRenderer) to handle your template files
* and use any templating language of your choice.
*
* Uses [Mustache templates](https://pub.dartlang.org/packages/mustache) by default.
*/
TemplateRenderer
renderTemplate = (String template, Map options) =>
    mustache.parse(template).renderString(options, htmlEscapeValues: false);

/**
* Contains global values/variables that may be used within all pages of the site.
* Values may be accessed in templates using the `_site` var. E.g. `{{ _site.date_format }}`
*
* Here are some options that are set by default:
* * `content_dir: 'content'`
* * `template_dir: 'templates'`
* * `output_dir: 'web'`
* * `date_format: 'yMd'` (see [DateFormat] for possible formatting options)
* * `markdown_templating: true`  Enables the use of template tags within markdown files (may not work when overriding [renderTemplate])
*/
Map
SITE_OPTIONS = {};

/// Render and output your static site (overwrites existing HTML files in output directory).
void
generate() {
    print("======== StillShot ========");
    print("Generating site...\n");

    File options_file = new File('site.yaml');
    Map yaml_options = {};
    try {
        yaml_options = yaml.loadYaml(options_file.readAsStringSync());
    }
    catch (e) {
        /// No site.yaml file specified
    }

    // TODO: provide a way to modify site.yaml values from dart, without just overwriting them

    yaml_options.forEach((key, value) =>
        SITE_OPTIONS.putIfAbsent(key, () => value));

    SITE_OPTIONS
        ..putIfAbsent('content_dir', () => 'content')
        ..putIfAbsent('template_dir', () => 'templates')
        ..putIfAbsent('output_dir', () => 'web')
        ..putIfAbsent('date_format', () => 'yMd')
        ..putIfAbsent('markdown_templating', () => true);

    /// See [DateFormat](https://api.dartlang.org/docs/channels/stable/latest/intl/DateFormat.html) for formatting options
    DateFormat date_format = new DateFormat(SITE_OPTIONS['date_format']);

    Directory content_dir = new Directory(SITE_OPTIONS['content_dir']);
    Directory template_dir = new Directory(SITE_OPTIONS['template_dir']);
    Directory output_dir = new Directory(SITE_OPTIONS['output_dir']);

    // TODO: support directory hierarchies for markdown, templates and output
    List<File> markdown_files = content_dir.listSync().where(
            (file) => file is File && (file.path.endsWith('.md') || file.path.endsWith(".markdown")));

    List<File> templates = template_dir.listSync().where((file) => file is File);

    for (File file in markdown_files) {
        // TODO: provide a way to access the list of pages with filenames and titles from a _site var

        String filename = path.basenameWithoutExtension(file.path);
        String filepath = path.normalize(file.path);

        print("Reading\t'$filepath'");

        List<String> lines = file.readAsLinesSync();

        Map page_options = {};

        if ( lines.any((line) => line.startsWith("~~~") && line.endsWith("~")) ) {
            List raw_options = lines.takeWhile((line) => !line.startsWith("~~~"));
            page_options = yaml.loadYaml(raw_options.join('\n'));

            lines.removeRange(0, raw_options.length+1); // +1 for the "~~~" line
        }

        page_options.putIfAbsent('title', () => filename);

        page_options['_site'] = SITE_OPTIONS;

        if (page_options.containsKey('date_format')) {
            DateFormat page_date_format = new DateFormat(page_options['date_format']);
            page_options['_date'] = page_date_format.format( file.lastModifiedSync() );
        }
        else {
            page_options['_date'] = date_format.format( file.lastModifiedSync() );
        }

        String content = lines.join('\n');

        if (SITE_OPTIONS['markdown_templating']
        || (page_options.containsKey('markdown_templating')
        && page_options['markdown_templating'])) {

                content = renderTemplate(content, page_options);
        }

        page_options['_content'] = md.markdownToHtml(content);

        File template;
        try {
            if (page_options.containsKey('template')) {
                template = templates.firstWhere(
                    (temp) => path.basenameWithoutExtension(temp.path) == page_options['template']);
            }
            else if (SITE_OPTIONS.containsKey('default_template')) {
                template = templates.firstWhere(
                    (temp) => path.basenameWithoutExtension(temp.path) == SITE_OPTIONS['default_template']);
            }
            else {
                template = templates.firstWhere(
                    (temp) => path.basenameWithoutExtension(temp.path) == filename);
            }
        }
        catch(e) { throw "No template given for '$filepath!"; }

        print("Using\t'${path.normalize(template.path)}'");

        String template_str = template.readAsStringSync();

        String output_str = _fixPathRefs( renderTemplate(template_str, page_options) );

        File output_file = new File("${output_dir.path}/$filename.html");

        print("Writing\t'${path.normalize(output_file.path)}'\n");

        output_file.openWrite()
                   ..write(output_str)
                   ..close();
    }

    print("Done!");
}

/**
* Redirect resource links using relative paths to the output directory.
* Currently only supports replacing Unix-style relative paths.
*/
String
_fixPathRefs(String html) {
    String relative_output = path.relative(SITE_OPTIONS['output_dir'], from: SITE_OPTIONS['template_dir']);

    relative_output = "$relative_output/".replaceAll("\\", "/");

    html = html.replaceAll('src="$relative_output', 'src="')
               .replaceAll('href="$relative_output', 'href="');

    return html;
}