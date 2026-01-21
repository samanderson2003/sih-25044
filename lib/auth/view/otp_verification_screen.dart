// otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/register_controller.dart'; 

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final VoidCallback onVerificationSuccess;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.onVerificationSuccess,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final RegisterController _controller = RegisterController(); 
  bool _isLoading = false;
  String? _errorMessage;

  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);
  
  // New state variable to track OTP length for button enablement
  // Initialized to 0, will be updated by onChanged
  int _otpLength = 0; 

  @override
  void initState() {
    super.initState();
    // Use the controller listener to initialize the state variable 
    // and handle paste/initial value, though onChanged will handle typing.
    _otpController.addListener(() {
      if (_otpLength != _otpController.text.length) {
        setState(() {
           _otpLength = _otpController.text.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    // This check is now mostly redundant but kept as a fallback
    if (_otpController.text.length != 6) { 
      setState(() => _errorMessage = 'Please enter the 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _controller.verifyOtp(
      verificationId: widget.verificationId,
      smsCode: _otpController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']!),
          backgroundColor: Colors.green,
        ),
      );
      widget.onVerificationSuccess();
      Navigator.pop(context); // Close OTP screen
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the Verify button should be enabled
    final isVerifyEnabled = _otpLength == 6 && !_isLoading;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const Text(
              'Enter the 6-digit code sent to:',
              style: TextStyle(fontSize: 18), 
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
              child: Text(
                '${widget.phoneNumber}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),

            // OTP Input Field 
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6, 
              onChanged: (value) { // <--- ADDED onChanged to aggressively update length state
                setState(() {
                  _otpLength = value.length;
                });
              },
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                // Ensure length limiting is applied here too, just in case
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                hintText: '• • • • • •',
                hintStyle: TextStyle(letterSpacing: 10, color: Colors.grey.shade400),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 24, letterSpacing: 10),
            ),

            const SizedBox(height: 32),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isVerifyEnabled ? _handleVerifyOtp : null, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: primaryColor.withOpacity(0.5), 
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Verify & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Resend Code Button
            TextButton(
              onPressed: null, 
              child: Text(
                'Resend Code',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}