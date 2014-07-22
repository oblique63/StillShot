part of stillshot;

void
_logStarting() {
    print("======== StillShot ========");
    print("Generating site...\n");
}

void
_logReading(File file) {
    var file_path = path.normalize(file.path);
    print("Reading\t'$file_path'");
}

void
_logUsingTemplate(File file) {
    var file_path = path.normalize(file.path);
    print("Using\t'$file_path'");
}

void
_logWriting(File file) {
    var file_path = path.normalize(file.path);
    print("Writing\t'$file_path'\n");
}

void
_logDone() {
    print("Done!");
}