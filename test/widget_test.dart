// Minimal placeholder test. flutter create overwrites this file with a default
// that references a class this app does not have, so CI restores this committed
// version with `git checkout -- test/` before analyzing.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoke', () {
    expect(1 + 1, 2);
  });
}
