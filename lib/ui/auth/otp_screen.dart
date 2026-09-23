import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/session_controller.dart';
import '../shell/track_router.dart';
import '../widgets/common.dart';
import 'aadhaar_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 45;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      showSnack(context, 'Enter the 6-digit code', error: true);
      return;
    }
    setState(() => _verifying = true);
    final session = context.read<SessionController>();
    final result = session.verifyOtp(code);
    if (!mounted) return;
    setState(() => _verifying = false);

    if (!result.ok) {
      showSnack(context, result.message, error: true);
      _controller.clear();
      return;
    }

    if (result.existing != null) {
      // Land on TrackRouter, never AppShell directly: a returning student must
      // reopen the blue education app, and hardcoding the marketplace shell
      // here would drop them into the agri market whatever their category.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const TrackRouter()),
        (route) => false,
      );
    } else {
      // New account: phone is confirmed, next step is Aadhaar verification.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AadhaarScreen()),
      );
    }
  }

  Future<void> _resend() async {
    final session = context.read<SessionController>();
    final result = await session.resendOtp();
    if (!mounted) return;
    showSnack(context, result.message, error: !result.success);
    if (result.success) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(title: Text(session.t('otp_title'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.t('otp_body'),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    session.pendingPhone,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(session.t('change_number')),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AutofillGroup(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  // Lets Android/iOS drop the code straight in from the SMS.
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 14,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: TextStyle(letterSpacing: 14, fontSize: 26),
                  ),
                  // Autofilled or hand-typed, verify as soon as it is complete.
                  onChanged: (v) {
                    if (v.trim().length == 6 && !_verifying) _verify();
                  },
                  onSubmitted: (_) => _verify(),
                ),
              ),
              const SizedBox(height: 12),
              if (!session.usesRealSms && session.devCode != null)
                InfoBanner(
                  icon: Icons.developer_mode,
                  message:
                      'Test mode — your code is ${session.devCode}. '
                      'Live SMS delivery activates once the SMS gateway keys '
                      'are supplied at build time.',
                  color: AppColors.warning,
                  background: AppColors.pendingSoft,
                )
              else
                const InfoBanner(
                  icon: Icons.sms_outlined,
                  message:
                      'We sent the code by SMS. It may take a few '
                      'seconds to arrive.',
                ),
              const SizedBox(height: 16),
              Text(
                'Code expires in 10 minutes.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _verifying ? null : _verify,
                child: _verifying
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(session.t('verify')),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _secondsLeft > 0 ? null : _resend,
                  child: Text(
                    _secondsLeft > 0
                        ? 'Resend code in ${_secondsLeft}s'
                        : session.t('resend_code'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
