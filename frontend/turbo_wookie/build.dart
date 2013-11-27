import "package:polymer/builder.dart";

void main(List<String> args) {
  build(entryPoints: ["web/html/index.html"], options: parseOptions(args));
}