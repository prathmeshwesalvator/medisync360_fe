/// All form validators as static functions.
/// Usage: validator: Validators.email
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() getPassword) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Please confirm your password';
      if (value != getPassword()) return 'Passwords do not match';
      return null;
    };
  }

  static String? phone(String? value) {
    // optional — only validate if not empty
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!regex.hasMatch(value.replaceAll(' ', ''))) return 'Enter a valid phone number';
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    final n = int.tryParse(value.trim());
    if (n == null || n < 0) return '$field must be a positive number';
    return null;
  }

  static String? licenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'License number is required';
    if (value.trim().length < 4) return 'Enter a valid license number';
    return null;
  }

  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pincode is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) return 'Enter a valid 6-digit pincode';
    return null;
  }
}