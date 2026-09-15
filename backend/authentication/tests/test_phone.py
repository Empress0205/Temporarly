"""Phone normalisation.

These cases are the contract between this service and the Flutter client. If
the two implementations ever drift, the same person can end up with two
accounts -- one created by typing `0712...`, one by typing `+255712...` -- so
the table below is duplicated verbatim in the app's `phone_normalisation_test`.
"""

from django.test import SimpleTestCase

from authentication import phone

# (input, expected canonical form). Empty string means "not a usable number".
CASES = [
    # The four spellings a Tanzanian customer actually types.
    ("0712345678", "712345678"),
    ("+255712345678", "712345678"),
    ("255712345678", "712345678"),
    ("712345678", "712345678"),
    # International dialling prefix.
    ("00255712345678", "712345678"),
    # Formatting noise.
    ("+255 712 345 678", "712345678"),
    ("0712-345-678", "712345678"),
    ("  0712 345 678  ", "712345678"),
    ("(0712) 345 678", "712345678"),
    # Country code followed by a redundant national zero.
    ("+2550712345678", "712345678"),
    # Vodacom, Airtel, Tigo, Halotel prefixes all begin 6 or 7.
    ("0655000111", "655000111"),
    ("0762000333", "762000333"),
]

INVALID = [
    "",
    "0712345",  # too short
    "07123456789",  # too long
    "0812345678",  # 8 is not a mobile prefix
    "0222345678",  # landline
    "abcdefghij",
    "+1 415 555 0134",  # not Tanzanian
]


class NormalisationTests(SimpleTestCase):
    def test_accepted_spellings_all_reduce_to_one_form(self):
        for raw, expected in CASES:
            with self.subTest(raw=raw):
                self.assertEqual(phone.normalise(raw), expected)

    def test_normalised_values_are_valid(self):
        for raw, expected in CASES:
            with self.subTest(raw=raw):
                self.assertTrue(phone.is_valid(phone.normalise(raw)))

    def test_rejects_numbers_that_are_not_tanzanian_mobiles(self):
        for raw in INVALID:
            with self.subTest(raw=raw):
                self.assertFalse(phone.is_valid(phone.normalise(raw)))

    def test_normalisation_is_idempotent(self):
        # Guards the storage path: a canonical value read back and normalised
        # again must not change.
        for _, expected in CASES:
            with self.subTest(value=expected):
                self.assertEqual(phone.normalise(expected), expected)

    def test_none_and_empty_are_handled(self):
        self.assertEqual(phone.normalise(None), "")
        self.assertEqual(phone.normalise(""), "")


class FormattingTests(SimpleTestCase):
    def test_e164_for_the_sms_provider(self):
        self.assertEqual(phone.to_e164("712345678"), "+255712345678")

    def test_mask_keeps_enough_to_identify_but_not_to_leak(self):
        masked = phone.mask("712345678")
        self.assertEqual(masked, "+255 712 ... 678")
        self.assertNotIn("345", masked)

    def test_mask_tolerates_a_malformed_value(self):
        self.assertEqual(phone.mask("123"), "+255 ...")
