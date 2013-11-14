library app_bootstrap;

import 'package:polymer/polymer.dart';

import '../dart/media-bar.dart' as i0;
import '../dart/main.dart' as i1;

void main() {
  configureForDeployment([
      '../dart/media-bar.dart',
      '../dart/main.dart',
    ]);
  i1.main();
}
