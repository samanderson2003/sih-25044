// register_model.dart
class RegisterModel {
  // Kept for controller compatibility
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
  String? validateName() {
    if (name == null || name!.isEmpty) {
      return 'Name is required';
    }
    // New validation: Only Uppercase, lowercase, and space are allowed
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name!)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? validateMobileNumber() {
    if (mobileNumber == null || mobileNumber!.isEmpty) {
      return 'Mobile number is required';
    }
    final cleanNumber = mobileNumber!.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.length != 10) {
      return 'Mobile number must be 10 digits';
    }
    return null;
  }

  bool isValid() {
    return validateName() == null && validateMobileNumber() == null;
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'name': name, 'mobileNumber': mobileNumber};
  }
}