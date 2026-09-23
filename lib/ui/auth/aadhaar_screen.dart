import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../services/aadhaar_service.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';
import 'category_screen.dart';

/// Step 1b — Aadhaar verification via OTP.
///
/// Two stages in one screen: enter the 12-digit number, then the 6-digit OTP
/// sent to the Aadhaar-registered mobile.
class AadhaarScreen extends StatefulWidget {
  const AadhaarScreen({super.key});

  @override
  State<AadhaarScreen> createState() => _AadhaarScreenState();
}

class _AadhaarScreenState extends State<AadhaarScreen> {
  final _aadhaarController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _aadhaarController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _rawAadhaar => AadhaarService.normalise(_aadhaarController.text);

  Future<void> _sendOtp() async {
    final value = _rawAadhaar;
    if (value.length != 12) {
      showSnack(
        context,
        'Enter all 12 digits of your Aadhaar number',
        error: true,
      );
      return;
    }
    if (!AadhaarService.isValidNumber(value)) {
      showSnack(
        context,
        'That Aadhaar number is not valid. Please re-check the digits.',
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    final session = context.read<SessionController>();
    final result = await session.requestAadhaarOtp(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _otpSent = result.success;
    });
    showSnack(context, result.message, error: !result.success);
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      showSnack(context, 'Enter the 6-digit OTP', error: true);
      return;
    }
    setState(() => _busy = true);
    final session = context.read<SessionController>();
    final result = session.verifyAadhaarOtp(code);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.success) {
      showSnack(context, result.message, error: true);
      _otpController.clear();
      return;
    }
    showSnack(context, result.message);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const CategoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Aadhaar Verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We verify your identity with an OTP sent to the '
                        'mobile number linked to your Aadhaar.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textSecondary.withValues(alpha: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Aadhaar number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _aadhaarController,
                enabled: !_otpSent,
                keyboardType: TextInputType.number,
                maxLength: 14, // 12 digits + 2 spaces
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _AadhaarFormatter(),
                ],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
                decoration: const InputDecoration(
                  hintText: '1234 5678 9012',
                  counterText: '',
                  prefixIcon: Icon(Icons.credit_card),
                ),
              ),

              if (!_otpSent) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _sendOtp,
                    child: _busy
                        ? const _Spinner()
                        : const Text('Send Aadhaar OTP'),
                  ),
                ),
              ],

              if (_otpSent) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OTP sent for ${session.pendingAadhaarMasked}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '••••••',
                    counterText: '',
                  ),
                ),
                if (session.aadhaarDevCode != null) ...[
                  const SizedBox(height: 10),
                  InfoBanner(
                    icon: Icons.info_outline,
                    message:
                        'Demo mode — your OTP is ${session.aadhaarDevCode}. '
                        'A live UIDAI connection replaces this.',
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _verify,
                    child: _busy
                        ? const _Spinner()
                        : const Text('Verify Aadhaar'),
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _otpSent = false;
                          _otpController.clear();
                        }),
                  child: const Text('Change Aadhaar number'),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We store only the last four digits of your Aadhaar, '
                      'never the full number.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppColors.textSecondary.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );
}

/// Renders 123456789012 as "1234 5678 9012" while typing.
class _AadhaarFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 12 ? digits.substring(0, 12) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 4 || i == 8) buffer.write(' ');
      buffer.write(capped[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
