/**
 * CheckoutScreen.tsx — a trustworthy, low-friction Ionic checkout for the Checkout example.
 *
 * Idiomatic Ionic 8 + Capacitor: Ionic components + the `mode` engine for native
 * feel on both OSes, styled entirely through CSS classes / `var(--...)` tokens in
 * checkout.css (no raw #hex / px in this file). A single scroll opens with an
 * ALWAYS-VISIBLE, itemized, editable order summary (subtotal / shipping / tax /
 * discount / total, tabular figures, locale currency via Intl.NumberFormat); a
 * prominent guest-checkout CTA; a platform-styled native Pay shortcut surfaced early;
 * an address + payment form (paste-safe card entry on a numeric keyboard); and a
 * STICKY, full-width primary IonButton that states the amount ("Pay $55.95").
 *
 * Every screen condition is a member of the CheckoutStatus discriminated union —
 * idle, empty, loading, processing, error, offline, success. `processing` is the
 * safety-critical member: the submit is idempotent (a client-side idempotency key
 * reused across retries so a double-tap can never create two charges), the Pay button
 * disables + swaps its label for an IonSpinner the instant it is tapped, every attempt
 * resolves to a definite success or a recoverable failure (never a limbo), offline
 * BLOCKS the charge with a clear reason while preserving all entries, and a decline
 * keeps ALL input so the user can retry without re-typing.
 *
 * order placement + native-Pay availability are injectable props defaulting to light
 * mocks, so the file runs standalone; wire them to your API / Apple Pay / Google Pay.
 */
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  IonContent, IonPage, IonHeader, IonToolbar, IonTitle, IonButtons,
  IonInput, IonButton, IonSpinner, IonIcon, isPlatform, useIonToast,
} from '@ionic/react';
import {
  cartOutline, closeOutline, addOutline, removeOutline, lockClosedOutline,
  cloudOfflineOutline, alertCircleOutline, checkmarkCircle, informationCircleOutline,
  logoApple, logoGoogle,
} from 'ionicons/icons';
import { Network } from '@capacitor/network';
import './checkout.css';

type OrderConfirmation = { orderNumber: string; etaText: string; receiptUrl?: string };

/** The 7 checkout conditions. `processing` is the safety-critical member — while it
 *  is active the Pay button is disabled + busy and no second charge can start. */
type CheckoutStatus =
  | { kind: 'idle' }
  | { kind: 'empty' }
  | { kind: 'loading' }
  | { kind: 'processing' }
  | { kind: 'error'; message: string }
  | { kind: 'offline' }
  | { kind: 'success'; confirmation: OrderConfirmation };

/** One cart line. `unitPrice` is in minor currency units (e.g. cents). */
type CartItem = { id: string; title: string; qty: number; unitPrice: number; note?: string };

type PlaceOrderArgs = { idempotencyKey: string; amount: number; currency: string };
type PaymentMethod = 'native' | 'saved' | 'new';

type AddressFields = { name: string; line1: string; city: string; postalCode: string; country: string };
type CardFields = { number: string; expiry: string; cvv: string };

type Props = {
  locale?: string;
  currency?: string;
  initialItems?: CartItem[];
  shipping?: number;
  taxRate?: number;
  discount?: number;
  nativePayAvailable?: boolean;
  placeOrder?: (args: PlaceOrderArgs) => Promise<OrderConfirmation>;
  requestNativePay?: () => Promise<boolean>;
  onBrowse?: () => void;
  onSignIn?: () => void;
  onClose?: () => void;
  onTrackOrder?: () => void;
  onViewReceipt?: () => void;
  onCreateAccount?: () => void;
};

const noop = () => {};

const DEFAULT_ITEMS: CartItem[] = [
  { id: 'sku-1', title: 'Merino Runner — Ash', qty: 1, unitPrice: 3200, note: 'US 10' },
  { id: 'sku-2', title: 'Everyday Crew Socks (3-pack)', qty: 2, unitPrice: 900 },
];
const SAVED_CARD = { brand: 'Visa', last4: '4242' } as const;

const defaultPlaceOrder = async (): Promise<OrderConfirmation> => ({
  orderNumber: 'EZ-10428',
  etaText: 'Arrives Tue, Jul 8',
});
const defaultRequestNativePay = async () => true;

/** A stable per-attempt idempotency key — reused across retries so a decline can be
 *  retried without ever risking a duplicate charge on the payment processor. */
function makeIdempotencyKey(): string {
  return `idem-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}
function groupCardNumber(digits: string): string {
  return digits.replace(/(.{4})/g, '$1 ').trim();
}
function formatExpiry(raw: string): string {
  const d = raw.replace(/[^0-9]/g, '').slice(0, 4);
  return d.length > 2 ? `${d.slice(0, 2)} / ${d.slice(2)}` : d;
}

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
}: Props) {
  const [items, setItems] = useState<CartItem[]>(initialItems);
  const [status, setStatus] = useState<CheckoutStatus>({ kind: 'loading' });
  const [online, setOnline] = useState(true);
  const [method, setMethod] = useState<PaymentMethod>(nativePayAvailable ? 'native' : 'saved');
  const [nativePayUnavailable, setNativePayUnavailable] = useState(false);
  const [address, setAddress] = useState<AddressFields>({
    name: '', line1: '', city: '', postalCode: '', country: '',
  });
  const [addressErrors, setAddressErrors] = useState<Partial<AddressFields>>({});
  const [card, setCard] = useState<CardFields>({ number: '', expiry: '', cvv: '' });
  const [cardErrors, setCardErrors] = useState<Partial<CardFields>>({});
  const [paidAmount, setPaidAmount] = useState(0);
  const [liveMessage, setLiveMessage] = useState('');

  const submittingRef = useRef(false); // hard guard against a double-charge
  const idempotencyKey = useRef(makeIdempotencyKey()).current;
  const errorRef = useRef<HTMLDivElement>(null);
  const [present] = useIonToast();

  const nativeLabel = isPlatform('ios') ? 'Apple Pay' : 'Google Pay';
  const nativeIcon = isPlatform('ios') ? logoApple : logoGoogle;

  const announce = useCallback((msg: string) => setLiveMessage(msg), []);

  // --- Money -----------------------------------------------------------------
  const money = useMemo(
    () => new Intl.NumberFormat(locale, { style: 'currency', currency }),
    [locale, currency],
  );
  const fmt = useCallback((minor: number) => money.format(minor / 100), [money]);

  const isEmpty = items.length === 0;
  const subtotal = useMemo(
    () => items.reduce((sum, it) => sum + it.unitPrice * it.qty, 0),
    [items],
  );
  const shippingCost = isEmpty ? 0 : shipping;
  const tax = Math.round(Math.max(subtotal - discount, 0) * taxRate);
  const total = Math.max(subtotal + shippingCost + tax - discount, 0);

  // Connectivity drives the offline banner + blocks the charge (OFF-*).
  useEffect(() => {
    Network.getStatus().then((s) => setOnline(s.connected));
    let handle: { remove: () => void } | undefined;
    Network.addListener('networkStatusChange', (s) => setOnline(s.connected)).then((h) => {
      handle = h;
    });
    return () => { handle?.remove(); };
  }, []);

  // Initial "computing totals" pass, then settle into idle / empty.
  useEffect(() => {
    let active = true;
    const t = setTimeout(() => {
      if (active) setStatus({ kind: initialItems.length === 0 ? 'empty' : 'idle' });
    }, 400);
    return () => { active = false; clearTimeout(t); };
  }, [initialItems.length]);

  // Announce total changes via the live region so a change is never silent (A11Y-*).
  const prevTotal = useRef(total);
  useEffect(() => {
    if (prevTotal.current === total) return;
    prevTotal.current = total;
    announce(`Order total updated to ${fmt(total)}`);
  }, [total, fmt, announce]);

  // Move focus to the decline banner + announce it when it appears (A11Y-*).
  useEffect(() => {
    if (status.kind === 'error') errorRef.current?.focus();
  }, [status]);

  // React to cart-size changes without clobbering in-flight or terminal states.
  const changeQty = useCallback((id: string, delta: number) => {
    setItems((prev) =>
      prev
        .map((it) => (it.id === id ? { ...it, qty: it.qty + delta } : it))
        .filter((it) => it.qty > 0),
    );
  }, []);
  useEffect(() => {
    setStatus((s) => {
      if (s.kind === 'loading' || s.kind === 'processing' || s.kind === 'success') return s;
      if (items.length === 0) return { kind: 'empty' };
      return s.kind === 'empty' ? { kind: 'idle' } : s;
    });
  }, [items.length]);

  const validate = useCallback((): boolean => {
    const aErr: Partial<AddressFields> = {};
    if (method !== 'native') {
      if (!address.name.trim()) aErr.name = 'Enter the name on the order.';
      if (!address.line1.trim()) aErr.line1 = 'Enter your street address.';
      if (!address.city.trim()) aErr.city = 'Enter your city or town.';
      if (!address.postalCode.trim()) aErr.postalCode = 'Enter your postal code.';
      if (!address.country.trim()) aErr.country = 'Enter your country.';
    }
    const cErr: Partial<CardFields> = {};
    if (method === 'new') {
      if (card.number.length < 12) cErr.number = 'Enter a valid card number.';
      if (!/^\d{2}\s*\/\s*\d{2}$/.test(card.expiry)) cErr.expiry = 'Use MM / YY.';
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
    if (submittingRef.current) return;           // no second charge, ever
    if (isEmpty) return;
    if (!online) {                               // offline BLOCKS the charge
      setStatus({ kind: 'offline' });
      announce('You are offline, so your payment was not sent. Your details are saved — reconnect to pay.');
      return;
    }
    if (!validate()) return;

    submittingRef.current = true;
    setStatus({ kind: 'processing' });
    announce('Processing payment');
    const chargedAmount = total;                 // exactly what the button showed (PAY-006)
    try {
      const confirmation = await placeOrder({ idempotencyKey, amount: chargedAmount, currency });
      setPaidAmount(chargedAmount);
      setStatus({ kind: 'success', confirmation });
      announce(`Payment successful. Order ${confirmation.orderNumber}. ${confirmation.etaText}.`);
      present({ message: 'Payment successful', duration: 2000 });
    } catch {
      // Recoverable failure — a definite outcome, all input preserved for retry.
      setStatus({ kind: 'error', message: 'Card declined — try another method or check your details.' });
      announce('Card declined. Try another method or check your details, then pay again.');
    } finally {
      submittingRef.current = false;             // retry reuses the same idempotency key
    }
  }, [isEmpty, online, validate, total, placeOrder, idempotencyKey, currency, announce, present]);

  const onNativePay = useCallback(async () => {
    setMethod('native');
    try {
      const ok = await requestNativePay();
      if (!ok) {
        // Never block checkout on Pay availability — fall back to manual card.
        setNativePayUnavailable(true);
        setMethod('new');
        announce(`${nativeLabel} is unavailable on this device. Switched to card entry — you can still check out.`);
        return;
      }
      handlePay();
    } catch {
      setNativePayUnavailable(true);
      setMethod('new');
      announce(`${nativeLabel} could not start. Switched to card entry — you can still check out.`);
    }
  }, [requestNativePay, handlePay, announce, nativeLabel]);

  const isProcessing = status.kind === 'processing';
  const payDisabled = isProcessing || !online || isEmpty;

  const setAddr = (patch: Partial<AddressFields>) => setAddress((a) => ({ ...a, ...patch }));

  // --- Full-screen states ----------------------------------------------------
  if (status.kind === 'loading') {
    return (
      <IonPage>
        <Chrome title="Checkout" onClose={onClose} />
        <IonContent>
          <LiveRegion message={liveMessage} />
          <div className="checkout-state" role="status" aria-live="polite">
            <IonSpinner name="crescent" aria-hidden="true" />
            <p className="checkout-state-body">Calculating your total…</p>
          </div>
        </IonContent>
      </IonPage>
    );
  }

  if (status.kind === 'success') {
    const { confirmation } = status;
    return (
      <IonPage>
        <Chrome title="Order confirmed" onClose={onClose} />
        <IonContent>
          <LiveRegion message={liveMessage} />
          <div className="checkout-scroll">
            <div className="checkout-state">
              <IonIcon className="checkout-state-glyph is-success" icon={checkmarkCircle} aria-hidden="true" />
              <h2 className="checkout-state-title">Payment successful</h2>
              <p className="checkout-state-body">
                Thanks! We emailed your receipt and started preparing your order.
              </p>
            </div>
            <div className="checkout-card">
              <SummaryRow label="Order number" value={confirmation.orderNumber} />
              <SummaryRow label="Total paid" value={fmt(paidAmount)} strong />
              <SummaryRow label="Estimated arrival" value={confirmation.etaText} />
            </div>
            <div className="checkout-card">
              <h2 className="checkout-section-title">What&apos;s next</h2>
              <div className="checkout-confirm-actions">
                <IonButton expand="block" onClick={onViewReceipt} aria-label="View receipt">
                  View receipt
                </IonButton>
                <IonButton expand="block" fill="outline" onClick={onTrackOrder} aria-label="Track order">
                  Track order
                </IonButton>
                <IonButton fill="clear" onClick={onCreateAccount} aria-label="Save my details for next time">
                  Save my details for next time
                </IonButton>
              </div>
            </div>
          </div>
        </IonContent>
      </IonPage>
    );
  }

  if (isEmpty || status.kind === 'empty') {
    return (
      <IonPage>
        <Chrome title="Checkout" onClose={onClose} />
        <IonContent>
          <LiveRegion message={liveMessage} />
          <div className="checkout-state" role="status">
            <IonIcon className="checkout-state-glyph" icon={cartOutline} aria-hidden="true" />
            <h2 className="checkout-state-title">Your cart is empty</h2>
            <p className="checkout-state-body">
              Nothing here yet — add something you love and it will show up in your order summary.
            </p>
            <IonButton expand="block" onClick={onBrowse} aria-label="Browse products">
              Browse products
            </IonButton>
          </div>
        </IonContent>
      </IonPage>
    );
  }

  // --- Main checkout (idle / processing / error / offline) -------------------
  return (
    <IonPage>
      <Chrome title="Checkout" onClose={onClose} />
      <IonContent>
        <LiveRegion message={liveMessage} />

        {!online && (
          <div className="checkout-banner" role="alert" aria-live="polite">
            <IonIcon icon={cloudOfflineOutline} aria-hidden="true" />
            <span className="spacer">
              You&apos;re offline — we won&apos;t charge you until you reconnect. Your details are saved.
            </span>
            <IonButton
              fill="clear" size="small"
              onClick={() => Network.getStatus().then((s) => setOnline(s.connected))}
              aria-label="Retry connection"
            >
              Retry
            </IonButton>
          </div>
        )}

        <div className="checkout-scroll">
          {status.kind === 'error' && (
            <div className="checkout-error" role="alert" tabIndex={-1} ref={errorRef}>
              <IonIcon icon={alertCircleOutline} aria-hidden="true" />
              <span>{status.message}</span>
            </div>
          )}

          {/* ALWAYS-VISIBLE, editable, itemized order summary + honest total (PAY-006). */}
          <div className="checkout-card">
            <h2 className="checkout-section-title">Order summary</h2>
            {items.map((it) => (
              <div key={it.id} className="checkout-item">
                <div className="checkout-item-info">
                  <p className="checkout-item-title">{it.title}</p>
                  {it.note && <p className="checkout-item-meta">{it.note}</p>}
                  <div className="checkout-stepper" role="group" aria-label={`${it.title} quantity`}>
                    <IonButton
                      className="checkout-stepper-btn" fill="outline" size="small"
                      onClick={() => changeQty(it.id, -1)}
                      aria-label={`Decrease ${it.title} quantity`}
                    >
                      <IonIcon slot="icon-only" icon={removeOutline} aria-hidden="true" />
                    </IonButton>
                    <span className="checkout-qty" aria-live="polite">{it.qty}</span>
                    <IonButton
                      className="checkout-stepper-btn" fill="outline" size="small"
                      onClick={() => changeQty(it.id, 1)}
                      aria-label={`Increase ${it.title} quantity`}
                    >
                      <IonIcon slot="icon-only" icon={addOutline} aria-hidden="true" />
                    </IonButton>
                  </div>
                </div>
                <p className="checkout-item-price">{fmt(it.unitPrice * it.qty)}</p>
              </div>
            ))}

            <hr className="checkout-divider" />
            <SummaryRow label="Subtotal" value={fmt(subtotal)} />
            <SummaryRow label="Shipping" value={fmt(shippingCost)} />
            <SummaryRow label="Tax" value={fmt(tax)} />
            <SummaryRow label="Discount" value={`− ${fmt(discount)}`} positive />
            <div className="checkout-total-row">
              <p className="checkout-total-label">Total</p>
              <p className="checkout-total-value" aria-live="polite" aria-label={`Total ${fmt(total)}`}>
                {fmt(total)}
              </p>
            </div>
          </div>

          {/* Prominent guest checkout; the account ask is deferred to post-purchase. */}
          <div className="checkout-card">
            <h2 className="checkout-section-title">How would you like to check out?</h2>
            <IonButton expand="block" onClick={noop} aria-label="Continue as guest">
              Continue as guest
            </IonButton>
            <IonButton fill="clear" onClick={onSignIn} aria-label="Sign in for faster checkout">
              Sign in for faster checkout
            </IonButton>
            <p className="checkout-guest-hint">No account needed — create one after you pay if you like.</p>
          </div>

          {/* Native Pay shortcut, surfaced early, platform-styled (PAY-001). */}
          {nativePayAvailable && (
            <div className="checkout-card">
              <IonButton
                expand="block" className="checkout-native-pay"
                disabled={payDisabled} onClick={onNativePay}
                aria-label={`Buy with ${nativeLabel}. Pay ${fmt(total)}`}
              >
                <IonIcon slot="start" icon={nativeIcon} aria-hidden="true" />
                Buy with {nativeLabel}
              </IonButton>
              <p className="checkout-native-divider">or pay another way</p>
            </div>
          )}

          {/* Shipping address — autofill + password managers + paste, then validate (PAY-009). */}
          <div className="checkout-card">
            <h2 className="checkout-section-title">Shipping address</h2>
            <Field
              id="addr-name" label="Full name" autocomplete="name" placeholder="Alex Morgan"
              value={address.name} onValue={(v) => setAddr({ name: v })} error={addressErrors.name}
            />
            <Field
              id="addr-line1" label="Street address" autocomplete="street-address" placeholder="123 Market St"
              value={address.line1} onValue={(v) => setAddr({ line1: v })} error={addressErrors.line1}
            />
            <div className="checkout-field-row">
              <div className="checkout-field-col">
                <Field
                  id="addr-city" label="City" autocomplete="address-level2" placeholder="Denver"
                  value={address.city} onValue={(v) => setAddr({ city: v })} error={addressErrors.city}
                />
              </div>
              <div className="checkout-field-col">
                <Field
                  id="addr-zip" label="Postal code" autocomplete="postal-code" inputmode="numeric"
                  placeholder="80202" value={address.postalCode}
                  onValue={(v) => setAddr({ postalCode: v })} error={addressErrors.postalCode}
                />
              </div>
            </div>
            <Field
              id="addr-country" label="Country" autocomplete="country-name" placeholder="United States"
              value={address.country} onValue={(v) => setAddr({ country: v })} error={addressErrors.country}
            />
          </div>

          {/* Payment — native / saved / paste-safe new card (PAY-005, FRM-014). */}
          <div className="checkout-card">
            <h2 className="checkout-section-title">Payment method</h2>
            {nativePayUnavailable && (
              <div className="checkout-note" role="status">
                <IonIcon icon={informationCircleOutline} aria-hidden="true" />
                <span>{nativeLabel} isn&apos;t available here — enter a card below to finish. Nothing was charged.</span>
              </div>
            )}

            {nativePayAvailable && (
              <MethodOption
                selected={method === 'native'} title={nativeLabel} meta="Fastest — no typing"
                onPress={() => setMethod('native')}
              />
            )}
            <MethodOption
              selected={method === 'saved'} title={`${SAVED_CARD.brand} ending ${SAVED_CARD.last4}`}
              meta="Saved card" onPress={() => setMethod('saved')}
            />
            <MethodOption
              selected={method === 'new'} title="New card" meta="Paste or type — number pad"
              onPress={() => setMethod('new')}
            />

            {method === 'new' && (
              <>
                <Field
                  id="card-number" label="Card number" autocomplete="cc-number" inputmode="numeric"
                  placeholder="1234 5678 9012 3456" value={groupCardNumber(card.number)}
                  onValue={(v) => setCard((c) => ({ ...c, number: v.replace(/[^0-9]/g, '').slice(0, 19) }))}
                  error={cardErrors.number}
                />
                <div className="checkout-field-row">
                  <div className="checkout-field-col">
                    <Field
                      id="card-exp" label="Expiry (MM / YY)" autocomplete="cc-exp" inputmode="numeric"
                      placeholder="08 / 27" value={card.expiry}
                      onValue={(v) => setCard((c) => ({ ...c, expiry: formatExpiry(v) }))}
                      error={cardErrors.expiry}
                    />
                  </div>
                  <div className="checkout-field-col">
                    <Field
                      id="card-cvv" label="Security code" autocomplete="cc-csc" inputmode="numeric"
                      placeholder="123" value={card.cvv}
                      onValue={(v) => setCard((c) => ({ ...c, cvv: v.replace(/[^0-9]/g, '').slice(0, 4) }))}
                      error={cardErrors.cvv}
                    />
                  </div>
                </div>
              </>
            )}

            <div className="checkout-trust">
              <IonIcon icon={lockClosedOutline} aria-hidden="true" />
              <span>Encrypted — we never store your CVV.</span>
            </div>
          </div>
        </div>
      </IonContent>

      {/* STICKY, full-width primary — states the amount; idempotent + busy-guarded. */}
      <footer className="checkout-footer">
        <IonButton
          expand="block" className="checkout-pay" onClick={handlePay} disabled={payDisabled}
          aria-label={isProcessing ? 'Processing payment' : `Pay ${fmt(total)}`}
        >
          {isProcessing ? <IonSpinner name="crescent" aria-hidden="true" /> : `Pay ${fmt(total)}`}
        </IonButton>
        {!online && (
          <p className="checkout-pay-hint">You&apos;re offline. Reconnect to complete payment.</p>
        )}
      </footer>
    </IonPage>
  );
}

// --- Page chrome: title + close --------------------------------------------
function Chrome({ title, onClose }: { title: string; onClose: () => void }) {
  return (
    <IonHeader>
      <IonToolbar>
        <IonTitle>{title}</IonTitle>
        <IonButtons slot="end">
          <IonButton onClick={onClose} aria-label="Close checkout">
            <IonIcon slot="icon-only" icon={closeOutline} aria-hidden="true" />
          </IonButton>
        </IonButtons>
      </IonToolbar>
    </IonHeader>
  );
}

// --- Screen-reader live region (visually hidden) ---------------------------
function LiveRegion({ message }: { message: string }) {
  return (
    <div className="checkout-sr-only" role="status" aria-live="polite">{message}</div>
  );
}

// --- Summary row (label start, amount end) ---------------------------------
function SummaryRow({
  label, value, strong, positive,
}: { label: string; value: string; strong?: boolean; positive?: boolean }) {
  return (
    <div className={strong ? 'checkout-total-row' : 'checkout-summary-row'}>
      <p className={strong ? 'checkout-total-label' : 'checkout-summary-label'}>{label}</p>
      <p className={
        (strong ? 'checkout-total-value' : 'checkout-summary-value') + (positive ? ' is-positive' : '')
      }>
        {value}
      </p>
    </div>
  );
}

// --- Payment-method option (a selectable IonButton, never a bare icon) ------
function MethodOption({
  selected, title, meta, onPress,
}: { selected: boolean; title: string; meta: string; onPress: () => void }) {
  return (
    <IonButton
      expand="block" fill="outline"
      className={selected ? 'checkout-method is-selected' : 'checkout-method'}
      onClick={onPress} aria-label={`${title}. ${meta}`} aria-pressed={selected}
    >
      <div className="checkout-method-info">
        <span className="checkout-method-title">{title}</span>
        <span className="checkout-method-meta">{meta}</span>
      </div>
      {selected && <IonIcon slot="end" icon={checkmarkCircle} aria-hidden="true" />}
    </IonButton>
  );
}

// --- Labeled, paste-friendly field -----------------------------------------
function Field({
  id, label, value, onValue, error, placeholder, autocomplete, inputmode,
}: {
  id: string;
  label: string;
  value: string;
  onValue: (v: string) => void;
  error?: string;
  placeholder?: string;
  autocomplete?: string;
  inputmode?: 'text' | 'numeric' | 'email' | 'tel';
}) {
  return (
    <div className="checkout-field">
      <label className="checkout-label" htmlFor={id}>{label}</label>
      <IonInput
        id={id}
        className={error ? 'checkout-input is-invalid' : 'checkout-input'}
        value={value}
        placeholder={placeholder}
        aria-label={label}
        autocomplete={autocomplete as never}
        inputmode={inputmode}
        onIonInput={(e) => onValue(e.detail.value ?? '')}
      />
      {error && (
        <p className="checkout-field-error" role="alert">
          <IonIcon icon={alertCircleOutline} aria-hidden="true" />
          <span>{error}</span>
        </p>
      )}
    </div>
  );
}
