// login_model.dart (UPDATED)
class LoginModel {
  final String mobile;

  LoginModel({required this.mobile});

  // Validation methods
  String? validateMobile() {
    // Trim the input string first
    final trimmedMobile = mobile.trim(); 
    
    if (trimmedMobile.isEmpty) {
      return 'Mobile number is required';
    }
    
    // Replace non-numeric characters and then check length
    final cleanNumber = trimmedMobile.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanNumber.length != 10) {
      return 'Mobile number must be 10 digits';
    }
    return null;
  }

  bool isValid() {
    return validateMobile() == null;
  }

  Map<String, dynamic> toJson() {
    return {'mobile': mobile};
  }
}