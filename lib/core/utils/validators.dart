class Validators {
  static String? notEmpty(String? value, {String message = 'Field cannot be empty'}) {
    return (value == null || value.trim().isEmpty) ? message : null;
  }
}
