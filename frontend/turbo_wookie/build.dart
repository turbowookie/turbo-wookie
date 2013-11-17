import "package:polymer/builder.dart";

void main(List<String> args) {
  List<String> actualArgs = new List<String>();
  //actualArgs.add("--deploy");
  actualArgs.addAll(args);
  CommandLineOptions options = parseOptions(actualArgs);
  build(entryPoints: ["web/html/index.html"], options: options);
}