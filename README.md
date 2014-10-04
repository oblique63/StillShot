StillShot
==========

[![Build Status](https://drone.io/github.com/oblique63/StillShot/status.png)](https://drone.io/github.com/oblique63/StillShot/latest)

A simple, bare-bones static site generator in [Dart][dart], with [Markdown][markdown]
and [Mustache][mustache] templating support.

No need to worry about "themes", "plugins" or configuration just to get a simple static site up and running.
This is a stripped-down 'framework' to help make Markdown -> HTML generation (with templating features)
as quick and easy as possible, while still being flexible and powerful enough to feel like you're working with
a dynamic site.

Edit your CSS/SASS/Dart/JS/Coffeescript/etc like you would on any other plain static site
(your assets won't get moved or copied around), and simplify your content creation with Markdown and HTML templates.
Recommend using it with the [LivePage][livepage] chrome extension for maximum productivity.


## site.yaml
**Optional** [YAML][yaml] file that stores your global values and config options.
Values set here can be accessed from all templates and markdown files.

Here are the configuration options you can set inside it:

- `content_dir`: This is where **StillShot** will look for your markdown files to generate the site from.
Defaults to looking for a `content` folder in the same directory as the Dart file you'll be generating the site from.
- `template_dir`: The directory containing your HTML+Mustache templates. Will look for a `templates` directory by default.
- `output_dir`: Where **StillShot** should output your generated site. Defaults to the `web` directory, as used by Dart conventions.
- `date_formatting`: Date format string used for parsing the 'last modified' date of your markdown files. See the Dart
[DateFormat Docs](https://api.dartlang.org/docs/channels/stable/latest/intl/DateFormat.html) for possible options.
- `markdown_templating`: Whether or not to support template tag embedding/rendering in markdown files. Defaults to `true`.


## Markdown
**StillShot** lets you use [markdown][markdown] to write your site content. At the beginning of each markdown file, you
have the option to use a [YAML][yaml] block to define custom values that you can inject into your templates. Example:

    title: A Blog Post
    published: 01/01/2014
    category: example
    tags:
        - StillShot
        - Rants
        - Etc.
    ~~~~~~

    Normal Markdown content here...

As you can see, a line of tildes (`~`) is used to designate your YAML block. You can access/inject your values into
your pages using [mustache template syntax][mustache]. You can do this either inside your dedicated HTML/mustache templates:

    <ul>
      {{#tags}}
        <li>{{.}}</li>
      {{/tags}}
    </ul>

Or, you can embed your values within the markdown file itself:

    {{#tags}}
      - __{{.}}__
    {{/tags}}

so you can take advantage of templating and markdown at the same time.

Simply place all your `.md` files in your `content_dir` and **StillShot** will generate your site accordingly. Note that
the filenames of your markdown files will be used for the names of the corresponding generated HTML files in your `output_dir`.


## Templates
As mentioned above, you can access any variables set within your markdown files from your templates using mustache. Options
set from your `site.yaml` can be accessed through the `_site` variable, like so:

    <h1>{{ _site.site_name }}</h1>

where `site_name` is a property defined in your `site.yaml`. You can access these values from your markdown files as well.

Every page and template has access to the following values:

- `title`: post title, usually set inside each markdown file, but is set to name of markdown file if left blank
- `_site`: site.yaml values
- `_date`: the post/markdown file's _last modified_ date
- `_content`: converted markdown content (only accessible from templates)

So when an HTML template for your markdown content would look something like this:

    <head>
      ...
      <title>{{ title }}</title>
      ...
    </head>
    <body>
      ...
      <article>
        {{ _content }}
      </article>
      ...
    </body>

Additionally, any tags with `src` and `href` attributes that have relative references to your output directory will be trimmed
to be local to your output directory. So for example, if you have a `<link rel="stylesheet" href="../web/css/main.css">` tag and
`web` is your output directory, then it will be modified to `<link rel="stylesheet" href="css/main.css">` in the corresponding
output file. A tag like `href="../assets/css/main.css"` however, will remain unchanged because it doesn't contain a reference to
the output directory. This way you can test out your css/js/dart directly from your templates without needing to change your
resource paths. _(Note: this feature currently only works with forward-slash (`/`) path separators)._


## Generating Your Site
First make sure to import StillShot in whichever **Dart** file you have your `main()` function:
```dart
import "package:stillshot/stillshot.dart" as stillshot;
```

Then simply call `stillshot.generate()` from anywhere in your `main()` function, like so:
```dart
main() => stillshot.generate();
```

If you wish, you can use this in a `build.dart` file to take advantage of your Editor's build system:

- [Dart Editor](https://www.dartlang.org/tools/editor/build.html)
- [Webstorm (and other JetBrains IDEs)](http://stackoverflow.com/questions/17266106/how-to-run-build-dart-in-webstorm)


## Advanced Customization
**StillShot** leaves a couple options available to you at runtime in case you wish to programmatically
customize your site rendering in Dart.

`SITE_OPTIONS` is the `Map` containing all your `site.yaml` options. Modifying the `SITE_OPTIONS` map directly will
take precedence over your site.yaml options (i.e. if you defined `site_name: Blog` in your site.yaml, but have the
line `stillshot.SITE_OPTIONS['site_name'] = 'Not A Blog';` in your Dart file, then `site_name` will be _'Not A Blog'_). You can
add whatever values you want to it and they will be accessible from your templates and markdown.

You also have the option of overriding **StillShot**'s  `renderTemplate` function, so that you can use
your templating engine of choice. Simply make sure you take a template `String` as your first argument, an
options/values `Map` as your second, and return a fully rendered HTML string. For example:

```dart
stillshot.renderTemplate = (String template, Map options) => jade.renderString(template, options);
```
if you were working with a [jade](http://jade-lang.com/) template parser of some kind.

Note that overriding this function may break markdown templating support, so try using it with `markdown_templating: false`
in your `site.yaml` or `SITE_OPTIONS` if it becomes a problem.


# Sample Project
Using the default options, a **StillShot** project would typically look like this

    site_project/     (Project root)
        content/      (Markdown files)
        templates/    (Html/Mustache templates)
        web/          (Output/resource directory -- where your static site will be generated)
            css/
            imgs/
            dart/
            ...
        build.dart    (Where StillShot will be called from to generate your site)
        site.yaml     (Optional config file)
        pubspec.yaml  (Dart pubspec file -- where you will list StillShot as a dependency)

Check the [example](https://github.com/oblique63/StillShot/tree/master/example) folder for a sample project using StillShot.
Be sure to read through the files in `content` and `templates` for extra usage details.


# Install
add `stillshot` to your `pubspec.yaml` file to install it from pub:

    dependencies:
      stillshot: any

or keep up with the latest developments on this git repo:

    dependencies:
      stillshot:
        git: https://github.com/oblique63/StillShot.git

then just run `$ pub get` and you'll be all set to go.


### Known Issues / TODO
- Markdown parser is finicky about lists, particularly nested and adjecent lists
- Directories in `content` and `templates` are ignored
- Mustache partials not yet supported
- Implement commandline interface and file-watcher to end reliance on a `build.dart` file

[dart]: https://www.dartlang.org/
[yaml]: http://rhnh.net/2011/01/31/yaml-tutorial
[markdown]: http://daringfireball.net/projects/markdown/syntax
[mustache]: http://mustache.github.io/mustache.5.html
[livepage]: https://chrome.google.com/webstore/detail/livepage/pilnojpmdoofaelbinaeodfpjheijkbh
[stillshot]: https://github.com/oblique63/StillShot