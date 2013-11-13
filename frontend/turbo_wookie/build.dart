import "package:polymer/builder.dart";

void main(List<String> args) {
  CommandLineOptions options = parseOptions(args);
  build(entryPoints: ["web/html/index.html"], options: options);
}