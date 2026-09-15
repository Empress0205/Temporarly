import 'package:flutter_test/flutter_test.dart';
import 'package:jihudumie_app/state/app_state.dart';

/// The phone-normalisation contract between the app and the backend.
///
/// This table is duplicated verbatim in
/// `backend/authentication/tests/test_phone.py`. Both sides must agree: if
/// they drift, the same person can register twice — once by typing `0712...`
/// and once by typing `+255712...` — and the account they reach depends on how
/// they happened to type their own number.
void main() {
  const cases = <String, String>{
    // The four spellings a Tanzanian customer actually types.
    '0712345678': '712345678',
    '+255712345678': '712345678',
    '255712345678': '712345678',
    '712345678': '712345678',
    // International dialling prefix.
    '00255712345678': '712345678',
    // Formatting noise.
    '+255 712 345 678': '712345678',
    '0712-345-678': '712345678',
    '  0712 345 678  ': '712345678',
    '(0712) 345 678': '712345678',
    // Country code followed by a redundant national zero.
    '+2550712345678': '712345678',
    // Vodacom, Airtel, Tigo, Halotel prefixes all begin 6 or 7.
    '0655000111': '655000111',
    '0762000333': '762000333',
  };

  const invalid = <String>[
    '',
    '0712345', // too short
    '07123456789', // too long
    '0812345678', // 8 is not a mobile prefix
    '0222345678', // landline
    'abcdefghij',
    '+1 415 555 0134', // not Tanzanian
  ];

  group('normalisation', () {
    test('every accepted spelling reduces to one canonical form', () {
      cases.forEach((raw, expected) {
        expect(JhAppState.digitsOf(raw), expected, reason: 'input: $raw');
      });
    });

    test('canonical values are valid', () {
      for (final expected in cases.values) {
        expect(JhAppState.isValidPhone(expected), isTrue);
      }
    });

    test('normalisation is idempotent', () {
      for (final expected in cases.values) {
        expect(JhAppState.digitsOf(expected), expected);
      }
    });

    test('rejects anything that is not a Tanzanian mobile', () {
      for (final raw in invalid) {
        expect(
          JhAppState.isValidPhone(JhAppState.digitsOf(raw)),
          isFalse,
          reason: 'input: $raw',
        );
      }
    });
  });

  test('formats for display', () {
    expect(JhAppState.prettyPhone('712345678'), '+255 712 345 678');
    expect(JhAppState.prettyPhone('0712345678'), '+255 712 345 678');
  });
}
