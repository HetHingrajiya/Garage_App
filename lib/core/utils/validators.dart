/// Validation utility class for form inputs
class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // Phone number validation (10 digits)
  static String? phone(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Phone number is required' : null;
    }

    // Remove any spaces or dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

    if (cleaned.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'Phone number must contain only digits';
    }

    return null;
  }

  // Required field validation
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Password validation
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Name validation
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  // Vehicle registration number validation
  static String? registrationNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Registration number is required';
    }

    if (value.trim().length < 4) {
      return 'Registration number must be at least 4 characters';
    }

    return null;
  }

  // Year validation
  static String? year(String? value) {
    if (value == null || value.isEmpty) {
      return 'Year is required';
    }

    final year = int.tryParse(value);
    if (year == null) {
      return 'Enter a valid year';
    }

    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      return 'Enter a year between 1900 and ${currentYear + 1}';
    }

    return null;
  }

  // Number validation
  static String? number(String? value, String fieldName, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }

    return null;
  }

  // Decimal number validation
  static String? decimal(
    String? value,
    String fieldName, {
    double? min,
    double? max,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }

    return null;
  }

  // VIN validation (optional)
  static String? vin(String? value) {
    if (value == null || value.isEmpty) {
      return null; // VIN is optional
    }

    if (value.length != 17) {
      return 'VIN must be exactly 17 characters';
    }

    if (!RegExp(r'^[A-HJ-NPR-Z0-9]+$').hasMatch(value)) {
      return 'VIN contains invalid characters';
    }

    return null;
  }

  // Address validation
  static String? address(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Address is required' : null;
    }

    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters';
    }

    return null;
  }
}
