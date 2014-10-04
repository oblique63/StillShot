import "dart:io";
import "package:stillshot/stillshot.dart" as stillshot;
import "package:path/path.dart";

/**
* By using a `build.dart` file, you can use your IDE to watch file changes and automatically compile your site.
* See https://www.dartlang.org/tools/editor/build.html for more info.
*/
main() {
    Map env = Platform.environment;
    if (env.containsKey('WORKSPACE')) {
        stillshot.SITE_OPTIONS['workspace_dir'] = join(env['WORKSPACE'], 'example');
    }

    stillshot.generate();
}