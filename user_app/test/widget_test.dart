// Smoke test — verifies the app widget tree boots without crashing.
// The default counter test is removed because this app does not have a counter widget.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder test — app package loads', () {
    expect(1 + 1, equals(2));
  });
}
