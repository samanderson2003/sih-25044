// register_screen.dart (UPDATED)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/register_controller.dart';
import '../model/register_model.dart';
import '../../terms&permissions/view/terms&conditions_view.dart';
import '../../widgets/translated_text.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final RegisterController _registerController = RegisterController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;
  bool _isOtpSent = false;
  bool _isPhoneVerified = false;

  // Theme colors for farming app
  static const primaryColor = Color(0xFF2D5016); // Deep green
  static const backgroundColor = Color(0xFFF8F6F0); // Cream
  static const textColor = Color(0xFF4A4A4A); // Dark gray

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    // Local validation check using model to get immediate feedback
    final name = _nameController.text.trim();
    final mobileNumber = _mobileController.text.trim();
    
    final model = RegisterModel(
      email: '', password: '', confirmPassword: '', 
      name: name, mobileNumber: mobileNumber,
    );

    // Consolidated validation check
    String? validationError = model.validateName() ?? model.validateMobileNumber();
    
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Call controller with name and mobile number for validation and pre-check
    final result =
        await _registerController.sendOtp(name, mobileNumber);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      _verificationId = result['verificationId'];
      _isOtpSent = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.blue,
        ),
      );
      // Navigate to OTP verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            verificationId: _verificationId!,
            phoneNumber: mobileNumber,
            onVerificationSuccess: _handleVerificationSuccess,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result['message'];
      });
    }
  }

  void _handleVerificationSuccess() async {
    if (!mounted) return;

    setState(() {
      _isPhoneVerified = true;
      _isOtpSent = false; // Hide the button after success
    });

    // 1. Finalize registration (create user document in Firestore)
    await _handleFinalizeRegister();
  }

  Future<void> _handleFinalizeRegister() async {
    // Final check for name and phone number
    final name = _nameController.text.trim();
    final mobileNumber = _mobileController.text.trim();

    final model = RegisterModel(
      email: '', password: '', confirmPassword: '', 
      name: name, mobileNumber: mobileNumber,
    );

    String? validationError = model.validateName() ?? model.validateMobileNumber();

    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    if (!_isPhoneVerified) {
      // If user clicks button without verifying, initiate OTP flow
      await _handleSendOtp();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Finalize Registration (Creates Firestore user profile)
    final result =
        await _registerController.finalizeRegistration(model);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to terms screen for new users
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
      );
    } else {
      setState(() {
        _errorMessage = result['message'];
      });
    }
  }

  // --- UI HELPER: The input decoration remains the same ---
  InputDecoration _buildInputDecoration(
    String label,
    IconData prefixIcon, {
    Widget? suffixIcon,
  }) {
    // ... (InputDecoration implementation remains the same)
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon, color: primaryColor),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo/Icon
                  Icon(Icons.agriculture, size: 70, color: primaryColor),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'Join us with your mobile number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _buildInputDecoration(
                      'Full Name',
                      Icons.person_outlined,
                    ),
                    validator: (value) {
                      final model = RegisterModel(
                        email: '', password: '', confirmPassword: '', 
                        name: value, mobileNumber: _mobileController.text.trim(),
                      );
                      return model.validateName();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mobile Number Field with OTP Button
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    readOnly: _isPhoneVerified,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: _buildInputDecoration(
                      'Mobile Number',
                      Icons.phone_outlined,
                      suffixIcon: _isPhoneVerified
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : TextButton(
                              onPressed: _isLoading ? null : _handleSendOtp,
                              child: Text(
                                _isOtpSent ? 'Resend OTP' : 'Send OTP',
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    validator: (value) {
                       final model = RegisterModel(
                        email: '', password: '', confirmPassword: '', 
                        name: _nameController.text.trim(), mobileNumber: value,
                      );
                      return model.validateMobileNumber();
                    },
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Button (Finalize Registration)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleFinalizeRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _isPhoneVerified ? 'Create Account' : 'Verify Phone & Sign Up',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 32),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: textColor),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}