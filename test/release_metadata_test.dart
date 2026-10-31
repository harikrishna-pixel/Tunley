import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String name) =>
    File('release/app_store/en-US/$name').readAsStringSync().trim();

void main() {
  test('App Store text fields fit their limits', () {
    expect(_read('name.txt').length, lessThanOrEqualTo(30));
    expect(_read('subtitle.txt').length, lessThanOrEqualTo(30));
    expect(_read('promotional_text.txt').length, lessThanOrEqualTo(170));
    expect(_read('keywords.txt').length, lessThanOrEqualTo(100));
    expect(_read('description.txt').length, lessThanOrEqualTo(4000));
  });

  test('description keeps the 2.3.2 line and auto-renew terms', () {
    final description = _read('description.txt');
    expect(
      description,
      contains('Some features require a Tunely Pro subscription'),
    );
    expect(description, contains('renew automatically'));
    expect(description, contains('Terms of Use'));
    expect(description, contains('Privacy Policy'));
  });
}
