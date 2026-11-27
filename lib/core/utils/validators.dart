/// Form field validators. Each returns an error message, or `null` when valid.
abstract final class Validators {
  static const int minPasswordLength = 8;
  static const int maxDisplayNameLength = 40;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

  static String? notEmpty(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final empty = notEmpty(value, field: 'Email');
    if (empty != null) return empty;
    return _emailPattern.hasMatch(value!.trim())
        ? null
        : 'Enter a valid email address';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    return null;
  }

  static String? username(String? value) {
    final empty = notEmpty(value, field: 'Username');
    if (empty != null) return empty;
    final normalised = value!.trim().toLowerCase();
    return _usernamePattern.hasMatch(normalised)
        ? null
        : 'Use 3-20 letters, numbers or underscores';
  }

  static String? displayName(String? value) {
    final empty = notEmpty(value, field: 'Name');
    if (empty != null) return empty;
    if (value!.trim().length > maxDisplayNameLength) {
      return 'Keep it under $maxDisplayNameLength characters';
    }
    return null;
  }
}
