import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kashta/app/app_shell.dart';

void main() {
  test('KashtaApp can be created', () {
    expect(const KashtaApp(), isA<Widget>());
  });
}
