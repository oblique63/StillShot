library stillshot;

import "dart:io";
import "package:path/path.dart" as path;
import "package:markdown/markdown.dart" as md;
import "package:mustache/mustache.dart" as mustache;
import "package:yaml/yaml.dart" as yaml;
import "package:intl/intl.dart";

part 'logging.dart';

/**
 * Takes a template string (such as a Mustache template) and renders it out to an HTML string
 * using the given input values/options.
 */
typedef String TemplateRenderer(String template, Map options);

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
* * `workspace_dir: '.'`  The site/project root directory. May only be overwritten from a build file.
* * `content_dir: 'content'`
* * `template_dir: 'templates'`
* * `output_dir: 'web'`
* * `date_format: 'yMd'` (see [DateFormat] for possible formatting options)
* * `markdown_templating: true`  Enables the use of template tags within markdown files (may not work when overriding [renderTemplate])
* * `yaml_block_delimiter: '~~~'` Delimiter string that separates a YAML-block from the rest of the content in a markdown file
*/
Map
SITE_OPTIONS = {
    'workspace_dir': '.'
};

/// Render and output your static site (WARNING: overwrites existing HTML files in output directory).
void
generate() {
    _logStarting();

    _paresOptionsFile(path.absolute(SITE_OPTIONS['workspace_dir'], 'site.yaml'));
    _fillInDefaultSiteOptions();

    if (SITE_OPTIONS['workspace_dir'] != '.') {
        _logEnvironment(SITE_OPTIONS['workspace_dir']);
    }

    var content_dir = new Directory(path.absolute(SITE_OPTIONS['workspace_dir'], SITE_OPTIONS['content_dir']));
    var template_dir = new Directory(path.absolute(SITE_OPTIONS['workspace_dir'], SITE_OPTIONS['template_dir']));
    var output_dir = new Directory(path.absolute(SITE_OPTIONS['workspace_dir'], SITE_OPTIONS['output_dir']));

    // TODO: support directory hierarchies for markdown, templates and output
    var markdown_files = _listContentFilesIn(content_dir);
    var templates = _listTemplatesIn(template_dir);

    for (File file in markdown_files) {
        // TODO: provide a way to access the list of pages with filenames and titles from a '_site' property
        _logReading(file);

        var lines = file.readAsLinesSync();
        var page_options = {};

        if (_hasYamlBlock(lines)) {
            var yaml_block = _extractYamlBlockFrom(lines);
            page_options.addAll( yaml.loadYaml( yaml_block.join('\n') ) );

            lines.removeRange(0, yaml_block.length+1); // +1 for the YAML-Block-Delimiter ("~~~") line
        }

        page_options = _fillInDefaultPageOptions(file, page_options);

        var content = lines.join('\n');

        if (_supportsInMarkdownTemplating(page_options)) {
            content = renderTemplate(content, page_options);
        }

        page_options['_content'] = md.markdownToHtml(content);

        var template = _getTemplateFor(file, page_options, templates);

        _logUsingTemplate(template);

        var template_str = template.readAsStringSync();
        var output_str = _fixPathRefs( renderTemplate(template_str, page_options) );

        var filename = path.basenameWithoutExtension(file.path);
        var output_file = new File("${output_dir.path}/$filename.html");

        _logWriting(output_file);

        output_file.openWrite()..write(output_str)
                                ..close();
    }

    _logDone();
}

void
_fillInDefaultSiteOptions() {
    SITE_OPTIONS
        ..putIfAbsent('content_dir', () => 'content')
        ..putIfAbsent('template_dir', () => 'templates')
        ..putIfAbsent('output_dir', () => 'web')
        ..putIfAbsent('date_format', () => 'yMd')
        ..putIfAbsent('yaml_block_delimiter', () => '~~~')
        ..putIfAbsent('markdown_templating', () => true);
}

void
_paresOptionsFile(String config_file_path) {
    var config_options = {};
    try {
        var options_file = new File(config_file_path);
        config_options = yaml.loadYaml(options_file.readAsStringSync());
    }
    catch (e) {
        print("Notice: No 'site.yaml' file specified");
    }

    // TODO: provide a way to modify site.yaml values from dart, without just overwriting them

    config_options.forEach((key, value) => SITE_OPTIONS.putIfAbsent(key, () => value));
}

List<File>
_listContentFilesIn(Directory content_dir) {
    return content_dir.listSync()
           .where((file) => file is File
                         && (file.path.endsWith('.md') || file.path.endsWith(".markdown"))).toList();
}

List<File>
_listTemplatesIn(Directory template_dir) {
    return template_dir.listSync().where((file) => file is File).toList();
}

bool
_supportsInMarkdownTemplating(Map page_options) {
    return SITE_OPTIONS['markdown_templating']
         || (  page_options.containsKey('markdown_templating')
               && page_options['markdown_templating'] );
}

bool
_hasYamlBlock(List<String> content) {
    var yaml_delimiter = SITE_OPTIONS["yaml_block_delimiter"];
    var end_of_delimiter = yaml_delimiter.substring(yaml_delimiter.length-2, yaml_delimiter.length-1);
    return content.any((line) => line.startsWith(yaml_delimiter) && line.endsWith(end_of_delimiter));
}

List<String>
_extractYamlBlockFrom(List<String> content) {
    var yaml_delimiter = SITE_OPTIONS["yaml_block_delimiter"];
    return content.takeWhile((line) => !line.startsWith(yaml_delimiter)).toList();
}

Map
_fillInDefaultPageOptions(File file, Map page_options) {
    var filename = path.basenameWithoutExtension(file.path);
    page_options.putIfAbsent('title', () => filename);

    page_options['_site'] = SITE_OPTIONS;

    /// See [DateFormat](https://api.dartlang.org/docs/channels/stable/latest/intl/DateFormat.html) for formatting options
    var date_format = new DateFormat(SITE_OPTIONS['date_format']);

    if (page_options.containsKey('date_format')) {
        var page_date_format = new DateFormat(page_options['date_format']);
        page_options['_date'] = page_date_format.format( file.lastModifiedSync() );
    }
    else {
        page_options['_date'] = date_format.format( file.lastModifiedSync() );
    }

    return page_options;
}

File
_getTemplateFor(File file, Map page_options, List<File> templates) {
    var filename = path.basenameWithoutExtension(file.path);
    var filepath = path.normalize(file.path);
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
    catch(e) {
        throw "No template given for '$filepath!";
    }

    return template;
}


/**
* Redirect resource links using relative paths to the output directory.
* Currently only supports replacing Unix-style relative paths.
*/
String
_fixPathRefs(String html) {
    var relative_output = path.relative(SITE_OPTIONS['output_dir'], from: SITE_OPTIONS['template_dir']);

    relative_output = "$relative_output/".replaceAll("\\", "/");

    html = html.replaceAll('src="$relative_output', 'src="')
               .replaceAll('href="$relative_output', 'href="');

    return html;
}