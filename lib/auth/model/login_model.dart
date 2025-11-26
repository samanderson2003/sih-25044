class LoginModel {
  final String email;
  final String password;

  LoginModel({required this.email, required this.password});

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

  bool isValid() {
    return validateEmail() == null && validatePassword() == null;
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
