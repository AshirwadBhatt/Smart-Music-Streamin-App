import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';

const _amounts = [
  (label: '☕  Coffee',    amount: 29.0),
  (label: '🍕  Pizza',     amount: 49.0),
  (label: '🎵  Album',     amount: 99.0),
  (label: '💎  Supporter', amount: 199.0),
];

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});
  @override ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  int    _selectedIndex = 0;
  bool   _customMode    = false;
  double _customAmount  = 0;
  final  _customCtrl    = TextEditingController();
  bool   _loading       = false;
  String? _statusMsg;
  bool    _success      = false;

  double get _amount => _customMode
      ? (_customAmount > 0 ? _customAmount : 0)
      : _amounts[_selectedIndex].amount;

  String get _upiUrl =>
      'upi://pay?pa=${ApiConstants.upiId}'
      '&pn=${Uri.encodeComponent(ApiConstants.upiName)}'
      '&am=${_amount.toStringAsFixed(2)}'
      '&tn=${Uri.encodeComponent(ApiConstants.upiDescription)}'
      '&cu=INR';

  Future<void> _pay() async {
    if (_amount <= 0) {
      setState(() => _statusMsg = 'Enter a valid amount');
      return;
    }
    setState(() { _loading = true; _statusMsg = null; });
    try {
      if (kIsWeb) {
        // On web show QR — handled in UI below
        setState(() { _loading = false; });
        return;
      }
      final uri = Uri.parse(_upiUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() { _success = true; _statusMsg = 'Thank you so much! 🙏'; });
      } else {
        setState(() => _statusMsg = 'No UPI app found on this device.');
      }
    } catch (e) {
      setState(() => _statusMsg = 'Error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Support ASHU'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(children: [

          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.2), AppColors.accent.withOpacity(0.15)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
            ),
            child: Column(children: [
              const Text('❤️', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              const Text('Love ASHU?', style: TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'ASHU is free and ad-free.\nIf it brings you joy, support development!\nEvery rupee helps keep it going.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
              ),
            ]),
          ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 28),

          // Amount presets
          if (!_customMode) ...[
            const Align(alignment: Alignment.centerLeft,
              child: Text('Choose an amount', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.2,
              ),
              itemCount: _amounts.length,
              itemBuilder: (_, i) {
                final isSelected = i == _selectedIndex;
                final a = _amounts[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent, width: 1.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary)),
                      Text('₹${a.amount.toInt()}', style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                    ]),
                  ),
                ).animate(delay: Duration(milliseconds: i * 60)).fade(duration: 300.ms);
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _customMode = true),
              child: const Text('Enter custom amount →',
                  style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
          ] else ...[
            TextField(
              controller: _customCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 22, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppColors.primary,
                    fontSize: 22, fontWeight: FontWeight.w700),
                hintText: '0',
                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                filled: true, fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
              onChanged: (v) => setState(() => _customAmount = double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() { _customMode = false; _customCtrl.clear(); }),
              child: const Text('← Use preset amounts',
                  style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 20),

          // ── Web/Desktop: show QR code ──
          if (kIsWeb && _amount > 0) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(children: [
                const Text('Scan with any UPI app',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Pay ₹${_amount.toInt()} via GPay / PhonePe / Paytm',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: _upiUrl,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Also show copyable UPI ID
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('UPI: ${ApiConstants.upiId}',
                        style: const TextStyle(color: AppColors.textPrimary,
                            fontSize: 13, fontFamily: 'monospace')),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          color: AppColors.textMuted, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: ApiConstants.upiId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UPI ID copied!'),
                              duration: Duration(seconds: 2)),
                        );
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                const Text('Open GPay → Scan QR or enter UPI ID manually',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center),
              ]),
            ).animate().fade(duration: 300.ms),
          ] else if (!kIsWeb) ...[
            // Mobile: direct UPI button
            if (_success)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success.withOpacity(0.4)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                  SizedBox(width: 10),
                  Text('Thank you so much! 🙏',
                      style: TextStyle(color: AppColors.success,
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ]),
              ).animate().scale(duration: 300.ms, curve: Curves.elasticOut)
            else
              ElevatedButton(
                onPressed: (_loading || _amount <= 0) ? null : _pay,
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                    : Text('Pay ₹${_amount > 0 ? _amount.toInt() : '---'} via UPI',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
          ] else ...[
            // Web but no amount selected yet
            ElevatedButton.icon(
              onPressed: _amount > 0 ? () => setState(() {}) : null,
              icon: const Icon(Icons.qr_code_rounded),
              label: Text('Generate QR for ₹${_amount > 0 ? _amount.toInt() : '---'}'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
            ),
          ],

          if (_statusMsg != null && !_success) ...[
            const SizedBox(height: 12),
            Text(_statusMsg!,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center),
          ],

          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  @override
  void dispose() { _customCtrl.dispose(); super.dispose(); }
}
