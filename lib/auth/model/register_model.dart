class RegisterModel {
  final String email;
  final String password;
  final String confirmPassword;
  final String? name;
  final String? mobileNumber;

  RegisterModel({
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.name,
    this.mobileNumber,
  });

  // Validation methods
  String? validateEmail() {
    if (email.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword() {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword() {
    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validateName() {
    if (name != null && name!.isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? validateMobileNumber() {
    if (mobileNumber != null && mobileNumber!.isNotEmpty) {
      // Remove any spaces or special characters
      final cleanNumber = mobileNumber!.replaceAll(RegExp(r'[^0-9]'), '');
      // Check if it's a valid 10-digit Indian mobile number
      if (cleanNumber.length != 10) {
        return 'Mobile number must be 10 digits';
      }
      // Check if it starts with valid digits (6-9 for Indian numbers)
      if (!RegExp(r'^[6-9]').hasMatch(cleanNumber)) {
        return 'Invalid mobile number';
      }
    }
    return null;
  }

  bool isValid() {
    return validateEmail() == null &&
        validatePassword() == null &&
        validateConfirmPassword() == null &&
        validateName() == null &&
        validateMobileNumber() == null;
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'name': name, 'password': password};
  }
}
