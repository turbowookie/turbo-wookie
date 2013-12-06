import "package:polymer/builder.dart";

void main(List<String> args) {
  build(entryPoints: ["web/index.html"], options: parseOptions(args));
}