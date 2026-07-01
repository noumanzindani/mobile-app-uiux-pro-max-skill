/**
 * CheckoutScreen.tsx — a trustworthy, low-friction checkout for the skill's Checkout example.
 *
 * Implements the full spec: a single scroll with an ALWAYS-VISIBLE, itemized,
 * editable order summary (subtotal / shipping / tax / discount / total, tabular
 * figures, locale currency via Intl.NumberFormat); prominent guest checkout; a
 * platform-styled native Pay shortcut surfaced early; an address form with
 * autofill + validation; a payment step (native Pay / saved card / paste-safe new
 * card on a numeric keyboard); and a STICKY, full-width primary button that states
 * the amount ("Pay $55.95").
 *
 * SAFETY-CRITICAL payment: the submit is idempotent (a client-side idempotency key
 * so a retry or double-tap can never create two charges), the button disables +
 * spins the instant it's tapped, every attempt resolves to a definitive success or
 * a recoverable failure (never a limbo), offline BLOCKS the charge with a clear
 * reason while preserving all entries, and a decline preserves ALL input so the
 * user can retry without re-typing.
 *
 * Every screen condition is a member of CheckoutStatus and every visual value comes
 * from checkoutTokens.ts (no raw hex/spacing literals in this file).
 *
 * NOTE: order placement + native-Pay availability are injectable props defaulting
 * to light mocks, so the file compiles and runs standalone. In a real app, wire the
 * native Pay shortcut to a platform library (Apple Pay / Google Pay) at the call site.
 */
import React, {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import {
  AccessibilityInfo,
  ActivityIndicator,
  Animated,
  I18nManager,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  findNodeHandle,
  useColorScheme,
} from 'react-native';
import type { TextInputProps } from 'react-native';
import {
  SafeAreaView,
  useSafeAreaInsets,
} from 'react-native-safe-area-context';
import NetInfo from '@react-native-community/netinfo';

import {
  ColorRoles,
  getColors,
  motion,
  radius,
  size,
  spacing,
  tabular,
  typography,
} from './checkoutTokens';

/**
 * The 8 checkout conditions. `processing` is the safety-critical member — while it
 * is active the primary button is disabled + busy and no second charge can start.
 */
export type CheckoutStatus =
  | 'ideal'
  | 'empty'
  | 'loading'
  | 'processing'
  | 'error'
  | 'offline'
  | 'success'
  | 'permissionDenied';

/** One cart line. `unitPrice` is in minor currency units (e.g. cents). */
export type CartItem = {
  id: string;
  title: string;
  qty: number;
  unitPrice: number;
  note?: string;
};

/** Returned by a successful order placement. */
export type OrderConfirmation = {
  orderNumber: string;
  etaText: string;
  receiptUrl?: string;
};

type PlaceOrderArgs = {
  idempotencyKey: string;
  amount: number; // minor units — exactly what the button showed
  currency: string;
};

type CheckoutScreenProps = {
  locale?: string;
  currency?: string;
  initialItems?: CartItem[];
  /** Flat shipping fee in minor units. */
  shipping?: number;
  /** Fraction 0..1 applied to the discounted subtotal. */
  taxRate?: number;
  /** Promo/discount in minor units. */
  discount?: number;
  /** Whether the platform Pay sheet is offered up front. */
  nativePayAvailable?: boolean;
  /** Place the order. Reject to exercise the recoverable decline path. */
  placeOrder?: (args: PlaceOrderArgs) => Promise<OrderConfirmation>;
  /** Native Pay availability/auth (biometric/NFC). false/reject => permissionDenied fallback. */
  requestNativePay?: () => Promise<boolean>;
  onBrowse?: () => void;
  onSignIn?: () => void;
  onClose?: () => void;
  onTrackOrder?: () => void;
  onViewReceipt?: () => void;
  onCreateAccount?: () => void;
};

type PaymentMethod = 'native' | 'saved' | 'new';

type AddressFields = {
  name: string;
  line1: string;
  city: string;
  postalCode: string;
  country: string;
};
type AddressErrors = Partial<Record<keyof AddressFields, string>>;

type CardFields = { number: string; expiry: string; cvv: string };
type CardErrors = Partial<Record<keyof CardFields, string>>;

const noop = () => {};

const DEFAULT_ITEMS: CartItem[] = [
  { id: 'sku-1', title: 'Merino Runner — Ash', qty: 1, unitPrice: 3200, note: 'US 10' },
  { id: 'sku-2', title: 'Everyday Crew Socks (3-pack)', qty: 2, unitPrice: 900 },
];

const SAVED_CARD = { brand: 'Visa', last4: '4242' } as const;

/** A stable per-attempt idempotency key — reused across retries so a decline can be
 *  retried without ever risking a duplicate charge on the payment processor. */
function makeIdempotencyKey(): string {
  return `idem-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

const defaultPlaceOrder = async (_args: PlaceOrderArgs): Promise<OrderConfirmation> => {
  // Illustrative latency only — replace with a real payment call.
  await new Promise((resolve) => setTimeout(resolve, motion.emphasis));
  return {
    orderNumber: 'EZ-10428',
    etaText: 'Arrives Tue, Jul 8',
    receiptUrl: undefined,
  };
};

const defaultRequestNativePay = async () => true;

export default function CheckoutScreen({
  locale = 'en-US',
  currency = 'USD',
  initialItems = DEFAULT_ITEMS,
  shipping = 500,
  taxRate = 0.084,
  discount = 300,
  nativePayAvailable = true,
  placeOrder = defaultPlaceOrder,
  requestNativePay = defaultRequestNativePay,
  onBrowse = noop,
  onSignIn = noop,
  onClose = noop,
  onTrackOrder = noop,
  onViewReceipt = noop,
  onCreateAccount = noop,
}: CheckoutScreenProps) {
  const scheme = useColorScheme();
  const colors = getColors(scheme);
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => makeStyles(colors), [colors]);

  const [items, setItems] = useState<CartItem[]>(initialItems);
  const [status, setStatus] = useState<CheckoutStatus>('loading');
  const [isConnected, setIsConnected] = useState(true);
  const [reduceMotion, setReduceMotion] = useState(false);
  const [liveMessage, setLiveMessage] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const [confirmation, setConfirmation] = useState<OrderConfirmation | null>(null);
  const [paidAmount, setPaidAmount] = useState(0);

  const [method, setMethod] = useState<PaymentMethod>(
    nativePayAvailable ? 'native' : 'saved',
  );
  const [address, setAddress] = useState<AddressFields>({
    name: '',
    line1: '',
    city: '',
    postalCode: '',
    country: '',
  });
  const [addressErrors, setAddressErrors] = useState<AddressErrors>({});
  const [card, setCard] = useState<CardFields>({ number: '', expiry: '', cvv: '' });
  const [cardErrors, setCardErrors] = useState<CardErrors>({});

  const submittingRef = useRef(false); // hard guard against a double-charge
  const idempotencyKey = useRef(makeIdempotencyKey()).current;
  const errorRef = useRef<View>(null);
  const totalAnim = useRef(new Animated.Value(1)).current;
  const checkAnim = useRef(new Animated.Value(0)).current;

  const isEmpty = items.length === 0;

  // --- Money -----------------------------------------------------------------
  const money = useMemo(
    () => new Intl.NumberFormat(locale, { style: 'currency', currency }),
    [locale, currency],
  );
  const fmt = useCallback((minor: number) => money.format(minor / 100), [money]);

  const subtotal = useMemo(
    () => items.reduce((sum, it) => sum + it.unitPrice * it.qty, 0),
    [items],
  );
  const shippingCost = isEmpty ? 0 : shipping;
  const tax = Math.round(Math.max(subtotal - discount, 0) * taxRate);
  const total = Math.max(subtotal + shippingCost + tax - discount, 0);

  const announce = useCallback((msg: string) => {
    setLiveMessage(msg);
    AccessibilityInfo.announceForAccessibility(msg);
  }, []);

  // Reduce-motion preference gates the success check + the total transition.
  useEffect(() => {
    let mounted = true;
    AccessibilityInfo.isReduceMotionEnabled().then((value) => {
      if (mounted) setReduceMotion(value);
    });
    const sub = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduceMotion);
    return () => {
      mounted = false;
      sub.remove();
    };
  }, []);

  // Connectivity — blocks the charge and drives the non-blocking offline banner.
  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener((state) => {
      setIsConnected(state.isConnected ?? true);
    });
    return () => unsubscribe();
  }, []);

  // Initial "computing totals" pass, then settle into ideal / empty.
  useEffect(() => {
    let active = true;
    setStatus('loading');
    const t = setTimeout(() => {
      if (active) setStatus(initialItems.length === 0 ? 'empty' : 'ideal');
    }, motion.base);
    return () => {
      active = false;
      clearTimeout(t);
    };
  }, [initialItems.length]);

  // Announce total changes via a live region + a subtle (reduce-motion-aware) fade.
  const prevTotal = useRef(total);
  useEffect(() => {
    if (prevTotal.current === total) return;
    prevTotal.current = total;
    setLiveMessage(`Order total updated to ${fmt(total)}`);
    if (reduceMotion) {
      totalAnim.setValue(1);
      return;
    }
    totalAnim.setValue(0.4);
    Animated.timing(totalAnim, {
      toValue: 1,
      duration: motion.base,
      useNativeDriver: true,
    }).start();
  }, [total, reduceMotion, fmt, totalAnim]);

  // Move focus to the decline banner and announce it when it appears.
  useEffect(() => {
    if (status !== 'error') return;
    const node = errorRef.current ? findNodeHandle(errorRef.current) : null;
    if (node != null) AccessibilityInfo.setAccessibilityFocus(node);
  }, [status]);

  // Play the success check-in once (honest — the receipt is never gated behind it).
  useEffect(() => {
    if (status !== 'success') return;
    if (reduceMotion) {
      checkAnim.setValue(1);
      return;
    }
    checkAnim.setValue(0);
    Animated.timing(checkAnim, {
      toValue: 1,
      duration: motion.success,
      useNativeDriver: true,
    }).start();
  }, [status, reduceMotion, checkAnim]);

  const changeQty = useCallback((id: string, delta: number) => {
    setItems((prev) =>
      prev
        .map((it) => (it.id === id ? { ...it, qty: it.qty + delta } : it))
        .filter((it) => it.qty > 0),
    );
  }, []);

  // React to cart-size changes without clobbering in-flight or terminal states.
  useEffect(() => {
    setStatus((s) => {
      if (s === 'loading' || s === 'processing' || s === 'success') return s;
      if (items.length === 0) return 'empty';
      return s === 'empty' ? 'ideal' : s;
    });
  }, [items.length]);

  const validate = useCallback((): boolean => {
    const aErr: AddressErrors = {};
    if (method !== 'native') {
      if (!address.name.trim()) aErr.name = 'Enter the name on the order.';
      if (!address.line1.trim()) aErr.line1 = 'Enter your street address.';
      if (!address.city.trim()) aErr.city = 'Enter your city or town.';
      if (!address.postalCode.trim()) aErr.postalCode = 'Enter your postal code.';
      if (!address.country.trim()) aErr.country = 'Enter your country.';
    }
    const cErr: CardErrors = {};
    if (method === 'new') {
      if (card.number.length < 12) cErr.number = 'Enter a valid card number.';
      if (!/^\d{2}\/\d{2}$/.test(card.expiry)) cErr.expiry = 'Use MM / YY.';
      if (card.cvv.length < 3) cErr.cvv = 'Enter the security code.';
    }
    setAddressErrors(aErr);
    setCardErrors(cErr);
    const ok = Object.keys(aErr).length === 0 && Object.keys(cErr).length === 0;
    if (!ok) announce('Some details need fixing before you can pay.');
    return ok;
  }, [method, address, card, announce]);

  // --- The safety-critical submit -------------------------------------------
  const handlePay = useCallback(async () => {
    if (submittingRef.current) return; // no second charge, ever
    if (isEmpty) return;

    // Offline BLOCKS the charge — never silently fire; entries are preserved.
    if (!isConnected) {
      setStatus('offline');
      announce(
        'You are offline, so your payment was not sent. Your details are saved — reconnect to pay.',
      );
      return;
    }
    if (!validate()) return;

    submittingRef.current = true;
    setErrorMessage('');
    setStatus('processing');
    announce('Processing payment');

    const chargedAmount = total; // exactly what the button showed (PAY-006)
    try {
      const result = await placeOrder({ idempotencyKey, amount: chargedAmount, currency });
      setConfirmation(result);
      setPaidAmount(chargedAmount);
      setStatus('success');
      announce(`Payment successful. Order ${result.orderNumber}. ${result.etaText}.`);
    } catch {
      // Recoverable failure — a definite outcome, all input preserved for retry.
      setErrorMessage('Card declined — try another method or check your details.');
      setStatus('error');
      announce('Card declined. Try another method or check your details, then pay again.');
    } finally {
      submittingRef.current = false; // retry reuses the same idempotency key
    }
  }, [isEmpty, isConnected, validate, total, placeOrder, idempotencyKey, currency, announce]);

  const onNativePay = useCallback(async () => {
    setMethod('native');
    try {
      const ok = await requestNativePay();
      if (!ok) {
        // Never block checkout on Pay availability — fall back to manual card.
        setStatus('permissionDenied');
        setMethod('new');
        announce(
          'Native Pay is unavailable on this device. Switched to card entry — you can still check out.',
        );
        return;
      }
      handlePay();
    } catch {
      setStatus('permissionDenied');
      setMethod('new');
      announce(
        'Native Pay could not start. Switched to card entry — you can still check out.',
      );
    }
  }, [requestNativePay, handlePay, announce]);

  const isProcessing = status === 'processing';
  const hardDisabled = !isConnected || isEmpty;
  const payDisabled = hardDisabled || isProcessing;
  const footerPad = insets.bottom + spacing.sm;

  // --- Empty: a designed dead-end escape, not a blank screen -----------------
  if (isEmpty || status === 'empty') {
    return (
      <SafeAreaView edges={['top', 'bottom']} style={styles.container}>
        <LiveRegion message={liveMessage} styles={styles} />
        <Header title="Checkout" onClose={onClose} styles={styles} />
        <View
          accessible
          accessibilityRole="text"
          accessibilityLabel="Your cart is empty."
          style={styles.stateWrap}
        >
          <Text style={styles.stateGlyph}>{'🛒'}</Text>
          <Text accessibilityRole="header" style={styles.stateTitle}>
            Your cart is empty
          </Text>
          <Text style={styles.stateBody}>
            Nothing here yet — add something you love and it will show up in your
            order summary.
          </Text>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Browse products"
            onPress={onBrowse}
            style={({ pressed }) => [
              styles.primaryButton,
              pressed ? styles.primaryButtonPressed : null,
            ]}
          >
            <Text style={styles.primaryLabel}>Browse products</Text>
          </Pressable>
        </View>
      </SafeAreaView>
    );
  }

  // --- Success: order number + receipt + ETA + next steps --------------------
  if (status === 'success' && confirmation) {
    return (
      <SafeAreaView edges={['top', 'bottom']} style={styles.container}>
        <LiveRegion message={liveMessage} styles={styles} />
        <Header title="Order confirmed" onClose={onClose} styles={styles} />
        <ScrollView contentContainerStyle={styles.scrollContent}>
          <View
            accessible
            accessibilityLiveRegion="assertive"
            accessibilityLabel={`Payment successful. Order ${confirmation.orderNumber}.`}
            style={styles.successHero}
          >
            <Animated.Text
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
              style={[
                styles.successCheck,
                { opacity: checkAnim, transform: [{ scale: checkAnim }] },
              ]}
            >
              {'✓'}
            </Animated.Text>
            <Text accessibilityRole="header" style={styles.stateTitle}>
              Payment successful
            </Text>
            <Text style={styles.stateBody}>
              Thanks! We emailed your receipt and started preparing your order.
            </Text>
          </View>

          <View style={styles.card}>
            <SummaryRow label="Order number" value={confirmation.orderNumber} styles={styles} />
            <SummaryRow label="Total paid" value={fmt(paidAmount)} strong styles={styles} />
            <SummaryRow label="Estimated arrival" value={confirmation.etaText} styles={styles} />
          </View>

          <View style={styles.card}>
            <Text accessibilityRole="header" style={styles.sectionTitle}>
              What&apos;s next
            </Text>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="View receipt"
              onPress={onViewReceipt}
              style={({ pressed }) => [
                styles.primaryButton,
                pressed ? styles.primaryButtonPressed : null,
              ]}
            >
              <Text style={styles.primaryLabel}>View receipt</Text>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Track order"
              onPress={onTrackOrder}
              style={styles.secondaryButton}
            >
              <Text style={styles.secondaryLabel}>Track order</Text>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Save details and create an account"
              onPress={onCreateAccount}
              hitSlop={size.hitSlop}
              style={styles.linkButton}
            >
              <Text style={styles.linkLabel}>Save my details for next time</Text>
            </Pressable>
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }

  // --- Loading: computing totals --------------------------------------------
  if (status === 'loading') {
    return (
      <SafeAreaView edges={['top', 'bottom']} style={styles.container}>
        <LiveRegion message={liveMessage} styles={styles} />
        <Header title="Checkout" onClose={onClose} styles={styles} />
        <View
          accessible
          accessibilityRole="progressbar"
          accessibilityLabel="Calculating your total"
          style={styles.stateWrap}
        >
          <ActivityIndicator color={colors.actionPrimary} />
          <Text style={styles.stateBody}>Calculating your total…</Text>
        </View>
      </SafeAreaView>
    );
  }

  // --- Main checkout (ideal / processing / error / offline / permissionDenied) --
  const payAccessibilityLabel = isProcessing
    ? 'Processing payment'
    : `Pay ${fmt(total)}`;

  return (
    <SafeAreaView edges={['top']} style={styles.container}>
      <LiveRegion message={liveMessage} styles={styles} />
      <Header title="Checkout" onClose={onClose} styles={styles} />

      {/* Offline BLOCKS the charge — stated plainly, entries preserved (OFF-002). */}
      {!isConnected ? (
        <View accessible accessibilityRole="alert" accessibilityLiveRegion="polite" style={styles.banner}>
          <Text
            style={styles.bannerIcon}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {'⚠'}
          </Text>
          <Text style={styles.bannerText}>
            You&apos;re offline — we won&apos;t charge you until you reconnect. Your
            details are saved.
          </Text>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Retry connection"
            onPress={() => NetInfo.refresh()}
            hitSlop={size.hitSlop}
            style={styles.bannerAction}
          >
            <Text style={styles.bannerLink}>Retry</Text>
          </Pressable>
        </View>
      ) : null}

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={insets.top}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
          keyboardDismissMode="on-drag"
        >
          {/* Recoverable decline — retry without re-entry via the Pay button (FRM-009). */}
          {status === 'error' ? (
            <View
              ref={errorRef}
              accessible
              accessibilityRole="alert"
              accessibilityLiveRegion="assertive"
              style={styles.errorBanner}
            >
              <Text
                style={styles.errorIcon}
                accessibilityElementsHidden
                importantForAccessibility="no-hide-descendants"
              >
                {'⚠'}
              </Text>
              <Text style={styles.errorText}>{errorMessage}</Text>
            </View>
          ) : null}

          {/* ALWAYS-VISIBLE, editable, itemized order summary + honest total (PAY-006). */}
          <View style={styles.card}>
            <Text accessibilityRole="header" style={styles.sectionTitle}>
              Order summary
            </Text>

            {items.map((it) => (
              <View key={it.id} style={styles.itemRow}>
                <View style={styles.itemInfo}>
                  <Text style={styles.itemTitle} numberOfLines={2}>
                    {it.title}
                  </Text>
                  {it.note ? (
                    <Text style={styles.itemMeta} numberOfLines={1}>
                      {it.note}
                    </Text>
                  ) : null}
                  <Stepper
                    label={it.title}
                    qty={it.qty}
                    onDec={() => changeQty(it.id, -1)}
                    onInc={() => changeQty(it.id, 1)}
                    styles={styles}
                  />
                </View>
                <Text style={styles.itemPrice} numberOfLines={1} allowFontScaling>
                  {fmt(it.unitPrice * it.qty)}
                </Text>
              </View>
            ))}

            <View style={styles.divider} />

            <SummaryRow label="Subtotal" value={fmt(subtotal)} styles={styles} />
            <SummaryRow label="Shipping" value={fmt(shippingCost)} styles={styles} />
            <SummaryRow label="Tax" value={fmt(tax)} styles={styles} />
            <SummaryRow
              label="Discount"
              value={`− ${fmt(discount)}`}
              positive
              styles={styles}
            />

            <View style={styles.totalRow}>
              <Text style={styles.totalLabel}>Total</Text>
              <Animated.Text
                accessibilityLiveRegion="polite"
                accessibilityLabel={`Total ${fmt(total)}`}
                allowFontScaling
                style={[styles.totalValue, { opacity: totalAnim }]}
              >
                {fmt(total)}
              </Animated.Text>
            </View>
          </View>

          {/* Prominent guest checkout; the account ask is deferred to post-purchase. */}
          <View style={styles.card}>
            <Text accessibilityRole="header" style={styles.sectionTitle}>
              How would you like to check out?
            </Text>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Continue as guest"
              onPress={noop}
              style={({ pressed }) => [
                styles.primaryButton,
                pressed ? styles.primaryButtonPressed : null,
              ]}
            >
              <Text style={styles.primaryLabel}>Continue as guest</Text>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Sign in for faster checkout"
              onPress={onSignIn}
              hitSlop={size.hitSlop}
              style={styles.linkButton}
            >
              <Text style={styles.linkLabel}>Sign in for faster checkout</Text>
            </Pressable>
          </View>

          {/* Native Pay shortcut, surfaced early, platform-styled (PAY-001). */}
          {nativePayAvailable ? (
            <View style={styles.card}>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={`${Platform.OS === 'ios' ? 'Apple Pay' : 'Google Pay'}. Pay ${fmt(total)}`}
                accessibilityState={{ disabled: hardDisabled }}
                disabled={hardDisabled}
                onPress={onNativePay}
                style={({ pressed }) => [
                  styles.nativePayButton,
                  pressed && !hardDisabled ? styles.nativePayPressed : null,
                ]}
              >
                <Text style={styles.nativePayMark}>{''}</Text>
                <Text style={styles.nativePayLabel}>
                  {Platform.OS === 'ios' ? 'Buy with  Apple Pay' : 'Buy with  Google Pay'}
                </Text>
              </Pressable>
              <Text style={styles.dividerLabel}>or pay another way</Text>
            </View>
          ) : null}

          {/* Address — autofill + password managers + paste, then validate (PAY-009). */}
          <View style={styles.card}>
            <Text accessibilityRole="header" style={styles.sectionTitle}>
              Shipping address
            </Text>
            <Field
              label="Full name"
              value={address.name}
              onChangeText={(v) => setAddress((a) => ({ ...a, name: v }))}
              error={addressErrors.name}
              nativeID="addr-name"
              textContentType="name"
              autoComplete="name"
              placeholder="Alex Morgan"
              styles={styles}
              colors={colors}
            />
            <Field
              label="Street address"
              value={address.line1}
              onChangeText={(v) => setAddress((a) => ({ ...a, line1: v }))}
              error={addressErrors.line1}
              nativeID="addr-line1"
              textContentType="fullStreetAddress"
              autoComplete="street-address"
              placeholder="123 Market St"
              styles={styles}
              colors={colors}
            />
            <View style={styles.fieldRow}>
              <View style={styles.fieldCol}>
                <Field
                  label="City"
                  value={address.city}
                  onChangeText={(v) => setAddress((a) => ({ ...a, city: v }))}
                  error={addressErrors.city}
                  nativeID="addr-city"
                  textContentType="addressCity"
                  autoComplete="postal-address-locality"
                  placeholder="Denver"
                  styles={styles}
                  colors={colors}
                />
              </View>
              <View style={styles.fieldCol}>
                <Field
                  label="Postal code"
                  value={address.postalCode}
                  onChangeText={(v) => setAddress((a) => ({ ...a, postalCode: v }))}
                  error={addressErrors.postalCode}
                  nativeID="addr-zip"
                  textContentType="postalCode"
                  autoComplete="postal-code"
                  keyboardType="number-pad"
                  placeholder="80202"
                  styles={styles}
                  colors={colors}
                />
              </View>
            </View>
            <Field
              label="Country"
              value={address.country}
              onChangeText={(v) => setAddress((a) => ({ ...a, country: v }))}
              error={addressErrors.country}
              nativeID="addr-country"
              textContentType="countryName"
              autoComplete="country"
              placeholder="United States"
              styles={styles}
              colors={colors}
            />
          </View>

          {/* Payment — native Pay / saved / paste-safe new card (PAY-005, FRM-014). */}
          <View style={styles.card}>
            <Text accessibilityRole="header" style={styles.sectionTitle}>
              Payment method
            </Text>

            {status === 'permissionDenied' ? (
              <View accessible accessibilityRole="text" style={styles.noteRow}>
                <Text
                  style={styles.noteIcon}
                  accessibilityElementsHidden
                  importantForAccessibility="no-hide-descendants"
                >
                  {'ⓘ'}
                </Text>
                <Text style={styles.noteText}>
                  Native Pay isn&apos;t available here — enter a card below to finish.
                  Nothing was charged.
                </Text>
              </View>
            ) : null}

            {nativePayAvailable ? (
              <MethodOption
                selected={method === 'native'}
                title={Platform.OS === 'ios' ? 'Apple Pay' : 'Google Pay'}
                meta="Fastest — no typing"
                onPress={() => setMethod('native')}
                styles={styles}
              />
            ) : null}
            <MethodOption
              selected={method === 'saved'}
              title={`${SAVED_CARD.brand} ending ${SAVED_CARD.last4}`}
              meta="Saved card"
              onPress={() => setMethod('saved')}
              styles={styles}
            />
            <MethodOption
              selected={method === 'new'}
              title="New card"
              meta="Paste or type — number pad"
              onPress={() => setMethod('new')}
              styles={styles}
            />

            {method === 'new' ? (
              <View style={styles.cardForm}>
                <Field
                  label="Card number"
                  value={groupCardNumber(card.number)}
                  onChangeText={(v) =>
                    setCard((c) => ({ ...c, number: v.replace(/[^0-9]/g, '').slice(0, 19) }))
                  }
                  error={cardErrors.number}
                  nativeID="card-number"
                  textContentType="creditCardNumber"
                  autoComplete="cc-number"
                  keyboardType="number-pad"
                  placeholder="1234 5678 9012 3456"
                  styles={styles}
                  colors={colors}
                />
                <View style={styles.fieldRow}>
                  <View style={styles.fieldCol}>
                    <Field
                      label="Expiry (MM / YY)"
                      value={card.expiry}
                      onChangeText={(v) => setCard((c) => ({ ...c, expiry: formatExpiry(v) }))}
                      error={cardErrors.expiry}
                      nativeID="card-exp"
                      autoComplete="cc-exp"
                      keyboardType="number-pad"
                      placeholder="08 / 27"
                      styles={styles}
                      colors={colors}
                    />
                  </View>
                  <View style={styles.fieldCol}>
                    <Field
                      label="Security code"
                      value={card.cvv}
                      onChangeText={(v) =>
                        setCard((c) => ({ ...c, cvv: v.replace(/[^0-9]/g, '').slice(0, 4) }))
                      }
                      error={cardErrors.cvv}
                      nativeID="card-cvv"
                      autoComplete="cc-csc"
                      keyboardType="number-pad"
                      placeholder="123"
                      styles={styles}
                      colors={colors}
                    />
                  </View>
                </View>
              </View>
            ) : null}

            <View style={styles.trustRow}>
              <Text
                style={styles.trustIcon}
                accessibilityElementsHidden
                importantForAccessibility="no-hide-descendants"
              >
                {'🔒'}
              </Text>
              <Text style={styles.trustText}>Encrypted — we never store your CVV.</Text>
            </View>
          </View>
        </ScrollView>

        {/* STICKY, full-width primary — states the amount; idempotent + busy-guarded. */}
        <View style={[styles.footer, { paddingBottom: footerPad }]}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={payAccessibilityLabel}
            accessibilityState={{ disabled: payDisabled, busy: isProcessing }}
            accessibilityHint={
              !isConnected ? 'You are offline. Reconnect to complete payment.' : undefined
            }
            disabled={payDisabled}
            onPress={handlePay}
            style={({ pressed }) => [
              styles.payButton,
              hardDisabled ? styles.payButtonDisabled : null,
              pressed && !payDisabled ? styles.payButtonPressed : null,
            ]}
          >
            {isProcessing ? <ActivityIndicator color={colors.onActionPrimary} /> : null}
            <Text
              style={[styles.payLabel, hardDisabled ? styles.payLabelDisabled : null]}
              numberOfLines={1}
              allowFontScaling
            >
              {isProcessing ? 'Processing…' : `Pay ${fmt(total)}`}
            </Text>
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

// --- Header -----------------------------------------------------------------
type HeaderProps = { title: string; onClose: () => void; styles: Styles };
function Header({ title, onClose, styles }: HeaderProps) {
  return (
    <View style={styles.header}>
      <Text accessibilityRole="header" style={styles.headerTitle} numberOfLines={1}>
        {title}
      </Text>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Close checkout"
        onPress={onClose}
        hitSlop={size.hitSlop}
        style={styles.iconButton}
      >
        <Text style={styles.headerGlyph}>{'✕'}</Text>
      </Pressable>
    </View>
  );
}

// --- Screen-reader live region (visually hidden) ----------------------------
function LiveRegion({ message, styles }: { message: string; styles: Styles }) {
  return (
    <Text accessibilityLiveRegion="polite" accessibilityLabel={message} style={styles.srOnly}>
      {message}
    </Text>
  );
}

// --- Summary row (label start, amount end) ----------------------------------
type SummaryRowProps = {
  label: string;
  value: string;
  strong?: boolean;
  positive?: boolean;
  styles: Styles;
};
function SummaryRow({ label, value, strong, positive, styles }: SummaryRowProps) {
  return (
    <View style={styles.summaryRow}>
      <Text style={strong ? styles.totalLabel : styles.summaryLabel} numberOfLines={1}>
        {label}
      </Text>
      <Text
        style={[
          strong ? styles.totalValue : styles.summaryValue,
          positive ? styles.summaryPositive : null,
        ]}
        numberOfLines={1}
        allowFontScaling
      >
        {value}
      </Text>
    </View>
  );
}

// --- Quantity stepper -------------------------------------------------------
type StepperProps = {
  label: string;
  qty: number;
  onDec: () => void;
  onInc: () => void;
  styles: Styles;
};
function Stepper({ label, qty, onDec, onInc, styles }: StepperProps) {
  return (
    <View
      style={styles.stepper}
      accessibilityRole="adjustable"
      accessibilityLabel={`${label} quantity`}
      accessibilityValue={{ text: `${qty}` }}
    >
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`Decrease ${label} quantity`}
        onPress={onDec}
        hitSlop={size.hitSlop}
        style={({ pressed }) => [styles.stepperButton, pressed ? styles.stepperPressed : null]}
      >
        <Text style={styles.stepperGlyph}>{'−'}</Text>
      </Pressable>
      <Text style={styles.qtyText} accessibilityLiveRegion="polite" allowFontScaling>
        {qty}
      </Text>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`Increase ${label} quantity`}
        onPress={onInc}
        hitSlop={size.hitSlop}
        style={({ pressed }) => [styles.stepperButton, pressed ? styles.stepperPressed : null]}
      >
        <Text style={styles.stepperGlyph}>{'＋'}</Text>
      </Pressable>
    </View>
  );
}

// --- Payment method option --------------------------------------------------
type MethodOptionProps = {
  selected: boolean;
  title: string;
  meta: string;
  onPress: () => void;
  styles: Styles;
};
function MethodOption({ selected, title, meta, onPress, styles }: MethodOptionProps) {
  return (
    <Pressable
      accessibilityRole="radio"
      accessibilityState={{ selected }}
      accessibilityLabel={`${title}. ${meta}`}
      onPress={onPress}
      style={[styles.methodOption, selected ? styles.methodOptionSelected : null]}
    >
      <View style={[styles.radio, selected ? styles.radioSelected : null]}>
        {selected ? <View style={styles.radioDot} /> : null}
      </View>
      <View style={styles.methodInfo}>
        <Text style={styles.methodTitle} numberOfLines={1}>
          {title}
        </Text>
        <Text style={styles.methodMeta} numberOfLines={1}>
          {meta}
        </Text>
      </View>
    </Pressable>
  );
}

// --- Labeled, paste-friendly field ------------------------------------------
type FieldProps = {
  label: string;
  value: string;
  onChangeText: (v: string) => void;
  error?: string;
  nativeID: string;
  styles: Styles;
  colors: ColorRoles;
} & Pick<
  TextInputProps,
  'textContentType' | 'autoComplete' | 'keyboardType' | 'placeholder'
>;
function Field({
  label,
  value,
  onChangeText,
  error,
  nativeID,
  styles,
  colors,
  ...inputProps
}: FieldProps) {
  const errorId = `${nativeID}-error`;
  return (
    <View style={styles.field}>
      <Text nativeID={nativeID} style={styles.fieldLabel}>
        {label}
      </Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        accessibilityLabel={label}
        accessibilityLabelledBy={nativeID}
        placeholderTextColor={colors.onSurfaceMuted}
        allowFontScaling
        style={[styles.input, error ? styles.inputError : null]}
        {...inputProps}
      />
      {error ? (
        <View style={styles.fieldErrorRow} accessibilityLiveRegion="polite">
          <Text
            style={styles.fieldErrorIcon}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {'⚠'}
          </Text>
          <Text nativeID={errorId} style={styles.fieldError}>
            {error}
          </Text>
        </View>
      ) : null}
    </View>
  );
}

// --- Card formatting helpers (paste-safe: normalize, never block paste) ------
function groupCardNumber(digits: string): string {
  return digits.replace(/(.{4})/g, '$1 ').trim();
}
function formatExpiry(raw: string): string {
  const d = raw.replace(/[^0-9]/g, '').slice(0, 4);
  return d.length > 2 ? `${d.slice(0, 2)} / ${d.slice(2)}` : d;
}

type Styles = ReturnType<typeof makeStyles>;

function makeStyles(colors: ColorRoles) {
  return StyleSheet.create({
    flex: { flex: 1 },
    container: { flex: 1, backgroundColor: colors.surface },
    srOnly: {
      position: 'absolute',
      width: size.hairline,
      height: size.hairline,
      overflow: 'hidden',
      opacity: 0,
    },
    // Header
    header: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.sm,
      borderBottomWidth: size.hairline,
      borderBottomColor: colors.outline,
      backgroundColor: colors.surface,
    },
    headerTitle: { ...typography.titleMd, flex: 1, color: colors.onSurface },
    headerGlyph: { ...typography.titleMd, color: colors.onSurface },
    iconButton: {
      minWidth: size.target,
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
    },
    // Scroll body
    scrollContent: { padding: spacing.lg, gap: spacing.lg },
    card: {
      gap: spacing.md,
      padding: spacing.lg,
      borderRadius: radius.lg,
      backgroundColor: colors.surfaceContainer,
    },
    sectionTitle: { ...typography.bodyStrong, color: colors.onSurface },
    // Order-summary items
    itemRow: {
      flexDirection: 'row',
      alignItems: 'flex-start',
      gap: spacing.md,
    },
    itemInfo: { flex: 1, gap: spacing.sm },
    itemTitle: { ...typography.bodyMd, color: colors.onSurface },
    itemMeta: { ...typography.labelSm, color: colors.onSurfaceMuted },
    itemPrice: { ...typography.bodyStrong, ...tabular, color: colors.onSurface },
    divider: { height: size.hairline, backgroundColor: colors.outline },
    // Summary rows
    summaryRow: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: spacing.md,
    },
    summaryLabel: { ...typography.bodyMd, flex: 1, color: colors.onSurfaceMuted },
    summaryValue: { ...typography.bodyMd, ...tabular, color: colors.onSurface },
    summaryPositive: { color: colors.statusSuccess },
    totalRow: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: spacing.md,
      paddingTop: spacing.md,
      borderTopWidth: size.hairline,
      borderTopColor: colors.outline,
    },
    totalLabel: { ...typography.titleMd, flex: 1, color: colors.onSurfaceStrong },
    totalValue: { ...typography.titleMd, ...tabular, color: colors.onSurfaceStrong },
    // Buttons — primary / secondary / link
    primaryButton: {
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.md,
      borderRadius: radius.md,
      backgroundColor: colors.actionPrimary,
    },
    primaryButtonPressed: { backgroundColor: colors.actionPrimaryPressed },
    primaryLabel: { ...typography.labelMd, color: colors.onActionPrimary },
    secondaryButton: {
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.md,
      borderRadius: radius.md,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surface,
    },
    secondaryLabel: { ...typography.labelMd, color: colors.onSurface },
    linkButton: {
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
      paddingHorizontal: spacing.sm,
    },
    linkLabel: { ...typography.labelMd, color: colors.actionPrimary },
    // Native Pay (platform brand)
    nativePayButton: {
      minHeight: size.target,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      gap: spacing.sm,
      paddingHorizontal: spacing.lg,
      borderRadius: radius.md,
      backgroundColor: colors.nativePayFill,
    },
    nativePayPressed: { opacity: 0.85 },
    nativePayMark: { ...typography.titleMd, color: colors.onNativePay },
    nativePayLabel: { ...typography.bodyStrong, color: colors.onNativePay },
    dividerLabel: {
      ...typography.labelSm,
      color: colors.onSurfaceMuted,
      textAlign: 'center',
    },
    // Fields
    field: { gap: spacing.xs },
    fieldRow: { flexDirection: 'row', gap: spacing.md },
    fieldCol: { flex: 1 },
    fieldLabel: { ...typography.labelSm, color: colors.onSurfaceMuted },
    input: {
      ...typography.bodyMd,
      minHeight: size.target,
      paddingHorizontal: spacing.md,
      paddingVertical: spacing.sm,
      borderRadius: radius.md,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surface,
      color: colors.onSurface,
      writingDirection: I18nManager.isRTL ? 'rtl' : 'ltr',
    },
    inputError: { borderColor: colors.statusError, borderWidth: size.focusRing },
    fieldErrorRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
    fieldErrorIcon: { ...typography.labelSm, color: colors.statusError },
    fieldError: { ...typography.labelSm, flex: 1, color: colors.statusError },
    // Payment method options
    methodOption: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.md,
      minHeight: size.target,
      padding: spacing.md,
      borderRadius: radius.md,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surface,
    },
    methodOptionSelected: {
      borderColor: colors.actionPrimary,
      borderWidth: size.focusRing,
    },
    radio: {
      width: size.icon,
      height: size.icon,
      borderRadius: radius.pill,
      borderWidth: size.focusRing,
      borderColor: colors.outline,
      alignItems: 'center',
      justifyContent: 'center',
    },
    radioSelected: { borderColor: colors.actionPrimary },
    radioDot: {
      width: spacing.md,
      height: spacing.md,
      borderRadius: radius.pill,
      backgroundColor: colors.actionPrimary,
    },
    methodInfo: { flex: 1, gap: spacing.none },
    methodTitle: { ...typography.bodyMd, color: colors.onSurface },
    methodMeta: { ...typography.labelSm, color: colors.onSurfaceMuted },
    cardForm: { gap: spacing.md },
    // Trust + note
    trustRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
    trustIcon: { ...typography.labelSm, color: colors.statusSuccess },
    trustText: { ...typography.labelSm, flex: 1, color: colors.onSurfaceMuted },
    noteRow: {
      flexDirection: 'row',
      alignItems: 'flex-start',
      gap: spacing.sm,
      padding: spacing.md,
      borderRadius: radius.md,
      backgroundColor: colors.surfaceDim,
    },
    noteIcon: { ...typography.bodyMd, color: colors.actionPrimary },
    noteText: { ...typography.labelSm, flex: 1, color: colors.onSurface },
    // Quantity stepper
    stepper: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
    stepperButton: {
      minWidth: size.target,
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: radius.md,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surface,
    },
    stepperPressed: { backgroundColor: colors.surfaceDim },
    stepperGlyph: { ...typography.titleMd, color: colors.onSurface },
    qtyText: {
      ...typography.bodyStrong,
      ...tabular,
      minWidth: size.qtyMin,
      color: colors.onSurface,
    },
    // Offline banner
    banner: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.sm,
      backgroundColor: colors.surfaceDim,
    },
    bannerIcon: { ...typography.bodyMd, color: colors.onSurface },
    bannerText: { ...typography.labelSm, flex: 1, color: colors.onSurface },
    bannerAction: {
      minHeight: size.target,
      justifyContent: 'center',
      paddingHorizontal: spacing.sm,
    },
    bannerLink: { ...typography.labelMd, color: colors.actionPrimary },
    // Decline banner
    errorBanner: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      padding: spacing.md,
      borderRadius: radius.md,
      borderWidth: size.hairline,
      borderColor: colors.statusError,
      backgroundColor: colors.surfaceDim,
    },
    errorIcon: { ...typography.bodyMd, color: colors.statusError },
    errorText: { ...typography.labelMd, flex: 1, color: colors.statusError },
    // Sticky footer
    footer: {
      paddingHorizontal: spacing.lg,
      paddingTop: spacing.md,
      borderTopWidth: size.hairline,
      borderTopColor: colors.outline,
      backgroundColor: colors.surface,
    },
    payButton: {
      minHeight: size.target,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      gap: spacing.sm,
      paddingHorizontal: spacing.lg,
      borderRadius: radius.md,
      backgroundColor: colors.actionPrimary,
    },
    payButtonPressed: { backgroundColor: colors.actionPrimaryPressed },
    payButtonDisabled: { backgroundColor: colors.actionDisabled },
    payLabel: { ...typography.bodyStrong, ...tabular, color: colors.onActionPrimary },
    payLabelDisabled: { color: colors.onActionDisabled },
    // Full-screen states
    stateWrap: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
      gap: spacing.md,
      paddingHorizontal: spacing.xl,
    },
    stateGlyph: { ...typography.titleLg },
    stateTitle: { ...typography.titleMd, color: colors.onSurface, textAlign: 'center' },
    stateBody: {
      ...typography.bodyMd,
      color: colors.onSurfaceMuted,
      textAlign: 'center',
    },
    successHero: { alignItems: 'center', gap: spacing.sm, paddingVertical: spacing.lg },
    successCheck: { ...typography.titleLg, color: colors.statusSuccess },
  });
}
