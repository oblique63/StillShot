part of stillshot;

void
_logStarting() {
    print("======== StillShot ========");
    print("Generating site...\n");
}

void
_logEnvironment(String working_directory) {
    print("From ${path.absolute(working_directory)}\n");
}

void
_logReading(File file) {
    var file_path = _displayPath(file.path);
    print("Reading\t'$file_path'");
}

void
_logUsingTemplate(File file) {
    var file_path = _displayPath(file.path);
    print("Using\t'$file_path'");
}

void
_logWriting(File file) {
    var file_path = _displayPath(file.path);
    print("Writing\t'$file_path'\n");
}

void
_logDone() {
    print("Done!");
}

String
_displayPath(String path_str) => path.relative(path_str);