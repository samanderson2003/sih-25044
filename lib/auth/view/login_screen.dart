// login_screen.dart (UPDATED)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/login_controller.dart';
import '../model/login_model.dart';
import '../../terms&permissions/view/terms&conditions_view.dart';
import '../../terms&permissions/view/permissions_screen.dart';
import '../../terms&permissions/controller/terms&conditions_controller.dart';
import '../../prior_data/controller/farm_data_controller.dart';
import '../../prior_data/view/simplified_data_collection_flow.dart';
import '../../widgets/translated_text.dart';
import 'otp_verification_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final LoginController _loginController = LoginController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;

  // Theme colors for farming app
  static const primaryColor = Color(0xFF2D5016); // Deep green
  static const backgroundColor = Color(0xFFF8F6F0); // Cream
  static const accentColor = Color(0xFF6B8E23); // Olive green
  static const textColor = Color(0xFF4A4A4A); // Dark gray

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    // --- FIX: Ensure mobile number is trimmed here ---
    final mobileNumber = _mobileController.text.trim();
    
    // --- Manual Validation Check (uses the model's logic for UI feedback) ---
    final model = LoginModel(mobile: mobileNumber);
    String? validationError = model.validateMobile();

    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        await _loginController.sendOtp(mobileNumber); // Pass trimmed number

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      _verificationId = result['verificationId'];
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

  Future<void> _handleVerificationSuccess() async {
    if (!mounted) return;

    // Check if user has accepted terms and granted permissions
    final termsController = TermsConditionsController();
    final permissionsController = PermissionsController();

    // Check if user has accepted terms
    final hasAcceptedTerms = await termsController.hasAcceptedTerms();

    if (!mounted) return;

    if (!hasAcceptedTerms) {
      // User hasn't accepted terms - go to terms screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TermsConditionsScreen(),
        ),
      );
    } else {
      // Terms accepted, now check permissions
      final permissionStatus = await permissionsController
          .checkPermissionStatus();
      final hasLocation = permissionStatus['location'] ?? false;

      if (!hasLocation) {
        // Location not granted - go to permissions screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PermissionsScreen()),
        );
      } else {
        // Permissions granted - check if farm data is complete
        final farmDataController = FarmDataController();
        final isFarmDataComplete = await farmDataController
            .isFarmDataComplete();

        if (!isFarmDataComplete) {
          // Farm data not complete - go to data collection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SimplifiedDataCollectionFlow(),
            ),
          );
        } else {
          // All good - go to main screen
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    }
  }

  // --- UI HELPER: The input decoration remains the same ---
  InputDecoration _buildInputDecoration(
    String label,
    IconData prefixIcon, {
    Widget? suffixIcon,
  }) {
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
                  Icon(Icons.agriculture, size: 80, color: primaryColor),
                  const SizedBox(height: 24),

                  // App Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Crop',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        TextSpan(
                          text: 'Yield',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  const Text(
                    'Login with your mobile number to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 48),

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

                  // Mobile Number Field with OTP Button
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: _buildInputDecoration(
                      'Mobile Number',
                      Icons.phone_outlined,
                      suffixIcon: TextButton(
                        onPressed: _isLoading ? null : _handleSendOtp,
                        child: Text(
                          _verificationId != null ? 'Resend OTP' : 'Send OTP',
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    validator: (value) {
                      final model = LoginModel(mobile: value ?? '');
                      return model.validateMobile();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button (Trigger OTP Send)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendOtp,
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
                        : const Text(
                            'Login / Send OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  // REMOVED Divider and Google Sign In
                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: textColor),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          'Sign Up',
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