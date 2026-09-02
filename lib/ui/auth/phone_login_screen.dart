import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/session_controller.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'otp_screen.dart';

class CountryCode {
  final String dial;
  final String label;
  final String flag;
  const CountryCode(this.dial, this.label, this.flag);
}

const kCountryCodes = <CountryCode>[
  CountryCode('+91', 'India', '🇮🇳'),
  CountryCode('+1', 'United States', '🇺🇸'),
  CountryCode('+44', 'United Kingdom', '🇬🇧'),
  CountryCode('+971', 'UAE', '🇦🇪'),
  CountryCode('+65', 'Singapore', '🇸🇬'),
  CountryCode('+61', 'Australia', '🇦🇺'),
  CountryCode('+49', 'Germany', '🇩🇪'),
  CountryCode('+81', 'Japan', '🇯🇵'),
  CountryCode('+86', 'China', '🇨🇳'),
  CountryCode('+31', 'Netherlands', '🇳🇱'),
];

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CountryCode _country = kCountryCodes.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final session = context.read<SessionController>();
    final result =
        await session.requestOtp(_country.dial, _controller.text.trim());
    if (!mounted) return;
    if (!result.success) {
      showSnack(context, result.message, error: true);
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const OtpScreen()));
  }

  void _pickCountry() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'Select country code',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            ...kCountryCodes.map(
              (c) => ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                title: Text(
                  c.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  c.dial,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                onTap: () {
                  setState(() => _country = c);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(title: const BrandAppBarTitle()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.t('login_title'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session.t('login_body'),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _pickCountry,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _country.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _country.dial,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _controller,
                        keyboardType: TextInputType.phone,
                        autofocus: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                        decoration: InputDecoration(
                          hintText: session.t('phone_number'),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Enter your phone number';
                          if (value.length < 7) return 'Number looks too short';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const InfoBanner(
                  icon: Icons.sms_outlined,
                  message: 'Your number is used only to send your SMS '
                      'verification code and secure your account. '
                      'Standard SMS rates may apply.',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: session.busy ? null : _submit,
                  child: session.busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(session.t('send_code')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
