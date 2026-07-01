// checkout_screen.dart
//
// A trustworthy, low-friction checkout built to the spec in
// examples/checkout/spec.md. Single scrollable flow with an always-visible,
// itemized order summary; prominent guest checkout; a platform-styled native Pay
// shortcut; an autofilled + validated address form; paste-safe payment fields; an
// editable review; and a sticky, full-width primary button that states the amount.
//
// SAFETY-CRITICAL PAYMENT (spec "Payment-processing"):
//   - Idempotent submit — a client-side idempotency key means a retry or a
//     double-tap can never create two charges.
//   - The instant Pay is tapped the button disables + spins, so a second tap is
//     impossible.
//   - Every attempt resolves to a DEFINITIVE success or a clear, recoverable
//     failure — never an ambiguous limbo.
//   - Offline BLOCKS the charge with a stated reason and preserves all entries.
//   - A decline preserves ALL entered data and retries without re-entry.
//
// Every color / spacing / radius / size / duration / text style comes from
// checkout_tokens.dart — this file holds no raw design values (token_lint). Money
// is formatted with `intl` (locale currency) in tabular figures.
//
// Drop-in: `CheckoutScreen(placeOrder: myChargeFn, onBrowse: goShop)`. See README.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'checkout_tokens.dart';

/// The eight UI states of the checkout flow (spec "States map", plus the
/// safety-critical `processing`). Modeled as an explicit enum so the switchboard
/// is exhaustive and no state is ever "forgotten".
enum CheckoutStatus {
  /// Ready to pay — items + honest total, native Pay available, review editable.
  ideal,

  /// No items — an empty-cart state with a Browse CTA, never a dead end.
  empty,

  /// Computing totals / fetching the cart — inline progress, no interaction lost.
  loading,

  /// Charge in flight — button disabled + spinner, idempotent, no second tap.
  processing,

  /// Declined / payment fault — specific recoverable message, all input preserved.
  error,

  /// No connectivity — the charge is blocked with a reason; entries preserved.
  offline,

  /// Order placed — confirmation with order number, receipt, ETA, next steps.
  success,

  /// Native Pay (biometric/NFC) unavailable — explain, fall back to manual card.
  permissionDenied,
}

/// The definitive outcome of a charge attempt. There is no "maybe" — the flow
/// always lands on exactly one of these (spec: never limbo).
enum PaymentOutcome { success, declined, networkError }

/// How the user is paying. Native Pay is offered first; a saved card is one-tap;
/// a new card is the fallback.
enum PaymentMethod { nativePay, savedCard, newCard }

/// One line in the cart. Money is integer cents to avoid float drift.
@immutable
class CartLine {
  const CartLine({
    required this.id,
    required this.name,
    required this.qty,
    required this.unitPriceCents,
  });

  final String id;
  final String name;
  final int qty;
  final int unitPriceCents;

  int get lineTotalCents => unitPriceCents * qty;

  CartLine copyWith({int? qty}) => CartLine(
        id: id,
        name: name,
        qty: qty ?? this.qty,
        unitPriceCents: unitPriceCents,
      );
}

/// A tokenized saved card — only the brand + last four are ever held client-side.
@immutable
class SavedCard {
  const SavedCard({required this.brand, required this.last4});
  final String brand;
  final String last4;
}

/// The request handed to [CheckoutScreen.placeOrder]. The [idempotencyKey] is the
/// contract that makes the charge safe to retry.
@immutable
class PaymentRequest {
  const PaymentRequest({
    required this.idempotencyKey,
    required this.method,
    required this.amountCents,
    required this.isGuest,
  });

  final String idempotencyKey;
  final PaymentMethod method;
  final int amountCents;
  final bool isGuest;
}

/// Copy. Kept as constants so layout code stays about layout; route through your
/// i18n layer in a real app (whole messages, no concatenation — L10N-002).
class _Strings {
  const _Strings._();

  static const String title = 'Checkout';
  static const String orderSummary = 'Order summary';
  static const String subtotal = 'Subtotal';
  static const String shipping = 'Shipping';
  static const String freeShipping = 'Free';
  static const String tax = 'Estimated tax';
  static const String discount = 'Discount';
  static const String total = 'Total';
  static const String showSummary = 'Show order summary';
  static const String hideSummary = 'Hide order summary';

  static const String identity = 'How would you like to check out?';
  static const String continueAsGuest = 'Continue as guest';
  static const String guestBlurb =
      'No account needed. You can save your details after you pay.';
  static const String haveAccount = 'Sign in for faster checkout';

  static const String expressPay = 'Express checkout';
  static const String applePay = 'Pay';
  static const String googlePay = 'Buy with Google Pay';

  static const String shippingTo = 'Shipping address';
  static const String fullName = 'Full name';
  static const String address1 = 'Address';
  static const String city = 'City';
  static const String postal = 'ZIP / postal code';
  static const String required = 'Required';
  static const String postalInvalid = 'Enter a valid postal code';

  static const String payment = 'Payment';
  static const String newCard = 'New card';
  static const String cardNumber = 'Card number';
  static const String cardNumberHint = '1234 5678 9012 3456';
  static const String expiry = 'Expiry (MM/YY)';
  static const String cvv = 'CVV';
  static const String cardNumberInvalid = 'Enter a valid card number';
  static const String expiryInvalid = 'MM/YY';
  static const String cvvInvalid = '3-4 digits';

  static const String review = 'Review your order';
  static const String editAddress = 'Edit address';
  static const String editPayment = 'Edit payment';
  static const String increase = 'Increase quantity';
  static const String decrease = 'Decrease quantity';
  static const String remove = 'Remove item';
  static const String eachSuffix = ' each';

  static const String promoLabel = 'Promo code';
  static const String promoHint = 'e.g. WELCOME10';
  static const String apply = 'Apply';
  static const String promoApplied = 'Promo applied';
  static const String promoInvalid = "That code isn't valid";
  static const String freeShipNudge = 'more for free shipping';

  static const String secure = 'Secure, encrypted payment';
  static const String payPrefix = 'Pay ';
  static const String processing = 'Processing payment…';
  static const String processingAnnounce = 'Processing payment, please wait';

  static const String offlineBanner = "You're offline — check your connection";
  static const String offlineReason =
      "You're offline. We won't charge you until you're back online — your details "
      'are saved.';
  static const String declined =
      'Card declined — no charge was made. Try another card or payment method.';
  static const String networkFailed =
      "Payment didn't go through and you were not charged. You can safely try again.";
  static const String fixFields = 'Check the highlighted fields and try again.';

  static const String offlineToggle = 'Simulate offline (demo)';
  static const String declineToggle = 'Simulate a declined card (demo)';

  static const String emptyTitle = 'Your cart is empty';
  static const String emptyBody =
      "Nothing here yet. Browse the shop and add something you love.";
  static const String browse = 'Browse the shop';

  static const String successTitle = 'Order confirmed';
  static const String successBody =
      "Thanks! We've emailed your receipt. You'll get tracking updates as it ships.";
  static const String orderNumberLabel = 'Order number';
  static const String etaLabel = 'Estimated delivery';
  static const String eta = 'Mon – Wed';
  static const String paidLabel = 'Paid';
  static const String track = 'Track order';
  static const String viewReceipt = 'View receipt';
  static const String keepShopping = 'Continue shopping';
  static const String createAccount = 'Save your details — create an account';

  static const String permissionTitle = 'Express Pay is unavailable';
  static const String permissionBody =
      "Your device can't use Apple Pay / Google Pay right now (it may not be set "
      'up, or the hardware is off). You can pay with a card instead — nothing is '
      'lost.';
  static const String useCard = 'Pay with a card';
  static const String openSettings = 'Open Settings';
}

/// The checkout surface. All handlers are optional so it drops into any app; with
/// no arguments the demo simulates the network and runs stand-alone.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    this.placeOrder,
    this.requestNativePay,
    this.initialItems,
    this.savedCard = const SavedCard(brand: 'Visa', last4: '4242'),
    this.initialStatus,
    this.isOffline = false,
    this.onBrowse,
    this.onBack,
    this.onSignIn,
    this.onTrackOrder,
    this.onViewReceipt,
    this.onContinueShopping,
    this.onCreateAccount,
    this.onOpenSettings,
  });

  /// Charge the order. MUST be idempotent on [PaymentRequest.idempotencyKey] so a
  /// retry cannot double-charge. Returns a definitive [PaymentOutcome]. Defaults
  /// to a demo that succeeds unless the "simulate decline" switch is on.
  final Future<PaymentOutcome> Function(PaymentRequest request)? placeOrder;

  /// Present the platform Pay sheet / authenticate. Return `false` (or throw) to
  /// route to the permission-denied fallback. Defaults to a demo that grants.
  final Future<bool> Function()? requestNativePay;

  /// Initial cart. `const []` (or omitting all items) shows the empty state.
  final List<CartLine>? initialItems;

  /// The customer's one-tap saved card (brand + last four only).
  final SavedCard savedCard;

  /// Force an initial state (e.g. `CheckoutStatus.loading` to preview the
  /// totals-loading skeleton). Defaults to `ideal`, or `empty` if the cart is.
  final CheckoutStatus? initialStatus;

  /// Initial connectivity. In a real app, drive this from `connectivity_plus`.
  final bool isOffline;

  final VoidCallback? onBrowse;
  final VoidCallback? onBack;
  final VoidCallback? onSignIn;
  final VoidCallback? onTrackOrder;
  final VoidCallback? onViewReceipt;
  final VoidCallback? onContinueShopping;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onOpenSettings;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Pricing model (a real app receives these from the server).
  static const int _freeShipThresholdCents = 5000; // subtotal for free shipping
  static const int _shippingFlatCents = 499; // flat shipping under the threshold
  static const int _taxRateBps = 725; // 7.25% in basis points

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _addressKey = GlobalKey();
  final GlobalKey _paymentKey = GlobalKey();
  final FocusNode _errorFocus = FocusNode(debugLabel: 'checkoutError');

  final TextEditingController _name = TextEditingController();
  final TextEditingController _street = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _postal = TextEditingController();
  final TextEditingController _cardNumber = TextEditingController();
  final TextEditingController _cardExpiry = TextEditingController();
  final TextEditingController _cardCvv = TextEditingController();
  final TextEditingController _promo = TextEditingController();

  late List<CartLine> _lines;
  late CheckoutStatus _status;
  late String _idempotencyKey;

  PaymentMethod _method = PaymentMethod.nativePay;
  bool _isGuest = true;
  bool _summaryExpanded = true;
  bool _manualOffline = false;
  bool _simulateDecline = false;
  bool _promoApplied = false;
  String? _errorMessage;
  String? _promoError;

  // Snapshotted at success so the receipt is stable even if the cart changes.
  String? _orderNumber;
  int _paidTotalCents = 0;

  bool get _offline => widget.isOffline || _manualOffline;
  bool get _processing => _status == CheckoutStatus.processing;
  bool get _cartEmpty => _lines.isEmpty;

  @override
  void initState() {
    super.initState();
    _lines = List<CartLine>.of(widget.initialItems ?? _demoCart);
    _idempotencyKey = _newIdempotencyKey();
    _status = widget.initialStatus ??
        (_cartEmpty ? CheckoutStatus.empty : CheckoutStatus.ideal);
  }

  @override
  void didUpdateWidget(covariant CheckoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reconnecting clears the offline block but never re-fires a charge on its own
    // (idempotent + explicit-tap only) — the user re-taps Pay when ready.
    if (oldWidget.isOffline && !widget.isOffline && _status == CheckoutStatus.offline) {
      setState(() {
        _status = _cartEmpty ? CheckoutStatus.empty : CheckoutStatus.ideal;
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _errorFocus.dispose();
    _name.dispose();
    _street.dispose();
    _city.dispose();
    _postal.dispose();
    _cardNumber.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    _promo.dispose();
    super.dispose();
  }

  // --- money / totals --------------------------------------------------------

  /// Locale-aware currency in tabular figures (L10N-005 / TYP-006).
  String _money(int cents) {
    final locale = Localizations.maybeLocaleOf(context)?.toString();
    return NumberFormat.simpleCurrency(locale: locale).format(cents / 100);
  }

  int get _subtotalCents =>
      _lines.fold(0, (sum, l) => sum + l.lineTotalCents);

  bool get _freeShipping => _subtotalCents >= _freeShipThresholdCents;

  int get _shippingCents =>
      (_cartEmpty || _freeShipping) ? 0 : _shippingFlatCents;

  int get _discountCents {
    if (!_promoApplied) return 0;
    return (_subtotalCents * 10) ~/ 100; // WELCOME10 → 10% off subtotal
  }

  int get _taxableCents => _subtotalCents - _discountCents;

  int get _taxCents => (_taxableCents * _taxRateBps) ~/ 10000;

  int get _totalCents =>
      _subtotalCents + _shippingCents + _taxCents - _discountCents;

  int get _freeShipRemainingCents =>
      (_freeShipThresholdCents - _subtotalCents).clamp(0, _freeShipThresholdCents);

  String _newIdempotencyKey() =>
      'ck_${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';

  String _newOrderNumber() =>
      'EZ-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

  // --- intents ---------------------------------------------------------------

  void _changeQty(CartLine line, int delta) {
    final nextQty = line.qty + delta;
    setState(() {
      if (nextQty <= 0) {
        _lines = _lines.where((l) => l.id != line.id).toList();
      } else {
        _lines = _lines
            .map((l) => l.id == line.id ? l.copyWith(qty: nextQty) : l)
            .toList();
      }
      if (_cartEmpty) {
        _status = CheckoutStatus.empty;
      } else if (_status == CheckoutStatus.error) {
        _status = CheckoutStatus.ideal; // editing clears a stale error
        _errorMessage = null;
      }
    });
  }

  void _applyPromo() {
    final code = _promo.text.trim().toUpperCase();
    setState(() {
      if (code == 'WELCOME10') {
        _promoApplied = true;
        _promoError = null;
      } else {
        _promoApplied = false;
        _promoError = _Strings.promoInvalid;
      }
    });
  }

  void _selectMethod(PaymentMethod method) {
    if (method == PaymentMethod.nativePay) {
      _onExpressPay();
      return;
    }
    setState(() => _method = method);
  }

  Future<void> _onExpressPay() async {
    final probe = widget.requestNativePay ?? _demoNativePayAvailable;
    bool available;
    try {
      available = await probe();
    } catch (_) {
      available = false;
    }
    if (!mounted) return;
    if (!available) {
      setState(() {
        _status = CheckoutStatus.permissionDenied;
        _method = PaymentMethod.newCard; // fall back — never block checkout
      });
      await _showPermissionDenied();
      return;
    }
    setState(() => _method = PaymentMethod.nativePay);
    await _pay(PaymentMethod.nativePay);
  }

  Future<void> _pay(PaymentMethod method) async {
    // Idempotent guard: a second tap while a charge is in flight is a no-op, so a
    // double-tap can never create two charges (spec: no double-charge).
    if (_processing) return;

    // Offline BLOCKS the charge with a reason; entries are preserved untouched.
    if (_offline) {
      setState(() {
        _status = CheckoutStatus.offline;
        _errorMessage = _Strings.offlineReason;
      });
      _focusError();
      return;
    }

    // A manual card must validate before we ever attempt a charge.
    if (method != PaymentMethod.nativePay && !(_formKey.currentState?.validate() ?? true)) {
      setState(() {
        _status = CheckoutStatus.error;
        _errorMessage = _Strings.fixFields;
      });
      _focusError();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _status = CheckoutStatus.processing;
      _errorMessage = null;
    });

    final request = PaymentRequest(
      idempotencyKey: _idempotencyKey, // reused across retries → dedupe on server
      method: method,
      amountCents: _totalCents,
      isGuest: _isGuest,
    );
    final place = widget.placeOrder ?? _demoPlaceOrder;

    PaymentOutcome outcome;
    try {
      outcome = await place(request);
    } catch (_) {
      // A thrown/dropped request resolves to a definitive, recoverable failure —
      // never left spinning (spec: never limbo).
      outcome = PaymentOutcome.networkError;
    }
    if (!mounted) return;

    switch (outcome) {
      case PaymentOutcome.success:
        _finishSuccess();
      case PaymentOutcome.declined:
        _showError(_Strings.declined); // all entered data preserved for retry
      case PaymentOutcome.networkError:
        _showError(_Strings.networkFailed);
    }
  }

  void _finishSuccess() {
    setState(() {
      _paidTotalCents = _totalCents;
      _orderNumber = _newOrderNumber();
      _status = CheckoutStatus.success;
      _idempotencyKey = _newIdempotencyKey(); // fresh key for any next order
    });
  }

  void _showError(String message) {
    setState(() {
      _status = CheckoutStatus.error;
      _errorMessage = message; // input is never cleared (FRM-009)
    });
    _focusError();
  }

  void _focusError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _errorFocus.requestFocus();
    });
  }

  Future<void> _showPermissionDenied() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: CheckoutColors.of(context).surface,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: _PermissionDeniedSheet(
          colors: CheckoutColors.of(sheetContext),
          onUseCard: () {
            Navigator.of(sheetContext).pop();
            _scrollTo(_paymentKey);
          },
          onOpenSettings: () {
            Navigator.of(sheetContext).pop();
            widget.onOpenSettings?.call();
          },
        ),
      ),
    );
    if (mounted && _status == CheckoutStatus.permissionDenied) {
      setState(() => _status = _cartEmpty ? CheckoutStatus.empty : CheckoutStatus.ideal);
    }
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : CheckoutMotion.standard,
      alignment: 0,
    );
  }

  // --- demo backends (stand-alone only) --------------------------------------

  static const List<CartLine> _demoCart = [
    CartLine(id: 'tee', name: 'Merino Wool Tee', qty: 1, unitPriceCents: 3200),
    CartLine(id: 'socks', name: 'Trail Socks (2-pack)', qty: 2, unitPriceCents: 900),
  ];

  Future<PaymentOutcome> _demoPlaceOrder(PaymentRequest request) async {
    await Future<void>.delayed(CheckoutMotion.demoLatency);
    return _simulateDecline ? PaymentOutcome.declined : PaymentOutcome.success;
  }

  Future<bool> _demoNativePayAvailable() async {
    await Future<void>.delayed(CheckoutMotion.fast);
    return true;
  }

  // --- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = CheckoutColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    late final Widget body;
    switch (_status) {
      case CheckoutStatus.empty:
        body = _EmptyCart(colors: colors, onBrowse: widget.onBrowse);
      case CheckoutStatus.success:
        body = _Confirmation(
          colors: colors,
          reduceMotion: reduceMotion,
          orderNumber: _orderNumber ?? '',
          paidLabel: _money(_paidTotalCents),
          onTrackOrder: widget.onTrackOrder,
          onViewReceipt: widget.onViewReceipt,
          onContinueShopping: widget.onContinueShopping,
          onCreateAccount: widget.onCreateAccount,
        );
      case CheckoutStatus.ideal:
      case CheckoutStatus.loading:
      case CheckoutStatus.processing:
      case CheckoutStatus.error:
      case CheckoutStatus.offline:
      case CheckoutStatus.permissionDenied:
        body = _buildCheckout(colors, reduceMotion);
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        title: Text(
          _Strings.title,
          style: CheckoutType.section(context)?.copyWith(color: colors.onSurface),
        ),
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                iconSize: CheckoutSize.icon,
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }

  Widget _buildCheckout(CheckoutColors colors, bool reduceMotion) {
    final loading = _status == CheckoutStatus.loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OfflineBanner(
          visible: _offline,
          colors: colors,
          reduceMotion: reduceMotion,
        ),
        // Always-visible, expandable, itemized order summary (PAY-006).
        _OrderSummary(
          colors: colors,
          reduceMotion: reduceMotion,
          expanded: _summaryExpanded,
          onToggle: () => setState(() => _summaryExpanded = !_summaryExpanded),
          subtotal: _money(_subtotalCents),
          shipping: _freeShipping ? _Strings.freeShipping : _money(_shippingCents),
          tax: _money(_taxCents),
          discount: _promoApplied ? _money(-_discountCents) : null,
          total: _money(_totalCents),
          loading: loading,
        ),
        Expanded(
          child: loading
              ? _LoadingBody(colors: colors)
              : _CheckoutForm(
                  formKey: _formKey,
                  addressKey: _addressKey,
                  paymentKey: _paymentKey,
                  colors: colors,
                  reduceMotion: reduceMotion,
                  lines: _lines,
                  isGuest: _isGuest,
                  method: _method,
                  savedCard: widget.savedCard,
                  name: _name,
                  street: _street,
                  city: _city,
                  postal: _postal,
                  cardNumber: _cardNumber,
                  cardExpiry: _cardExpiry,
                  cardCvv: _cardCvv,
                  promo: _promo,
                  promoApplied: _promoApplied,
                  promoError: _promoError,
                  freeShipping: _freeShipping,
                  freeShipRemaining: _money(_freeShipRemainingCents),
                  manualOffline: _manualOffline,
                  simulateDecline: _simulateDecline,
                  errorMessage: _errorMessage,
                  errorVisible: _status == CheckoutStatus.error ||
                      _status == CheckoutStatus.offline,
                  errorFocus: _errorFocus,
                  money: _money,
                  onGuestChanged: (v) => setState(() => _isGuest = v),
                  onSignIn: widget.onSignIn,
                  onSelectMethod: _selectMethod,
                  onApplyPromo: _applyPromo,
                  onChangeQty: _changeQty,
                  onEditAddress: () => _scrollTo(_addressKey),
                  onEditPayment: () => _scrollTo(_paymentKey),
                  onOfflineToggle: (v) => setState(() => _manualOffline = v),
                  onDeclineToggle: (v) => setState(() => _simulateDecline = v),
                ),
        ),
        _PayBar(
          colors: colors,
          reduceMotion: reduceMotion,
          amountLabel: _money(_totalCents),
          processing: _processing,
          offline: _offline,
          onPay: () => _pay(_method),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Order summary — always visible, expandable, itemized, live-region announced.
// ---------------------------------------------------------------------------

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.colors,
    required this.reduceMotion,
    required this.expanded,
    required this.onToggle,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.discount,
    required this.total,
    required this.loading,
  });

  final CheckoutColors colors;
  final bool reduceMotion;
  final bool expanded;
  final VoidCallback onToggle;
  final String subtotal;
  final String shipping;
  final String tax;
  final String? discount;
  final String total;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle header: label + running total, always shown (>= 48dp target).
          Semantics(
            button: true,
            expanded: expanded,
            label: expanded ? _Strings.hideSummary : _Strings.showSummary,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: CheckoutSpace.edge,
                  vertical: CheckoutSpace.rowGap,
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: CheckoutSize.iconSm, color: colors.onSurfaceMuted),
                    const SizedBox(width: CheckoutSpace.sm),
                    Expanded(
                      child: Text(
                        _Strings.orderSummary,
                        style: CheckoutType.label(context)
                            ?.copyWith(color: colors.onSurface),
                      ),
                    ),
                    if (loading)
                      SizedBox.square(
                        dimension: CheckoutSize.iconSm,
                        child: CircularProgressIndicator(
                          strokeWidth: CheckoutSize.stroke,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(colors.onSurfaceMuted),
                        ),
                      )
                    else
                      Text(
                        total,
                        style: CheckoutType.amount(context)
                            ?.copyWith(color: colors.onSurfaceStrong),
                        textAlign: TextAlign.end,
                      ),
                    const SizedBox(width: CheckoutSpace.sm),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: CheckoutSize.iconSm,
                      color: colors.onSurfaceMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: reduceMotion ? Duration.zero : CheckoutMotion.standard,
            alignment: AlignmentDirectional.topStart,
            child: !expanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      CheckoutSpace.edge,
                      0,
                      CheckoutSpace.edge,
                      CheckoutSpace.rowGap,
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: _Strings.subtotal,
                          value: subtotal,
                          colors: colors,
                        ),
                        const SizedBox(height: CheckoutSpace.sm),
                        _SummaryRow(
                          label: _Strings.shipping,
                          value: shipping,
                          colors: colors,
                        ),
                        const SizedBox(height: CheckoutSpace.sm),
                        _SummaryRow(
                          label: _Strings.tax,
                          value: tax,
                          colors: colors,
                        ),
                        if (discount != null) ...[
                          const SizedBox(height: CheckoutSpace.sm),
                          _SummaryRow(
                            label: _Strings.discount,
                            value: discount!,
                            colors: colors,
                            emphasize: true,
                          ),
                        ],
                        const SizedBox(height: CheckoutSpace.rowGap),
                        Divider(height: CheckoutSpace.xs, color: colors.divider),
                        const SizedBox(height: CheckoutSpace.rowGap),
                        // The grand total, announced whenever it changes (A11Y-019).
                        Semantics(
                          liveRegion: true,
                          container: true,
                          child: _SummaryRow(
                            label: _Strings.total,
                            value: total,
                            colors: colors,
                            strong: true,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One label/amount row. The amount is tabular and logically end-aligned so it
/// mirrors and column-aligns in any locale; meaning is never carried by color
/// alone — the label always names the figure (A11Y-012).
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.colors,
    this.strong = false,
    this.emphasize = false,
    this.reduceMotion = true,
  });

  final String label;
  final String value;
  final CheckoutColors colors;
  final bool strong;
  final bool emphasize;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final labelColor = strong ? colors.onSurfaceStrong : colors.onSurfaceMuted;
    final valueColor = strong
        ? colors.onSurfaceStrong
        : (emphasize ? colors.success : colors.onSurface);
    final labelStyle = strong
        ? CheckoutType.section(context)?.copyWith(color: labelColor)
        : CheckoutType.body(context)?.copyWith(color: labelColor);
    final valueStyle = strong
        ? CheckoutType.amountStrong(context)?.copyWith(color: valueColor)
        : CheckoutType.amount(context)?.copyWith(color: valueColor);

    final valueText = Text(value, style: valueStyle, textAlign: TextAlign.end);

    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: CheckoutSpace.md),
        // The total gets a subtle cross-fade so a recompute is noticed (MOT-001).
        strong
            ? AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : CheckoutMotion.total,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: KeyedSubtree(key: ValueKey<String>(value), child: valueText),
              )
            : valueText,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The scrolling checkout body: identity, express pay, address, payment, review.
// ---------------------------------------------------------------------------

class _CheckoutForm extends StatelessWidget {
  const _CheckoutForm({
    required this.formKey,
    required this.addressKey,
    required this.paymentKey,
    required this.colors,
    required this.reduceMotion,
    required this.lines,
    required this.isGuest,
    required this.method,
    required this.savedCard,
    required this.name,
    required this.street,
    required this.city,
    required this.postal,
    required this.cardNumber,
    required this.cardExpiry,
    required this.cardCvv,
    required this.promo,
    required this.promoApplied,
    required this.promoError,
    required this.freeShipping,
    required this.freeShipRemaining,
    required this.manualOffline,
    required this.simulateDecline,
    required this.errorMessage,
    required this.errorVisible,
    required this.errorFocus,
    required this.money,
    required this.onGuestChanged,
    required this.onSignIn,
    required this.onSelectMethod,
    required this.onApplyPromo,
    required this.onChangeQty,
    required this.onEditAddress,
    required this.onEditPayment,
    required this.onOfflineToggle,
    required this.onDeclineToggle,
  });

  final GlobalKey<FormState> formKey;
  final GlobalKey addressKey;
  final GlobalKey paymentKey;
  final CheckoutColors colors;
  final bool reduceMotion;
  final List<CartLine> lines;
  final bool isGuest;
  final PaymentMethod method;
  final SavedCard savedCard;
  final TextEditingController name;
  final TextEditingController street;
  final TextEditingController city;
  final TextEditingController postal;
  final TextEditingController cardNumber;
  final TextEditingController cardExpiry;
  final TextEditingController cardCvv;
  final TextEditingController promo;
  final bool promoApplied;
  final String? promoError;
  final bool freeShipping;
  final String freeShipRemaining;
  final bool manualOffline;
  final bool simulateDecline;
  final String? errorMessage;
  final bool errorVisible;
  final FocusNode errorFocus;
  final String Function(int cents) money;
  final ValueChanged<bool> onGuestChanged;
  final VoidCallback? onSignIn;
  final ValueChanged<PaymentMethod> onSelectMethod;
  final VoidCallback onApplyPromo;
  final void Function(CartLine line, int delta) onChangeQty;
  final VoidCallback onEditAddress;
  final VoidCallback onEditPayment;
  final ValueChanged<bool> onOfflineToggle;
  final ValueChanged<bool> onDeclineToggle;

  @override
  Widget build(BuildContext context) {
    // Keyboard avoidance: lift the scroll content above the IME (FRM-003).
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Form(
      key: formKey,
      child: AutofillGroup(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsetsDirectional.fromSTEB(
            CheckoutSpace.edge,
            CheckoutSpace.lg,
            CheckoutSpace.edge,
            CheckoutSpace.lg + keyboardInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GuestChoice(
                colors: colors,
                isGuest: isGuest,
                onGuestChanged: onGuestChanged,
                onSignIn: onSignIn,
              ),
              const SizedBox(height: CheckoutSpace.lg),
              _ExpressPay(
                colors: colors,
                onPressed: () => onSelectMethod(PaymentMethod.nativePay),
              ),
              const SizedBox(height: CheckoutSpace.lg),
              _SectionCard(
                key: addressKey,
                colors: colors,
                title: _Strings.shippingTo,
                icon: Icons.local_shipping_outlined,
                child: _AddressForm(
                  colors: colors,
                  name: name,
                  street: street,
                  city: city,
                  postal: postal,
                ),
              ),
              const SizedBox(height: CheckoutSpace.lg),
              _SectionCard(
                key: paymentKey,
                colors: colors,
                title: _Strings.payment,
                icon: Icons.lock_outline,
                child: _PaymentSelector(
                  colors: colors,
                  method: method,
                  savedCard: savedCard,
                  cardNumber: cardNumber,
                  cardExpiry: cardExpiry,
                  cardCvv: cardCvv,
                  onSelectMethod: onSelectMethod,
                ),
              ),
              const SizedBox(height: CheckoutSpace.lg),
              _SectionCard(
                colors: colors,
                title: _Strings.review,
                icon: Icons.fact_check_outlined,
                child: _ReviewList(
                  colors: colors,
                  lines: lines,
                  money: money,
                  freeShipping: freeShipping,
                  freeShipRemaining: freeShipRemaining,
                  promo: promo,
                  promoApplied: promoApplied,
                  promoError: promoError,
                  onApplyPromo: onApplyPromo,
                  onChangeQty: onChangeQty,
                  onEditAddress: onEditAddress,
                  onEditPayment: onEditPayment,
                ),
              ),
              const SizedBox(height: CheckoutSpace.md),
              _ErrorRegion(
                message: errorMessage,
                visible: errorVisible && errorMessage != null,
                colors: colors,
                reduceMotion: reduceMotion,
                focusNode: errorFocus,
              ),
              const SizedBox(height: CheckoutSpace.lg),
              _DemoControls(
                colors: colors,
                offline: manualOffline,
                decline: simulateDecline,
                onOfflineToggle: onOfflineToggle,
                onDeclineToggle: onDeclineToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Guest checkout, offered prominently and pre-selected — the account ask is
/// deferred to post-purchase (PAY-003, AUTH-010).
class _GuestChoice extends StatelessWidget {
  const _GuestChoice({
    required this.colors,
    required this.isGuest,
    required this.onGuestChanged,
    required this.onSignIn,
  });

  final CheckoutColors colors;
  final bool isGuest;
  final ValueChanged<bool> onGuestChanged;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _Strings.identity,
          style: CheckoutType.section(context)?.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: CheckoutSpace.rowGap),
        _SelectableTile(
          colors: colors,
          selected: isGuest,
          title: _Strings.continueAsGuest,
          subtitle: _Strings.guestBlurb,
          leading: Icons.person_outline,
          onTap: () => onGuestChanged(true),
        ),
        const SizedBox(height: CheckoutSpace.sm),
        _SelectableTile(
          colors: colors,
          selected: !isGuest,
          title: _Strings.haveAccount,
          leading: Icons.login_outlined,
          onTap: () {
            onGuestChanged(false);
            onSignIn?.call();
          },
        ),
      ],
    );
  }
}

/// The platform-styled native Pay shortcut, surfaced early (PAY-001). Apple Pay on
/// iOS, Google Pay elsewhere. Uses the platform-mandated brand fill from the token
/// file (the one allowed exception to app tokens).
class _ExpressPay extends StatelessWidget {
  const _ExpressPay({required this.colors, required this.onPressed});

  final CheckoutColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final label = isIOS ? _Strings.applePay : _Strings.googlePay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _Strings.expressPay,
          style: CheckoutType.label(context)
              ?.copyWith(color: colors.onSurfaceMuted),
        ),
        const SizedBox(height: CheckoutSpace.sm),
        Semantics(
          button: true,
          label: isIOS ? 'Apple Pay' : 'Google Pay',
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: colors.payBrand,
              foregroundColor: colors.onPayBrand,
              minimumSize: const Size(double.infinity, CheckoutSize.targetMin),
              textStyle: CheckoutType.button(context),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(CheckoutRadius.control)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(isIOS ? Icons.apple : Icons.account_balance_wallet,
                      size: CheckoutSize.icon),
                ),
                const SizedBox(width: CheckoutSpace.sm),
                Text(label),
              ],
            ),
          ),
        ),
        const SizedBox(height: CheckoutSpace.rowGap),
        Row(
          children: [
            Expanded(child: Divider(color: colors.divider)),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: CheckoutSpace.rowGap),
              child: Text(
                'or',
                style: CheckoutType.caption(context)
                    ?.copyWith(color: colors.onSurfaceMuted),
              ),
            ),
            Expanded(child: Divider(color: colors.divider)),
          ],
        ),
      ],
    );
  }
}

/// A titled section container used for address / payment / review.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.colors,
    required this.title,
    required this.icon,
    required this.child,
  });

  final CheckoutColors colors;
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(CheckoutSpace.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius:
            const BorderRadius.all(Radius.circular(CheckoutRadius.card)),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: CheckoutSize.iconSm, color: colors.onSurfaceMuted),
              const SizedBox(width: CheckoutSpace.sm),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: CheckoutType.section(context)
                      ?.copyWith(color: colors.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: CheckoutSpace.md),
          child,
        ],
      ),
    );
  }
}

/// Address form — every field autofills (OS address book, paste, managers) and
/// validates; errors are programmatically associated with their field (A11Y-004).
class _AddressForm extends StatelessWidget {
  const _AddressForm({
    required this.colors,
    required this.name,
    required this.street,
    required this.city,
    required this.postal,
  });

  final CheckoutColors colors;
  final TextEditingController name;
  final TextEditingController street;
  final TextEditingController city;
  final TextEditingController postal;

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? _Strings.required : null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          colors: colors,
          controller: name,
          label: _Strings.fullName,
          autofillHints: const [AutofillHints.name],
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: _required,
        ),
        const SizedBox(height: CheckoutSpace.fieldGap),
        _Field(
          colors: colors,
          controller: street,
          label: _Strings.address1,
          autofillHints: const [AutofillHints.streetAddressLine1],
          keyboardType: TextInputType.streetAddress,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: _required,
        ),
        const SizedBox(height: CheckoutSpace.fieldGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _Field(
                colors: colors,
                controller: city,
                label: _Strings.city,
                autofillHints: const [AutofillHints.addressCity],
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
            ),
            const SizedBox(width: CheckoutSpace.md),
            Expanded(
              flex: 2,
              child: _Field(
                colors: colors,
                controller: postal,
                label: _Strings.postal,
                autofillHints: const [AutofillHints.postalCode],
                keyboardType: TextInputType.number, // number pad (FRM-002)
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return _Strings.required;
                  if (v.trim().length < 3) return _Strings.postalInvalid;
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Payment selection: native Pay / saved card (one-tap) / new card. New-card
/// fields use the number keyboard, autofill, and are paste-safe — masking (digit
/// grouping) never blocks paste (A11Y-015, FRM-014).
class _PaymentSelector extends StatelessWidget {
  const _PaymentSelector({
    required this.colors,
    required this.method,
    required this.savedCard,
    required this.cardNumber,
    required this.cardExpiry,
    required this.cardCvv,
    required this.onSelectMethod,
  });

  final CheckoutColors colors;
  final PaymentMethod method;
  final SavedCard savedCard;
  final TextEditingController cardNumber;
  final TextEditingController cardExpiry;
  final TextEditingController cardCvv;
  final ValueChanged<PaymentMethod> onSelectMethod;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MethodRadio<PaymentMethod>(
          colors: colors,
          value: PaymentMethod.nativePay,
          groupValue: method,
          onChanged: onSelectMethod,
          leading: Icons.account_balance_wallet_outlined,
          title: _Strings.expressPay,
        ),
        _MethodRadio<PaymentMethod>(
          colors: colors,
          value: PaymentMethod.savedCard,
          groupValue: method,
          onChanged: onSelectMethod,
          leading: Icons.credit_card,
          // Masked saved card — brand + last four only (never blocks paste; the
          // digits are never held client-side).
          title: '${savedCard.brand} •••• ${savedCard.last4}',
        ),
        _MethodRadio<PaymentMethod>(
          colors: colors,
          value: PaymentMethod.newCard,
          groupValue: method,
          onChanged: onSelectMethod,
          leading: Icons.add_card_outlined,
          title: _Strings.newCard,
        ),
        AnimatedSize(
          duration: CheckoutMotion.fast,
          alignment: AlignmentDirectional.topStart,
          child: method != PaymentMethod.newCard
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsetsDirectional.only(top: CheckoutSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Field(
                        colors: colors,
                        controller: cardNumber,
                        label: _Strings.cardNumber,
                        hint: _Strings.cardNumberHint,
                        autofillHints: const [AutofillHints.creditCardNumber],
                        keyboardType: TextInputType.number, // number pad
                        textInputAction: TextInputAction.next,
                        inputFormatters: [_CardGroupFormatter()],
                        validator: (v) {
                          final digits =
                              (v ?? '').replaceAll(RegExp(r'\D'), '');
                          return digits.length < 12
                              ? _Strings.cardNumberInvalid
                              : null;
                        },
                      ),
                      const SizedBox(height: CheckoutSpace.fieldGap),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Field(
                              colors: colors,
                              controller: cardExpiry,
                              label: _Strings.expiry,
                              autofillHints: const [
                                AutofillHints.creditCardExpirationDate
                              ],
                              keyboardType: TextInputType.datetime,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().length < 4)
                                  ? _Strings.expiryInvalid
                                  : null,
                            ),
                          ),
                          const SizedBox(width: CheckoutSpace.md),
                          Expanded(
                            child: _Field(
                              colors: colors,
                              controller: cardCvv,
                              label: _Strings.cvv,
                              autofillHints: const [
                                AutofillHints.creditCardSecurityCode
                              ],
                              keyboardType: TextInputType.number, // number pad
                              textInputAction: TextInputAction.done,
                              validator: (v) {
                                final d = (v ?? '').trim();
                                return (d.length < 3 || d.length > 4)
                                    ? _Strings.cvvInvalid
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// A tappable radio row for a payment method — the whole row is one >= 48dp target.
class _MethodRadio<T> extends StatelessWidget {
  const _MethodRadio({
    required this.colors,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.leading,
    required this.title,
  });

  final CheckoutColors colors;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final IconData leading;
  final String title;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: title,
      child: InkWell(
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
              vertical: CheckoutSpace.rowGap),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: CheckoutSize.icon,
                color: selected ? colors.primary : colors.onSurfaceMuted,
              ),
              const SizedBox(width: CheckoutSpace.md),
              Icon(leading, size: CheckoutSize.iconSm, color: colors.onSurfaceMuted),
              const SizedBox(width: CheckoutSpace.rowGap),
              Expanded(
                child: Text(
                  title,
                  style: CheckoutType.body(context)
                      ?.copyWith(color: colors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labeled, error-associated text field. `labelText` + `errorText` give the
/// field a programmatic name and its error is announced with it (A11Y-004).
class _Field extends StatelessWidget {
  const _Field({
    required this.colors,
    required this.controller,
    required this.label,
    this.hint,
    this.autofillHints,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
  });

  final CheckoutColors colors;
  final TextEditingController controller;
  final String label;
  final String? hint;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(CheckoutRadius.control));
    final base = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.outline),
    );
    return TextFormField(
      controller: controller,
      autofillHints: autofillHints,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: CheckoutType.field(context)?.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: colors.surface,
        labelStyle:
            CheckoutType.label(context)?.copyWith(color: colors.onSurfaceMuted),
        hintStyle:
            CheckoutType.body(context)?.copyWith(color: colors.onSurfaceMuted),
        errorStyle: CheckoutType.caption(context)?.copyWith(color: colors.error),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: CheckoutSpace.md,
          vertical: CheckoutSpace.md,
        ),
        border: base,
        enabledBorder: base,
        focusedBorder: base.copyWith(
          borderSide: BorderSide(color: colors.focus, width: CheckoutSize.stroke),
        ),
        errorBorder: base.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: base.copyWith(
          borderSide: BorderSide(color: colors.error, width: CheckoutSize.stroke),
        ),
      ),
    );
  }
}

/// Editable review: each line has a >= 48dp quantity stepper + remove; the promo
/// field applies a discount; and "Edit" jumps back to address/payment (FRM-013).
class _ReviewList extends StatelessWidget {
  const _ReviewList({
    required this.colors,
    required this.lines,
    required this.money,
    required this.freeShipping,
    required this.freeShipRemaining,
    required this.promo,
    required this.promoApplied,
    required this.promoError,
    required this.onApplyPromo,
    required this.onChangeQty,
    required this.onEditAddress,
    required this.onEditPayment,
  });

  final CheckoutColors colors;
  final List<CartLine> lines;
  final String Function(int cents) money;
  final bool freeShipping;
  final String freeShipRemaining;
  final TextEditingController promo;
  final bool promoApplied;
  final String? promoError;
  final VoidCallback onApplyPromo;
  final void Function(CartLine line, int delta) onChangeQty;
  final VoidCallback onEditAddress;
  final VoidCallback onEditPayment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines) ...[
          _ReviewRow(
            colors: colors,
            line: line,
            money: money,
            onChangeQty: onChangeQty,
          ),
          const SizedBox(height: CheckoutSpace.rowGap),
        ],
        if (!freeShipping)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: CheckoutSpace.rowGap),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: CheckoutSize.iconSm, color: colors.success),
                const SizedBox(width: CheckoutSpace.sm),
                Expanded(
                  child: Text(
                    'Add $freeShipRemaining ${_Strings.freeShipNudge}',
                    style: CheckoutType.caption(context)
                        ?.copyWith(color: colors.onSurfaceMuted),
                  ),
                ),
              ],
            ),
          ),
        _PromoField(
          colors: colors,
          controller: promo,
          applied: promoApplied,
          error: promoError,
          onApply: onApplyPromo,
        ),
        const SizedBox(height: CheckoutSpace.md),
        Row(
          children: [
            Expanded(
              child: _EditLink(
                colors: colors,
                label: _Strings.editAddress,
                onPressed: onEditAddress,
              ),
            ),
            const SizedBox(width: CheckoutSpace.sm),
            Expanded(
              child: _EditLink(
                colors: colors,
                label: _Strings.editPayment,
                onPressed: onEditPayment,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.colors,
    required this.line,
    required this.money,
    required this.onChangeQty,
  });

  final CheckoutColors colors;
  final CartLine line;
  final String Function(int cents) money;
  final void Function(CartLine line, int delta) onChangeQty;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${line.name}, quantity ${line.qty}, ${money(line.lineTotalCents)}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  style: CheckoutType.body(context)
                      ?.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: CheckoutSpace.xs),
                Text(
                  '${money(line.unitPriceCents)}${_Strings.eachSuffix}',
                  style: CheckoutType.caption(context)
                      ?.copyWith(color: colors.onSurfaceMuted),
                ),
                const SizedBox(height: CheckoutSpace.sm),
                _QtyStepper(colors: colors, line: line, onChangeQty: onChangeQty),
              ],
            ),
          ),
          const SizedBox(width: CheckoutSpace.md),
          Text(
            money(line.lineTotalCents),
            style: CheckoutType.amount(context)?.copyWith(color: colors.onSurface),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}

/// Quantity stepper. Both buttons are full >= 48dp targets (A11Y-003); decreasing
/// to zero removes the line. The count is read as tabular so it never jitters.
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.colors,
    required this.line,
    required this.onChangeQty,
  });

  final CheckoutColors colors;
  final CartLine line;
  final void Function(CartLine line, int delta) onChangeQty;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline),
        borderRadius:
            const BorderRadius.all(Radius.circular(CheckoutRadius.control)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onChangeQty(line, -1),
            tooltip: line.qty <= 1 ? _Strings.remove : _Strings.decrease,
            padding: const EdgeInsetsDirectional.all(CheckoutSpace.sm),
            constraints: const BoxConstraints(
              minWidth: CheckoutSize.targetMin,
              minHeight: CheckoutSize.targetMin,
            ),
            iconSize: CheckoutSize.iconSm,
            color: colors.onSurface,
            icon: Icon(line.qty <= 1 ? Icons.delete_outline : Icons.remove),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: CheckoutSpace.sm),
            child: Text(
              '${line.qty}',
              style:
                  CheckoutType.amount(context)?.copyWith(color: colors.onSurface),
            ),
          ),
          IconButton(
            onPressed: () => onChangeQty(line, 1),
            tooltip: _Strings.increase,
            padding: const EdgeInsetsDirectional.all(CheckoutSpace.sm),
            constraints: const BoxConstraints(
              minWidth: CheckoutSize.targetMin,
              minHeight: CheckoutSize.targetMin,
            ),
            iconSize: CheckoutSize.iconSm,
            color: colors.onSurface,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _PromoField extends StatelessWidget {
  const _PromoField({
    required this.colors,
    required this.controller,
    required this.applied,
    required this.error,
    required this.onApply,
  });

  final CheckoutColors colors;
  final TextEditingController controller;
  final bool applied;
  final String? error;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(CheckoutRadius.control));
    final base = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.outline),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => onApply(),
                style: CheckoutType.field(context)
                    ?.copyWith(color: colors.onSurface),
                decoration: InputDecoration(
                  labelText: _Strings.promoLabel,
                  hintText: _Strings.promoHint,
                  filled: true,
                  fillColor: colors.surface,
                  labelStyle: CheckoutType.label(context)
                      ?.copyWith(color: colors.onSurfaceMuted),
                  hintStyle: CheckoutType.body(context)
                      ?.copyWith(color: colors.onSurfaceMuted),
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: CheckoutSpace.md,
                    vertical: CheckoutSpace.md,
                  ),
                  border: base,
                  enabledBorder: base,
                  focusedBorder: base.copyWith(
                    borderSide:
                        BorderSide(color: colors.focus, width: CheckoutSize.stroke),
                  ),
                ),
              ),
            ),
            const SizedBox(width: CheckoutSpace.sm),
            OutlinedButton(
              onPressed: onApply,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, CheckoutSize.targetMin),
                foregroundColor: colors.onSurface,
                side: BorderSide(color: colors.outline),
                textStyle: CheckoutType.button(context),
                shape: const RoundedRectangleBorder(borderRadius: radius),
              ),
              child: const Text(_Strings.apply),
            ),
          ],
        ),
        if (applied || error != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: CheckoutSpace.errorGap),
            child: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Icon(
                    applied ? Icons.check_circle_outline : Icons.error_outline,
                    size: CheckoutSize.iconSm,
                    color: applied ? colors.success : colors.error,
                  ),
                  const SizedBox(width: CheckoutSpace.xs),
                  Text(
                    applied ? _Strings.promoApplied : (error ?? ''),
                    style: CheckoutType.caption(context)?.copyWith(
                        color: applied ? colors.success : colors.error),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A secondary "Edit …" link — subordinate to the one primary action, out of the
/// primary thumb arc (BTN-006), yet a full-height target.
class _EditLink extends StatelessWidget {
  const _EditLink({
    required this.colors,
    required this.label,
    required this.onPressed,
  });

  final CheckoutColors colors;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, CheckoutSize.targetMin),
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.outline),
        textStyle: CheckoutType.label(context),
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: CheckoutSpace.rowGap),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(CheckoutRadius.control)),
        ),
      ),
      icon: const Icon(Icons.edit_outlined, size: CheckoutSize.iconSm),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared / small pieces
// ---------------------------------------------------------------------------

/// A selectable tile (guest vs sign-in). The whole tile is one target; selection
/// is exposed to assistive tech and shown by an icon, never color alone.
class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.colors,
    required this.selected,
    required this.title,
    this.subtitle,
    required this.leading,
    required this.onTap,
  });

  final CheckoutColors colors;
  final bool selected;
  final String title;
  final String? subtitle;
  final IconData leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            const BorderRadius.all(Radius.circular(CheckoutRadius.card)),
        child: Container(
          padding: const EdgeInsetsDirectional.all(CheckoutSpace.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius:
                const BorderRadius.all(Radius.circular(CheckoutRadius.card)),
            border: Border.all(
              color: selected ? colors.primary : colors.divider,
              width: selected ? CheckoutSize.stroke : CheckoutSize.freeShipBar,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: CheckoutSize.icon,
                color: selected ? colors.primary : colors.onSurfaceMuted,
              ),
              const SizedBox(width: CheckoutSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CheckoutType.body(context)
                          ?.copyWith(color: colors.onSurface),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: CheckoutSpace.xs),
                      Text(
                        subtitle!,
                        style: CheckoutType.caption(context)
                            ?.copyWith(color: colors.onSurfaceMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Non-blocking offline banner, announced as a live region (STATE-008).
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({
    required this.visible,
    required this.colors,
    required this.reduceMotion,
  });

  final bool visible;
  final CheckoutColors colors;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: reduceMotion ? Duration.zero : CheckoutMotion.standard,
      alignment: AlignmentDirectional.topStart,
      child: !visible
          ? const SizedBox.shrink()
          : Semantics(
              liveRegion: true,
              container: true,
              child: Container(
                color: colors.surfaceContainer,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: CheckoutSpace.edge,
                  vertical: CheckoutSpace.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: CheckoutSize.icon, color: colors.onSurfaceMuted),
                    const SizedBox(width: CheckoutSpace.sm),
                    Expanded(
                      child: Text(
                        _Strings.offlineBanner,
                        style: CheckoutType.body(context)
                            ?.copyWith(color: colors.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Inline, recoverable error above the actions. Specific copy (which method,
/// whether a charge occurred), icon-paired (not color-only), focus-receiving, and
/// announced via a live region (STATE-007, A11Y-019). All input is preserved.
class _ErrorRegion extends StatelessWidget {
  const _ErrorRegion({
    required this.message,
    required this.visible,
    required this.colors,
    required this.reduceMotion,
    required this.focusNode,
  });

  final String? message;
  final bool visible;
  final CheckoutColors colors;
  final bool reduceMotion;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion ? Duration.zero : CheckoutMotion.standard;
    return AnimatedSize(
      duration: duration,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        child: !visible || message == null
            ? const SizedBox.shrink()
            : Focus(
                focusNode: focusNode,
                canRequestFocus: true,
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Container(
                    padding: const EdgeInsetsDirectional.all(CheckoutSpace.rowGap),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: const BorderRadius.all(
                          Radius.circular(CheckoutRadius.control)),
                      border: Border.all(color: colors.error),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline,
                            size: CheckoutSize.icon, color: colors.error),
                        const SizedBox(width: CheckoutSpace.sm),
                        Expanded(
                          child: Text(
                            message!,
                            textAlign: TextAlign.start,
                            style: CheckoutType.body(context)
                                ?.copyWith(color: colors.error),
                          ),
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

/// Demo-only affordances to preview offline + decline without a real backend.
/// Remove in production — connectivity and decisions come from the platform/server.
class _DemoControls extends StatelessWidget {
  const _DemoControls({
    required this.colors,
    required this.offline,
    required this.decline,
    required this.onOfflineToggle,
    required this.onDeclineToggle,
  });

  final CheckoutColors colors;
  final bool offline;
  final bool decline;
  final ValueChanged<bool> onOfflineToggle;
  final ValueChanged<bool> onDeclineToggle;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, bool value, ValueChanged<bool> onChanged) => Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CheckoutType.caption(context)
                    ?.copyWith(color: colors.onSurfaceMuted),
              ),
            ),
            const SizedBox(width: CheckoutSpace.sm),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        );
    return Column(
      children: [
        Divider(color: colors.divider),
        row(_Strings.offlineToggle, offline, onOfflineToggle),
        row(_Strings.declineToggle, decline, onDeclineToggle),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky Pay bar — the one primary action, full-width, stating the amount.
// ---------------------------------------------------------------------------

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.colors,
    required this.reduceMotion,
    required this.amountLabel,
    required this.processing,
    required this.offline,
    required this.onPay,
  });

  final CheckoutColors colors;
  final bool reduceMotion;
  final String amountLabel;
  final bool processing;
  final bool offline;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    // Enabled only when we can actually charge; disabled while processing (so a
    // second tap is impossible) or offline (with a spoken reason).
    final canPay = !processing && !offline;
    final reason = offline
        ? _Strings.offlineReason
        : (processing ? _Strings.processingAnnounce : '');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            CheckoutSpace.edge,
            CheckoutSpace.md,
            CheckoutSpace.edge,
            CheckoutSpace.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Trust cue — honest, paired with an icon + text, never color alone.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline,
                      size: CheckoutSize.iconSm, color: colors.success),
                  const SizedBox(width: CheckoutSpace.xs),
                  Text(
                    _Strings.secure,
                    style: CheckoutType.caption(context)
                        ?.copyWith(color: colors.onSurfaceMuted),
                  ),
                ],
              ),
              const SizedBox(height: CheckoutSpace.sm),
              // Honest, determinate-free processing announcement (no fake bar).
              if (processing)
                Semantics(
                  liveRegion: true,
                  container: true,
                  label: _Strings.processingAnnounce,
                  child: const SizedBox.shrink(),
                ),
              Semantics(
                button: true,
                enabled: canPay,
                hint: reason,
                child: FilledButton(
                  onPressed: canPay ? onPay : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    disabledBackgroundColor:
                        processing ? colors.primary : colors.surfaceContainer,
                    disabledForegroundColor:
                        processing ? colors.onPrimary : colors.onSurfaceMuted,
                    minimumSize:
                        const Size(double.infinity, CheckoutSize.targetMin),
                    textStyle: CheckoutType.amountButton(context),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(CheckoutRadius.control)),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration:
                        reduceMotion ? Duration.zero : CheckoutMotion.standard,
                    child: processing
                        ? Row(
                            key: const ValueKey<String>('processing'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox.square(
                                dimension: CheckoutSize.spinner,
                                child: CircularProgressIndicator(
                                  strokeWidth: CheckoutSize.stroke,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      colors.onPrimary),
                                ),
                              ),
                              const SizedBox(width: CheckoutSpace.sm),
                              const Text(_Strings.processing),
                            ],
                          )
                        : Text(
                            '${_Strings.payPrefix}$amountLabel',
                            key: const ValueKey<String>('pay'),
                          ),
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

// ---------------------------------------------------------------------------
// Empty cart
// ---------------------------------------------------------------------------

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.colors, required this.onBrowse});

  final CheckoutColors colors;
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(CheckoutSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: CheckoutSize.successMark, color: colors.onSurfaceMuted),
            const SizedBox(height: CheckoutSpace.md),
            Text(
              _Strings.emptyTitle,
              textAlign: TextAlign.center,
              style: CheckoutType.title(context)?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: CheckoutSpace.sm),
            Text(
              _Strings.emptyBody,
              textAlign: TextAlign.center,
              style: CheckoutType.body(context)
                  ?.copyWith(color: colors.onSurfaceMuted),
            ),
            const SizedBox(height: CheckoutSpace.lg),
            FilledButton(
              onPressed: onBrowse,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                minimumSize: const Size(double.infinity, CheckoutSize.targetMin),
                textStyle: CheckoutType.button(context),
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(CheckoutRadius.control)),
                ),
              ),
              child: const Text(_Strings.browse),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confirmation — order number, receipt (paid total), ETA, next steps.
// ---------------------------------------------------------------------------

class _Confirmation extends StatelessWidget {
  const _Confirmation({
    required this.colors,
    required this.reduceMotion,
    required this.orderNumber,
    required this.paidLabel,
    required this.onTrackOrder,
    required this.onViewReceipt,
    required this.onContinueShopping,
    required this.onCreateAccount,
  });

  final CheckoutColors colors;
  final bool reduceMotion;
  final String orderNumber;
  final String paidLabel;
  final VoidCallback? onTrackOrder;
  final VoidCallback? onViewReceipt;
  final VoidCallback? onContinueShopping;
  final VoidCallback? onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(CheckoutSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: CheckoutSpace.lg),
          // Brief check reveal — transform/opacity only, instant under reduce-motion.
          // The receipt below is never gated behind it (MOT-005).
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: reduceMotion ? 1.0 : 0.0, end: 1.0),
              duration: reduceMotion ? Duration.zero : CheckoutMotion.success,
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(scale: t, child: child),
              ),
              child: Icon(Icons.check_circle,
                  size: CheckoutSize.successMark, color: colors.success),
            ),
          ),
          const SizedBox(height: CheckoutSpace.md),
          Semantics(
            liveRegion: true,
            header: true,
            child: Text(
              _Strings.successTitle,
              textAlign: TextAlign.center,
              style: CheckoutType.title(context)?.copyWith(color: colors.onSurface),
            ),
          ),
          const SizedBox(height: CheckoutSpace.sm),
          Text(
            _Strings.successBody,
            textAlign: TextAlign.center,
            style:
                CheckoutType.body(context)?.copyWith(color: colors.onSurfaceMuted),
          ),
          const SizedBox(height: CheckoutSpace.lg),
          Container(
            padding: const EdgeInsetsDirectional.all(CheckoutSpace.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius:
                  const BorderRadius.all(Radius.circular(CheckoutRadius.card)),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              children: [
                _ReceiptRow(
                  colors: colors,
                  label: _Strings.orderNumberLabel,
                  value: orderNumber,
                ),
                const SizedBox(height: CheckoutSpace.rowGap),
                _ReceiptRow(
                  colors: colors,
                  label: _Strings.paidLabel,
                  value: paidLabel,
                  tabular: true,
                ),
                const SizedBox(height: CheckoutSpace.rowGap),
                _ReceiptRow(
                  colors: colors,
                  label: _Strings.etaLabel,
                  value: _Strings.eta,
                ),
              ],
            ),
          ),
          const SizedBox(height: CheckoutSpace.lg),
          FilledButton.icon(
            onPressed: onTrackOrder,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(double.infinity, CheckoutSize.targetMin),
              textStyle: CheckoutType.button(context),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(CheckoutRadius.control)),
              ),
            ),
            icon: const Icon(Icons.local_shipping_outlined,
                size: CheckoutSize.icon),
            label: const Text(_Strings.track),
          ),
          const SizedBox(height: CheckoutSpace.sm),
          OutlinedButton(
            onPressed: onViewReceipt,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, CheckoutSize.targetMin),
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outline),
              textStyle: CheckoutType.button(context),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(CheckoutRadius.control)),
              ),
            ),
            child: const Text(_Strings.viewReceipt),
          ),
          const SizedBox(height: CheckoutSpace.lg),
          // The account ask, deferred to post-purchase (PAY-003) — never a blocker.
          TextButton.icon(
            onPressed: onCreateAccount,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, CheckoutSize.targetMin),
              foregroundColor: colors.primary,
              textStyle: CheckoutType.button(context),
            ),
            icon: const Icon(Icons.bookmark_add_outlined,
                size: CheckoutSize.iconSm),
            label: const Text(_Strings.createAccount),
          ),
          const SizedBox(height: CheckoutSpace.sm),
          TextButton(
            onPressed: onContinueShopping,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, CheckoutSize.targetMin),
              foregroundColor: colors.onSurfaceMuted,
              textStyle: CheckoutType.button(context),
            ),
            child: const Text(_Strings.keepShopping),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.colors,
    required this.label,
    required this.value,
    this.tabular = false,
  });

  final CheckoutColors colors;
  final String label;
  final String value;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style:
                CheckoutType.body(context)?.copyWith(color: colors.onSurfaceMuted),
          ),
        ),
        const SizedBox(width: CheckoutSpace.md),
        Text(
          value,
          textAlign: TextAlign.end,
          style: tabular
              ? CheckoutType.amount(context)
                  ?.copyWith(color: colors.onSurfaceStrong)
              : CheckoutType.label(context)?.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton for totals / cart fetch.
// ---------------------------------------------------------------------------

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.colors});

  final CheckoutColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: CheckoutSize.icon,
            child: CircularProgressIndicator(
              strokeWidth: CheckoutSize.stroke,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: CheckoutSpace.md),
          Text(
            _Strings.orderSummary,
            style:
                CheckoutType.body(context)?.copyWith(color: colors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permission-denied — native Pay unavailable; fall back to a card, never blocked.
// ---------------------------------------------------------------------------

class _PermissionDeniedSheet extends StatelessWidget {
  const _PermissionDeniedSheet({
    required this.colors,
    required this.onUseCard,
    required this.onOpenSettings,
  });

  final CheckoutColors colors;
  final VoidCallback onUseCard;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CheckoutSpace.lg,
        CheckoutSpace.sm,
        CheckoutSpace.lg,
        CheckoutSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: CheckoutSize.icon, color: colors.onSurfaceMuted),
          const SizedBox(height: CheckoutSpace.sm),
          Text(
            _Strings.permissionTitle,
            style: CheckoutType.title(context)?.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: CheckoutSpace.sm),
          Text(
            _Strings.permissionBody,
            style:
                CheckoutType.body(context)?.copyWith(color: colors.onSurfaceMuted),
          ),
          const SizedBox(height: CheckoutSpace.lg),
          FilledButton(
            onPressed: onUseCard,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(double.infinity, CheckoutSize.targetMin),
              textStyle: CheckoutType.button(context),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(CheckoutRadius.control)),
              ),
            ),
            child: const Text(_Strings.useCard),
          ),
          const SizedBox(height: CheckoutSpace.sm),
          TextButton(
            onPressed: onOpenSettings,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, CheckoutSize.targetMin),
              foregroundColor: colors.onSurface,
              textStyle: CheckoutType.button(context),
            ),
            child: const Text(_Strings.openSettings),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paste-safe card number grouping. Reformats the WHOLE value on every edit —
// including a paste — into groups of four, so masking never blocks paste
// (A11Y-015 / FRM-014). It only groups digits; it never rejects input.
// ---------------------------------------------------------------------------

class _CardGroupFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 19 ? digits.substring(0, 19) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(capped[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
