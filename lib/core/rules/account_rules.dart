import 'dart:math' as math;

/// Inline form errors for sign-up / sign-in (`12` §2).
enum FieldError { required, tooLong, invalidEmail, weakPassword }

abstract final class AccountRules {
  static const nameMax = 50;
  static const passwordMin = 8;
  static const resendCooldown = Duration(seconds: 60);

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static FieldError? name(String value) {
    final v = value.trim();
    if (v.isEmpty) return FieldError.required;
    if (v.length > nameMax) return FieldError.tooLong;
    return null;
  }

  static FieldError? email(String value) {
    final v = value.trim();
    if (v.isEmpty) return FieldError.required;
    return _email.hasMatch(v) ? null : FieldError.invalidEmail;
  }

  /// At least 8 characters including a number.
  static FieldError? password(String value) {
    if (value.isEmpty) return FieldError.required;
    final strong =
        value.length >= passwordMin && value.contains(RegExp(r'[0-9]'));
    return strong ? null : FieldError.weakPassword;
  }

  static bool passwordStrong(String value) => password(value) == null;
}

/// Referral codes (`12` §3): first name, accents removed, A–Z only, max 6
/// letters, uppercase + 2 random characters; fewer than 2 letters → `TUNE`
/// + 4 random. The random part never uses 0 O 1 I L. The server makes the
/// real code; this is the live preview on 48.
abstract final class ReferralCode {
  static const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static const _accents = {
    'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A', //
    'Ç': 'C', 'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ì': 'I', 'Í': 'I',
    'Î': 'I', 'Ï': 'I', 'Ñ': 'N', 'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O',
    'Ö': 'O', 'Ø': 'O', 'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U', 'Ý': 'Y',
    'Ÿ': 'Y', 'ß': 'SS',
  };

  static String namePart(String firstName) {
    final upper = firstName.trim().toUpperCase();
    final plain = StringBuffer();
    for (final rune in upper.runes) {
      final ch = String.fromCharCode(rune);
      plain.write(_accents[ch] ?? ch);
    }
    final letters = plain.toString().replaceAll(RegExp('[^A-Z]'), '');
    return letters.length > 6 ? letters.substring(0, 6) : letters;
  }

  static String suggest(String firstName, {math.Random? random}) {
    final rng = random ?? math.Random.secure();
    String pick(int n) =>
        [for (var i = 0; i < n; i++) alphabet[rng.nextInt(alphabet.length)]]
            .join();
    final name = namePart(firstName);
    return name.length < 2 ? 'TUNE${pick(4)}' : '$name${pick(2)}';
  }

  static String normalize(String input) =>
      input.trim().toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  /// Plausible enough to send to the server (4–10 characters).
  static bool looksValid(String input) {
    final code = normalize(input);
    return code.length >= 4 && code.length <= 10;
  }

  /// `https://<domain>/i/<CODE>`.
  static String link(String domain, String code) => 'https://$domain/i/$code';

  /// The code in a universal link (`/i/<CODE>`), or null.
  static String? fromLink(Uri uri, {required String domain}) {
    if (uri.host.isNotEmpty && uri.host != domain) return null;
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments.first != 'i') return null;
    final code = normalize(segments[1]);
    return looksValid(code) ? code : null;
  }
}
