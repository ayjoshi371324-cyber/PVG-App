import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

enum RazorpayPaymentMethod {
  upi,
  card,
  netbanking,
  paymentLink,
}

/// Razorpay Test Mode checkout sheet supporting UPI, Cards, Netbanking,
/// and web/desktop hosted Payment Link simulated fallback.
class RazorpayCheckoutSheet extends StatefulWidget {
  const RazorpayCheckoutSheet({
    super.key,
    required this.receipt,
    required this.onPaymentComplete,
    this.isWebOrDesktop = false,
    this.onCancel,
  });

  final TripReceipt receipt;
  final ValueChanged<TripReceipt> onPaymentComplete;
  final bool isWebOrDesktop;
  final VoidCallback? onCancel;

  @override
  State<RazorpayCheckoutSheet> createState() => _RazorpayCheckoutSheetState();
}

class _RazorpayCheckoutSheetState extends State<RazorpayCheckoutSheet> {
  late RazorpayPaymentMethod _selectedMethod;
  String _selectedUpiApp = 'Google Pay';
  String _selectedCardType = 'Visa (Test 4111...)';
  String _selectedBank = 'HDFC Bank';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedMethod = (widget.isWebOrDesktop || kIsWeb)
        ? RazorpayPaymentMethod.paymentLink
        : RazorpayPaymentMethod.upi;
  }

  String get _paymentMethodLabel {
    switch (_selectedMethod) {
      case RazorpayPaymentMethod.upi:
        return 'UPI ($_selectedUpiApp)';
      case RazorpayPaymentMethod.card:
        return 'Card ($_selectedCardType)';
      case RazorpayPaymentMethod.netbanking:
        return 'Netbanking ($_selectedBank)';
      case RazorpayPaymentMethod.paymentLink:
        return 'Razorpay Payment Link (Web/Desktop)';
    }
  }

  void _processPayment() {
    final txId = 'pay_test_${DateTime.now().millisecondsSinceEpoch}';
    final updatedReceipt = widget.receipt.copyWith(
      paymentStatus: PaymentStatus.completed,
      paymentTransactionId: txId,
      paymentMethod: _paymentMethodLabel,
    );

    setState(() {
      _isProcessing = false;
    });

    widget.onPaymentComplete(updatedReceipt);
  }

  @override
  Widget build(BuildContext context) {
    final amountRupees = (widget.receipt.effectiveFarePaise / 100.0).toStringAsFixed(2);
    final paise = widget.receipt.effectiveFarePaise;

    return Container(
      padding: const EdgeInsets.all(UberSpacing.lg),
      decoration: BoxDecoration(
        color: UberColors.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Razorpay Test Mode branding
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(UberSpacing.xs),
                decoration: const BoxDecoration(
                  color: UberColors.accentBlueSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: UberColors.accentBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: UberSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Razorpay Test Mode',
                      style: UberTypography.bodyMdStrong.copyWith(
                        color: UberColors.accentBlue,
                      ),
                    ),
                    Text(
                      'Instant Sandbox Settlement • Exact Shapley Allocation',
                      style: UberTypography.caption,
                    ),
                  ],
                ),
              ),
              if (widget.onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: widget.onCancel,
                ),
            ],
          ),

          const SizedBox(height: UberSpacing.md),

          // Amount Card
          UberCard(
            variant: UberCardVariant.elevated,
            padding: const EdgeInsets.all(UberSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Payable',
                      style: UberTypography.caption,
                    ),
                    Text(
                      '₹$amountRupees',
                      style: UberTypography.displayMd.copyWith(
                        fontWeight: FontWeight.w900,
                        color: UberColors.ink,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: UberColors.canvasSoft,
                    borderRadius: UberRadii.pill,
                  ),
                  child: Text(
                    '$paise paise',
                    style: UberTypography.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: UberColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.md),

          // Method Selector Tabs
          Row(
            children: [
              _buildMethodTab(RazorpayPaymentMethod.upi, 'UPI', Icons.phone_android_rounded, const Key('tab_upi')),
              const SizedBox(width: 4),
              _buildMethodTab(RazorpayPaymentMethod.card, 'Card', Icons.credit_card_rounded, const Key('tab_card')),
              const SizedBox(width: 4),
              _buildMethodTab(RazorpayPaymentMethod.netbanking, 'Netbanking', Icons.account_balance_rounded, const Key('tab_netbanking')),
              const SizedBox(width: 4),
              _buildMethodTab(RazorpayPaymentMethod.paymentLink, 'Link', Icons.link_rounded, const Key('tab_payment_link')),
            ],
          ),

          const SizedBox(height: UberSpacing.md),

          // Method Content Card
          _buildMethodContent(),

          const SizedBox(height: UberSpacing.lg),

          // Action Button
          if (_selectedMethod == RazorpayPaymentMethod.paymentLink)
            PillButton(
              key: const Key('simulate_link_checkout_button'),
              label: 'Complete via Payment Link',
              size: PillButtonSize.large,
              fullWidth: true,
              variant: PillButtonVariant.primary,
              icon: Icons.open_in_new_rounded,
              isLoading: _isProcessing,
              onPressed: _isProcessing ? null : _processPayment,
            )
          else
            PillButton(
              key: const Key('razorpay_pay_button'),
              label: 'Pay ₹$amountRupees',
              size: PillButtonSize.large,
              fullWidth: true,
              variant: PillButtonVariant.primary,
              icon: Icons.payment_rounded,
              isLoading: _isProcessing,
              onPressed: _isProcessing ? null : _processPayment,
            ),
        ],
      ),
    );
  }

  Widget _buildMethodTab(RazorpayPaymentMethod method, String label, IconData icon, [Key? key]) {
    final isSelected = _selectedMethod == method;

    return Expanded(
      child: InkWell(
        key: key,
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
        },
        borderRadius: UberRadii.md,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? UberColors.ink : UberColors.canvasSoft,
            borderRadius: UberRadii.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? UberColors.onDark : UberColors.body,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: UberTypography.caption.copyWith(
                    color: isSelected ? UberColors.onDark : UberColors.body,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodContent() {
    switch (_selectedMethod) {
      case RazorpayPaymentMethod.upi:
        return UberCard(
          variant: UberCardVariant.tinted,
          padding: const EdgeInsets.all(UberSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select UPI App', style: UberTypography.bodySmStrong),
              const SizedBox(height: UberSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Google Pay', 'PhonePe', 'Paytm', 'BHIM'].map((app) {
                  final isChosen = _selectedUpiApp == app;
                  return ChoiceChip(
                    label: Text(app),
                    selected: isChosen,
                    onSelected: (val) {
                      if (val) setState(() => _selectedUpiApp = app);
                    },
                    selectedColor: UberColors.accentGreenSoft,
                    labelStyle: UberTypography.caption.copyWith(
                      color: isChosen ? UberColors.accentGreen : UberColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case RazorpayPaymentMethod.card:
        return UberCard(
          variant: UberCardVariant.tinted,
          padding: const EdgeInsets.all(UberSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Test Card (Visa / RuPay)', style: UberTypography.bodySmStrong),
              const SizedBox(height: UberSpacing.xs),
              Wrap(
                spacing: 8,
                children: [
                  'Visa (Test 4111...)',
                  'MasterCard (Test 5123...)',
                  'RuPay (Test 6071...)',
                ].map((card) {
                  final isChosen = _selectedCardType == card;
                  return ChoiceChip(
                    label: Text(card),
                    selected: isChosen,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCardType = card);
                    },
                    selectedColor: UberColors.accentBlueSoft,
                    labelStyle: UberTypography.caption.copyWith(
                      color: isChosen ? UberColors.accentBlue : UberColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case RazorpayPaymentMethod.netbanking:
        return UberCard(
          variant: UberCardVariant.tinted,
          padding: const EdgeInsets.all(UberSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Popular Bank', style: UberTypography.bodySmStrong),
              const SizedBox(height: UberSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['HDFC Bank', 'ICICI Bank', 'SBI', 'Axis Bank'].map((bank) {
                  final isChosen = _selectedBank == bank;
                  return ChoiceChip(
                    label: Text(bank),
                    selected: isChosen,
                    onSelected: (val) {
                      if (val) setState(() => _selectedBank = bank);
                    },
                    selectedColor: UberColors.canvasSoft,
                    labelStyle: UberTypography.caption.copyWith(
                      color: UberColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case RazorpayPaymentMethod.paymentLink:
        return UberCard(
          variant: UberCardVariant.tinted,
          padding: const EdgeInsets.all(UberSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.desktop_windows_rounded, size: 20, color: UberColors.body),
                  const SizedBox(width: UberSpacing.xs),
                  Text('Web / Desktop Fallback', style: UberTypography.bodySmStrong),
                ],
              ),
              const SizedBox(height: UberSpacing.xs),
              Text(
                'Generate a secure Razorpay test payment link or simulate direct settlement for web and desktop platforms.',
                style: UberTypography.caption.copyWith(color: UberColors.body),
              ),
            ],
          ),
        );
    }
  }
}
