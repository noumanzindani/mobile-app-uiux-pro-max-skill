package ux.examples.checkout

/**
 * CheckoutScreen — a trustworthy, low-friction, all-states checkout for Jetpack Compose
 * (Material 3 Expressive). Implements the checkout example spec:
 *
 *  - an ALWAYS-VISIBLE, itemized order summary (subtotal / shipping / tax / discount / total)
 *    with TABULAR figures and locale currency via NumberFormat.getCurrencyInstance — no surprise
 *    at the end; the total is announced through a live region whenever it changes,
 *  - prominent GUEST checkout (account ask deferred to post-purchase),
 *  - a native GOOGLE PAY shortcut surfaced early, platform-styled (the only brand literal, in
 *    CheckoutTokens); wire the real Google Pay button/SDK in production (see README),
 *  - an address form with the correct KeyboardOptions + autofill (ContentType) semantics,
 *  - payment selection (Google Pay / saved masked card / a NEW paste-safe card with the number
 *    keyboard and credit-card autofill),
 *  - an EDITABLE review (quantity steppers + Edit affordances) right in the summary,
 *  - a STICKY, full-width primary "Pay $X" button that disables + spins the instant it's tapped
 *    and is IDEMPOTENT (a client idempotency key so a retry/double-tap cannot double-charge),
 *    resolving to a definitive Success or a recoverable Error — never a limbo,
 *  - OFFLINE blocks the charge with a clear reason, entries preserved,
 *  - a declined card preserves ALL input; an empty cart offers a Browse CTA (never a dead end);
 *    Success shows an order number + receipt + ETA + next steps.
 *
 * Keyboard-safe (imePadding), edge-to-edge (enableEdgeToEdge + Scaffold safeDrawing), RTL-safe
 * (start/end + RTL-aware Arrangement/Alignment; amounts end-aligned), Dynamic-Type-safe
 * (typography roles, no fixed text heights), targets >= 48dp, motion animates alpha/offset only
 * with a reduce-motion snap() fallback. Every color/spacing/size/radius comes from CheckoutTokens.
 */

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.autofill.ContentType
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.contentType
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import java.text.NumberFormat
import java.util.Currency
import java.util.Locale
import java.util.UUID
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN — money is carried as integer cents; all formatting goes through
// NumberFormat.getCurrencyInstance(locale) so the grouping/symbol/decimals follow the
// user's locale (L10N-005). Never do float math on prices in real code.
// ─────────────────────────────────────────────────────────────────────────────
data class CartLine(
    val id: String,
    val name: String,
    val qty: Int,
    val unitPriceCents: Long,
)

data class Address(
    val fullName: String = "",
    val street: String = "",
    val city: String = "",
    val region: String = "",
    val postalCode: String = "",
    val country: String = "",
)

/** New-card entry. The value is never intercepted, so paste + autofill always work (FRM-014). */
data class CardInput(
    val number: String = "",
    val expiry: String = "",
    val cvv: String = "",
)

enum class PaymentMethod { GooglePay, SavedCard, NewCard }

// ─────────────────────────────────────────────────────────────────────────────
// STATE — a sealed interface makes coverage of all states auditable (STATE-*).
// The words loading / empty / error / offline / success appear here by design.
// Processing is the safety-critical charge state, kept distinct from Loading.
// ─────────────────────────────────────────────────────────────────────────────
sealed interface CheckoutStatus {
    /** Ideal: cart + honest total ready; native Pay available; review editable. */
    data object Ideal : CheckoutStatus

    /** Empty: no items — the empty-cart state offers a Browse CTA, never a dead end. */
    data object Empty : CheckoutStatus

    /** Loading: recomputing totals after an edit; inline progress, inputs preserved. */
    data object Loading : CheckoutStatus

    /** Processing: the charge is in flight — button disabled + spinner, idempotent, no double-charge. */
    data object Processing : CheckoutStatus

    /** Error: declined / server fail — specific, recoverable; ALL entered data preserved. */
    data class Error(val message: String) : CheckoutStatus

    /** Offline: no connectivity — the charge is BLOCKED with a reason; entries preserved. */
    data object Offline : CheckoutStatus

    /** Success: order placed — order number + receipt total + ETA + next steps. */
    data class Success(
        val orderNumber: String,
        val etaText: String,
        val receiptTotal: String,
    ) : CheckoutStatus

    /** Permission-denied: NFC/biometric for native Pay unavailable — fall back to manual card. */
    data object PermissionDenied : CheckoutStatus
}

/** Hoisted, immutable UI state. Input is ALWAYS preserved across status changes (FRM-009). */
data class CheckoutUiState(
    val cart: List<CartLine> = DEMO_CART,
    val isGuest: Boolean = true,
    val address: Address = Address(),
    val paymentMethod: PaymentMethod = PaymentMethod.GooglePay,
    val savedCardLabel: String = "Visa ···· 4242",
    val card: CardInput = CardInput(),
    val status: CheckoutStatus = CheckoutStatus.Ideal,
    val isOffline: Boolean = false,
    val googlePayAvailable: Boolean = true,
    val currencyCode: String = "USD",
    /** Client idempotency key — created once per attempt, REUSED on retry so no double-charge. */
    val idempotencyKey: String? = null,
)

// ── Demo constants (a real screen sources these from cart/pricing services) ──
val DEMO_CART: List<CartLine> = listOf(
    CartLine(id = "sku-headphones", name = "Aurora Wireless Headphones", qty = 1, unitPriceCents = 12900),
    CartLine(id = "sku-cable", name = "Braided USB-C Cable (2 m)", qty = 2, unitPriceCents = 1500),
)
private const val TAX_RATE = 0.0825
private const val SHIPPING_CENTS = 599L
private const val DISCOUNT_CENTS = 1000L

private fun subtotalOf(cart: List<CartLine>): Long = cart.sumOf { it.qty * it.unitPriceCents }
private fun taxOf(subtotalCents: Long): Long = Math.round(subtotalCents * TAX_RATE)

/** Locale + currency aware money formatting — the source of every tabular amount string. */
private fun formatMoney(cents: Long, currencyCode: String, locale: Locale): String {
    val format = NumberFormat.getCurrencyInstance(locale)
    format.currency = Currency.getInstance(currencyCode)
    return format.format(cents / 100.0)
}

// ─────────────────────────────────────────────────────────────────────────────
// STATEFUL ENTRY POINT — owns the state machine, including the idempotent submit.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun CheckoutScreen(
    modifier: Modifier = Modifier,
    onBrowse: () -> Unit = {},
    onOrderPlaced: (orderNumber: String) -> Unit = {},
) {
    var state by remember { mutableStateOf(CheckoutUiState()) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    CheckoutScreenContent(
        state = state,
        modifier = modifier,
        onQtyChange = { id, qty ->
            if (qty >= 1) {
                val newCart = state.cart.map { if (it.id == id) it.copy(qty = qty) else it }
                // Loading: recompute totals with honest inline progress; nothing else is touched.
                state = state.copy(cart = newCart, status = CheckoutStatus.Loading)
                scope.launch {
                    delay(Motion.shortMillis.toLong()) // demo: totals/pricing recompute
                    if (state.status is CheckoutStatus.Loading) {
                        state = state.copy(status = CheckoutStatus.Ideal)
                    }
                }
            }
        },
        onAddressChange = { state = state.copy(address = it) },
        onSelectMethod = { state = state.copy(paymentMethod = it, status = CheckoutStatus.Ideal) },
        onCardChange = { state = state.copy(card = it) },
        onGuestContinue = { state = state.copy(isGuest = true) },
        onSignIn = { /* route to sign-in; guest remains the default, prominent path (AUTH-010) */ },
        onGooglePay = {
            if (!state.googlePayAvailable) {
                // Permission-denied: NFC/biometric unavailable — fall back to manual card, never block.
                state = state.copy(status = CheckoutStatus.PermissionDenied, paymentMethod = PaymentMethod.NewCard)
            } else {
                state = state.copy(paymentMethod = PaymentMethod.GooglePay, status = CheckoutStatus.Ideal)
                submit(state, scope, setState = { state = it }, onOrderPlaced = onOrderPlaced)
            }
        },
        onPay = { submit(state, scope, setState = { state = it }, onOrderPlaced = onOrderPlaced) },
        onBrowse = onBrowse,
        onTrackOrder = {
            val placed = state.status
            if (placed is CheckoutStatus.Success) onOrderPlaced(placed.orderNumber)
        },
        onOpenSettings = {
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", context.packageName, null),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        },
    )
}

/**
 * The single, idempotent submit path. A retry or a double-tap REUSES the same idempotency key,
 * so the backend deduplicates and the customer is charged exactly once (PAY-007). Resolves to a
 * definitive Success or a recoverable Error — never an ambiguous limbo. Input is never cleared.
 */
private fun submit(
    current: CheckoutUiState,
    scope: kotlinx.coroutines.CoroutineScope,
    setState: (CheckoutUiState) -> Unit,
    onOrderPlaced: (String) -> Unit,
) {
    when {
        current.cart.isEmpty() -> setState(current.copy(status = CheckoutStatus.Empty))
        // Offline BLOCKS the charge with a reason; the cart + all entries are preserved.
        current.isOffline -> setState(current.copy(status = CheckoutStatus.Offline))
        // Idempotency guard: while a charge is in flight, ignore further taps (no double-charge).
        current.status is CheckoutStatus.Processing || current.status is CheckoutStatus.Loading -> Unit
        else -> {
            val key = current.idempotencyKey ?: UUID.randomUUID().toString()
            var working = current.copy(status = CheckoutStatus.Processing, idempotencyKey = key)
            setState(working)
            scope.launch {
                delay(Motion.processingMs) // demo: authorize the charge with `key`
                // Demo outcome: a saved/new card ending in 0002 is declined; everything else succeeds.
                val digits = working.card.number.filter { it.isDigit() }
                val declined = working.paymentMethod == PaymentMethod.NewCard && digits.endsWith("0002")
                working = if (declined) {
                    // Error preserves ALL input (card, address) so retry needs no re-entry.
                    working.copy(status = CheckoutStatus.Error("Card declined — try another payment method."))
                } else {
                    val total = subtotalOf(working.cart) + SHIPPING_CENTS +
                        taxOf(subtotalOf(working.cart)) - DISCOUNT_CENTS
                    val receipt = formatMoney(total, working.currencyCode, Locale.getDefault())
                    working.copy(
                        status = CheckoutStatus.Success(
                            orderNumber = "EZ2K-" + key.takeLast(4).uppercase(),
                            etaText = "Arrives Tue–Thu, 3–5 business days",
                            receiptTotal = receipt,
                        ),
                    )
                }
                setState(working)
                val placed = working.status
                if (placed is CheckoutStatus.Success) onOrderPlaced(placed.orderNumber)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATELESS CONTENT — pure, previewable across every state.
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalComposeUiApi::class)
@Composable
private fun CheckoutScreenContent(
    state: CheckoutUiState,
    onQtyChange: (String, Int) -> Unit,
    onAddressChange: (Address) -> Unit,
    onSelectMethod: (PaymentMethod) -> Unit,
    onCardChange: (CardInput) -> Unit,
    onGuestContinue: () -> Unit,
    onSignIn: () -> Unit,
    onGooglePay: () -> Unit,
    onPay: () -> Unit,
    onBrowse: () -> Unit,
    onTrackOrder: () -> Unit,
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val locale = LocalConfiguration.current.locales[0]
    val reduceMotion = rememberReduceMotion()

    val cartIsEmpty = state.cart.isEmpty()
    val subtotal = subtotalOf(state.cart)
    val tax = taxOf(subtotal)
    val total = subtotal + SHIPPING_CENTS + tax - DISCOUNT_CENTS

    val money: (Long) -> String = { formatMoney(it, state.currencyCode, locale) }
    val totalText = money(total)
    val payLabel = "Pay $totalText"

    val isProcessing = state.status is CheckoutStatus.Processing
    val isLoading = state.status is CheckoutStatus.Loading
    val showOffline = state.isOffline || state.status is CheckoutStatus.Offline
    val cardReady = state.paymentMethod != PaymentMethod.NewCard ||
        (state.card.number.isNotBlank() && state.card.expiry.isNotBlank() && state.card.cvv.isNotBlank())
    val canPay = !cartIsEmpty && !showOffline && !isProcessing && !isLoading && cardReady

    Scaffold(
        modifier = modifier,
        // Edge-to-edge: Scaffold applies WindowInsets.safeDrawing so content clears system bars.
        contentWindowInsets = WindowInsets.safeDrawing,
        bottomBar = {
            // The sticky Pay bar is only shown when there's something to pay for.
            if (!cartIsEmpty) {
                StickyPayBar(
                    status = state.status,
                    payLabel = payLabel,
                    canPay = canPay,
                    isProcessing = isProcessing,
                    showOffline = showOffline,
                    onPay = onPay,
                    onTrackOrder = onTrackOrder,
                )
            }
        },
    ) { padding ->
        when {
            cartIsEmpty -> EmptyCart(padding = padding, onBrowse = onBrowse)
            state.status is CheckoutStatus.Success ->
                Confirmation(
                    success = state.status as CheckoutStatus.Success,
                    padding = padding,
                    reduceMotion = reduceMotion,
                )
            else -> LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .imePadding(), // keep focused fields above the keyboard (FRM keyboard-avoidance)
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    start = Space.md, end = Space.md, top = Space.md, bottom = Space.md,
                ),
                verticalArrangement = Arrangement.spacedBy(Space.md),
            ) {
                item { Header() }

                // Offline / error status — announced; the charge is blocked, entries preserved.
                item {
                    StatusBanner(
                        status = state.status,
                        showOffline = showOffline,
                        reduceMotion = reduceMotion,
                    )
                }

                item { GuestIdentityCard(onGuestContinue = onGuestContinue, onSignIn = onSignIn) }

                item { ExpressPay(onGooglePay = onGooglePay) }

                item {
                    OrderSummaryCard(
                        cart = state.cart,
                        money = money,
                        subtotal = subtotal,
                        shipping = SHIPPING_CENTS,
                        tax = tax,
                        discount = DISCOUNT_CENTS,
                        totalText = totalText,
                        isLoading = isLoading,
                        onQtyChange = onQtyChange,
                    )
                }

                item {
                    AddressSection(address = state.address, onAddressChange = onAddressChange)
                }

                item {
                    PaymentSection(
                        method = state.paymentMethod,
                        savedCardLabel = state.savedCardLabel,
                        card = state.card,
                        permissionDenied = state.status is CheckoutStatus.PermissionDenied,
                        onSelectMethod = onSelectMethod,
                        onCardChange = onCardChange,
                        onOpenSettings = onOpenSettings,
                    )
                }

                item { TrustFooter() }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — title + honest "secure" trust cue (icon + TEXT, never color alone).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun Header() {
    Column {
        Text(
            text = "Checkout",
            style = CheckoutType.title,
            color = MaterialTheme.checkoutColors.onSurfaceStrong,
        )
        Spacer(Modifier.height(Space.xs))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = Icons.Filled.Lock,
                contentDescription = null,
                tint = MaterialTheme.checkoutColors.statusSuccess,
                modifier = Modifier.size(Size.trustIcon),
            )
            Spacer(Modifier.width(Space.xxs))
            Text(
                text = "Secure checkout — encrypted, no hidden fees",
                style = CheckoutType.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status banner — offline (polite) or error (assertive), icon + text, live region.
// Only opacity animates; reduce-motion collapses the fade to an instant change (MOT-004).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun StatusBanner(status: CheckoutStatus, showOffline: Boolean, reduceMotion: Boolean) {
    val error = status as? CheckoutStatus.Error
    val visible = showOffline || error != null
    val fade by animateFloatAsState(
        targetValue = if (visible) 1f else 0f,
        animationSpec = if (reduceMotion) snap() else tween(durationMillis = Motion.shortMillis),
        label = "statusFade",
    )
    if (!visible) return

    val container = if (error != null) {
        MaterialTheme.colorScheme.errorContainer
    } else {
        MaterialTheme.colorScheme.secondaryContainer
    }
    val onContainer = if (error != null) {
        MaterialTheme.colorScheme.onErrorContainer
    } else {
        MaterialTheme.colorScheme.onSecondaryContainer
    }
    val message = error?.message
        ?: "You're offline — we won't charge you until you're back online. Your cart is saved."

    Surface(
        color = container,
        shape = MaterialTheme.shapes.medium,
        modifier = Modifier
            .fillMaxWidth()
            .alpha(fade)
            .semantics {
                // Errors interrupt; the offline notice is polite. Result is announced either way.
                liveRegion = if (error != null) LiveRegionMode.Assertive else LiveRegionMode.Polite
                contentDescription = message
            },
    ) {
        Row(
            modifier = Modifier.padding(Space.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = if (error != null) Icons.Filled.Warning else Icons.Filled.Info,
                contentDescription = null,
                tint = onContainer,
                modifier = Modifier.size(Size.icon),
            )
            Spacer(Modifier.width(Space.sm))
            Text(text = message, style = CheckoutType.body, color = onContainer)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guest identity — GUEST is the prominent default; sign-in is a subordinate link
// so we never wall the purchase behind an account (AUTH-010, PAY-003).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun GuestIdentityCard(onGuestContinue: () -> Unit, onSignIn: () -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(Space.md)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.Person,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(Size.icon),
                )
                Spacer(Modifier.width(Space.sm))
                Text(
                    text = "Checking out as guest",
                    style = CheckoutType.sectionTitle,
                    color = MaterialTheme.colorScheme.onSurface,
                )
            }
            Spacer(Modifier.height(Space.xs))
            Text(
                text = "No account needed — you can save your details after you pay.",
                style = CheckoutType.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(Space.sm))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Space.sm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Button(
                    onClick = onGuestContinue,
                    modifier = Modifier
                        .weight(1f)
                        .heightIn(min = Size.minTarget),
                ) {
                    Text("Continue as guest")
                }
                TextButton(
                    onClick = onSignIn,
                    modifier = Modifier.heightIn(min = Size.minTarget),
                ) {
                    Text("Sign in", style = CheckoutType.label)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Express pay — the native GOOGLE PAY shortcut, surfaced early, platform-styled.
// In production replace this with the official Google Pay button (see README); the
// only brand literal lives in CheckoutTokens (checkoutColors.googlePayContainer).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun ExpressPay(onGooglePay: () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Surface(
            onClick = onGooglePay,
            shape = PillShape,
            color = MaterialTheme.checkoutColors.googlePayContainer,
            contentColor = MaterialTheme.checkoutColors.onGooglePay,
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = Size.minTarget)
                .semantics {
                    role = Role.Button
                    contentDescription = "Pay with Google Pay"
                },
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Space.md, vertical = Space.sm),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    imageVector = Icons.Filled.CreditCard,
                    contentDescription = null,
                    modifier = Modifier.size(Size.payLogo),
                )
                Spacer(Modifier.width(Space.sm))
                Text(text = "Pay with Google Pay", style = CheckoutType.action)
            }
        }
        Spacer(Modifier.height(Space.sm))
        OrDivider()
    }
}

@Composable
private fun OrDivider() {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        HorizontalDivider(modifier = Modifier.weight(1f))
        Text(
            text = "or pay another way",
            style = CheckoutType.meta,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = Space.md),
        )
        HorizontalDivider(modifier = Modifier.weight(1f))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order summary — ALWAYS VISIBLE, itemized, editable (quantity steppers), honest.
// Amounts use tabular figures and are END-aligned so they mirror in RTL; the TOTAL is
// announced via a polite live region whenever it changes (PAY-006, TYP-006, A11Y-019).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun OrderSummaryCard(
    cart: List<CartLine>,
    money: (Long) -> String,
    subtotal: Long,
    shipping: Long,
    tax: Long,
    discount: Long,
    totalText: String,
    isLoading: Boolean,
    onQtyChange: (String, Int) -> Unit,
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(Space.md)) {
            Text(
                text = "Review your order",
                style = CheckoutType.sectionTitle,
                color = MaterialTheme.colorScheme.onSurface,
            )
            Spacer(Modifier.height(Space.sm))

            cart.forEach { line ->
                CartLineRow(line = line, money = money, onQtyChange = onQtyChange)
                Spacer(Modifier.height(Space.sm))
            }

            HorizontalDivider()
            Spacer(Modifier.height(Space.sm))

            SummaryRow(label = "Subtotal", value = money(subtotal))
            SummaryRow(label = "Shipping", value = money(shipping))
            SummaryRow(label = "Tax", value = money(tax))
            SummaryRow(label = "Discount", value = "-" + money(discount), emphasizeValue = true)

            Spacer(Modifier.height(Space.sm))
            HorizontalDivider()
            Spacer(Modifier.height(Space.sm))

            // TOTAL — highest emphasis; live region re-announces "Order total X" on change.
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .semantics {
                        liveRegion = LiveRegionMode.Polite
                        contentDescription = "Order total $totalText"
                    },
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "Total",
                        style = CheckoutType.action,
                        color = MaterialTheme.checkoutColors.onSurfaceStrong,
                    )
                    if (isLoading) {
                        Spacer(Modifier.width(Space.sm))
                        // Honest inline progress while totals recompute — no fake progress bar.
                        CircularProgressIndicator(
                            modifier = Modifier.size(Size.spinner),
                            strokeWidth = Size.spinnerStroke,
                        )
                    }
                }
                Text(
                    text = totalText,
                    style = CheckoutType.total,
                    color = MaterialTheme.checkoutColors.onSurfaceStrong,
                    textAlign = TextAlign.End,
                )
            }
        }
    }
}

@Composable
private fun CartLineRow(line: CartLine, money: (Long) -> String, onQtyChange: (String, Int) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = line.name,
            style = CheckoutType.body,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f),
        )
        Spacer(Modifier.width(Space.sm))
        // Quantity stepper — each IconButton is a 48dp target by default (A11Y-003).
        IconButton(
            onClick = { onQtyChange(line.id, line.qty - 1) },
            enabled = line.qty > 1,
        ) {
            Icon(imageVector = Icons.Filled.Remove, contentDescription = "Decrease quantity")
        }
        Text(
            text = line.qty.toString(),
            style = CheckoutType.amount,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
        )
        IconButton(onClick = { onQtyChange(line.id, line.qty + 1) }) {
            Icon(imageVector = Icons.Filled.Add, contentDescription = "Increase quantity")
        }
        Spacer(Modifier.width(Space.sm))
        Text(
            text = money(line.unitPriceCents * line.qty),
            style = CheckoutType.amount,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.End,
        )
    }
}

@Composable
private fun SummaryRow(label: String, value: String, emphasizeValue: Boolean = false) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = Space.xxs)
            .semantics { contentDescription = "$label $value" },
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = label, style = CheckoutType.body, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(
            text = value,
            style = CheckoutType.amount,
            color = if (emphasizeValue) {
                MaterialTheme.checkoutColors.statusSuccess
            } else {
                MaterialTheme.colorScheme.onSurface
            },
            textAlign = TextAlign.End,
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Address — every field labeled, with the correct keyboard + autofill ContentType so
// paste, OS autofill, and password/address managers all work (A11Y-015, FRM-002, PAY-009).
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalComposeUiApi::class)
@Composable
private fun AddressSection(address: Address, onAddressChange: (Address) -> Unit) {
    Column(modifier = Modifier.fillMaxWidth()) {
        SectionHeader(title = "Shipping address")
        Spacer(Modifier.height(Space.sm))

        AutofillField(
            value = address.fullName,
            onValueChange = { onAddressChange(address.copy(fullName = it)) },
            label = "Full name",
            contentTypeHint = ContentType.PersonFullName,
            keyboardType = KeyboardType.Text,
            capitalization = KeyboardCapitalization.Words,
        )
        Spacer(Modifier.height(Space.sm))
        AutofillField(
            value = address.street,
            onValueChange = { onAddressChange(address.copy(street = it)) },
            label = "Street address",
            contentTypeHint = ContentType.AddressStreet,
            keyboardType = KeyboardType.Text,
            capitalization = KeyboardCapitalization.Words,
        )
        Spacer(Modifier.height(Space.sm))
        AutofillField(
            value = address.city,
            onValueChange = { onAddressChange(address.copy(city = it)) },
            label = "City",
            contentTypeHint = ContentType.AddressLocality,
            keyboardType = KeyboardType.Text,
            capitalization = KeyboardCapitalization.Words,
        )
        Spacer(Modifier.height(Space.sm))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Space.sm),
        ) {
            AutofillField(
                value = address.region,
                onValueChange = { onAddressChange(address.copy(region = it)) },
                label = "State / Region",
                contentTypeHint = ContentType.AddressRegion,
                keyboardType = KeyboardType.Text,
                capitalization = KeyboardCapitalization.Words,
                modifier = Modifier.weight(1f),
            )
            AutofillField(
                value = address.postalCode,
                onValueChange = { onAddressChange(address.copy(postalCode = it)) },
                label = "ZIP / Postal",
                contentTypeHint = ContentType.PostalCode,
                keyboardType = KeyboardType.Number, // numeric pad for postal codes (A11Y-004)
                capitalization = KeyboardCapitalization.None,
                imeAction = ImeAction.Done,
                modifier = Modifier.weight(1f),
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment — Google Pay / saved masked card / a NEW paste-safe card. The saved card is
// display-masked ("···· 4242"); the new-card fields never intercept input, so paste +
// credit-card autofill always work with the number keyboard (FRM-014, A11Y-015).
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalComposeUiApi::class)
@Composable
private fun PaymentSection(
    method: PaymentMethod,
    savedCardLabel: String,
    card: CardInput,
    permissionDenied: Boolean,
    onSelectMethod: (PaymentMethod) -> Unit,
    onCardChange: (CardInput) -> Unit,
    onOpenSettings: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        SectionHeader(title = "Payment")
        Spacer(Modifier.height(Space.sm))

        if (permissionDenied) {
            PermissionDeniedNotice(onOpenSettings = onOpenSettings)
            Spacer(Modifier.height(Space.sm))
        }

        PaymentOptionRow(
            selected = method == PaymentMethod.GooglePay,
            label = "Google Pay",
            onSelect = { onSelectMethod(PaymentMethod.GooglePay) },
        )
        PaymentOptionRow(
            selected = method == PaymentMethod.SavedCard,
            label = savedCardLabel,
            onSelect = { onSelectMethod(PaymentMethod.SavedCard) },
        )
        PaymentOptionRow(
            selected = method == PaymentMethod.NewCard,
            label = "New card",
            onSelect = { onSelectMethod(PaymentMethod.NewCard) },
        )

        if (method == PaymentMethod.NewCard) {
            Spacer(Modifier.height(Space.sm))
            AutofillField(
                value = card.number,
                onValueChange = { onCardChange(card.copy(number = it)) },
                label = "Card number",
                contentTypeHint = ContentType.CreditCardNumber,
                keyboardType = KeyboardType.Number, // number pad; value is never intercepted (paste-safe)
                capitalization = KeyboardCapitalization.None,
            )
            Spacer(Modifier.height(Space.sm))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Space.sm),
            ) {
                AutofillField(
                    value = card.expiry,
                    onValueChange = { onCardChange(card.copy(expiry = it)) },
                    label = "MM / YY",
                    contentTypeHint = ContentType.CreditCardExpirationDate,
                    keyboardType = KeyboardType.Number,
                    capitalization = KeyboardCapitalization.None,
                    modifier = Modifier.weight(1f),
                )
                AutofillField(
                    value = card.cvv,
                    onValueChange = { onCardChange(card.copy(cvv = it)) },
                    label = "CVV",
                    contentTypeHint = ContentType.CreditCardSecurityCode,
                    keyboardType = KeyboardType.Number,
                    capitalization = KeyboardCapitalization.None,
                    imeAction = ImeAction.Done,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

@Composable
private fun PaymentOptionRow(selected: Boolean, label: String, onSelect: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.minTarget)
            .selectable(selected = selected, role = Role.RadioButton, onClick = onSelect)
            .padding(vertical = Space.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        RadioButton(selected = selected, onClick = null)
        Spacer(Modifier.width(Space.sm))
        Text(
            text = label,
            style = CheckoutType.body,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f),
        )
    }
}

// One shared field: correct keyboard + autofill semantics, single-line, no fixed height.
@OptIn(ExperimentalComposeUiApi::class)
@Composable
private fun AutofillField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    contentTypeHint: ContentType,
    keyboardType: KeyboardType,
    capitalization: KeyboardCapitalization,
    imeAction: ImeAction = ImeAction.Next,
    modifier: Modifier = Modifier,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        label = { Text(label) },
        keyboardOptions = KeyboardOptions(
            keyboardType = keyboardType,
            imeAction = imeAction,
            capitalization = capitalization,
        ),
        modifier = modifier
            .fillMaxWidth()
            // Autofill hint → OS/manager suggestions + paste (WCAG 3.3.8, A11Y-015, FRM-014).
            .semantics { contentType = contentTypeHint },
    )
}

@Composable
private fun SectionHeader(title: String, onEdit: (() -> Unit)? = null) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = title, style = CheckoutType.sectionTitle, color = MaterialTheme.colorScheme.onSurface)
        if (onEdit != null) {
            TextButton(onClick = onEdit, modifier = Modifier.heightIn(min = Size.minTarget)) {
                Text("Edit", style = CheckoutType.label)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission-denied — native Pay unavailable; explain + fall back to a card. Never a dead end.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun PermissionDeniedNotice(onOpenSettings: () -> Unit) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = MaterialTheme.shapes.medium,
        modifier = Modifier
            .fillMaxWidth()
            .semantics { liveRegion = LiveRegionMode.Polite },
    ) {
        Column(modifier = Modifier.padding(Space.md)) {
            Text(
                text = "Google Pay isn't available on this device",
                style = CheckoutType.sectionTitle,
                color = MaterialTheme.colorScheme.onSurface,
            )
            Spacer(Modifier.height(Space.xs))
            Text(
                text = "NFC or device unlock is off, so we've switched you to card entry. " +
                    "You can still complete your order below, or enable it in Settings.",
                style = CheckoutType.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(Space.sm))
            OutlinedButton(
                onClick = onOpenSettings,
                modifier = Modifier.heightIn(min = Size.minTarget),
            ) {
                Text("Open Settings")
            }
        }
    }
}

@Composable
private fun TrustFooter() {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(
            imageVector = Icons.Filled.Lock,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(Size.trustIcon),
        )
        Spacer(Modifier.width(Space.xxs))
        Text(
            text = "Your card is encrypted. You won't be charged more than the total shown.",
            style = CheckoutType.meta,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky Pay bar — the ONE primary action, full-width, in the bottom thumb arc. Shows the
// amount; on tap it disables + spins (idempotent, no double-charge); rides above the keyboard
// via imePadding. Swaps to "Track order" once the order is placed (BTN-007, BTN-008, PAY-007).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun StickyPayBar(
    status: CheckoutStatus,
    payLabel: String,
    canPay: Boolean,
    isProcessing: Boolean,
    showOffline: Boolean,
    onPay: () -> Unit,
    onTrackOrder: () -> Unit,
) {
    val success = status as? CheckoutStatus.Success
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainerHigh,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .imePadding() // sticky button rides above the keyboard (FRM keyboard-avoidance)
                .padding(Space.md),
        ) {
            if (success != null) {
                Button(
                    onClick = onTrackOrder,
                    shape = PillShape,
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = Size.minTarget),
                ) {
                    Icon(imageVector = Icons.Filled.Receipt, contentDescription = null, modifier = Modifier.size(Size.icon))
                    Spacer(Modifier.width(Space.sm))
                    Text("Track order")
                }
            } else {
                val payDescription = when {
                    isProcessing -> "Processing payment, please wait"
                    showOffline -> "$payLabel, unavailable while offline"
                    else -> payLabel
                }
                Button(
                    onClick = onPay,
                    enabled = canPay,
                    shape = PillShape,
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = Size.minTarget)
                        .semantics {
                            role = Role.Button
                            contentDescription = payDescription
                            if (isProcessing) {
                                stateDescription = "Processing payment"
                                liveRegion = LiveRegionMode.Assertive
                            }
                        },
                ) {
                    if (isProcessing) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(Size.spinner),
                            strokeWidth = Size.spinnerStroke,
                            color = MaterialTheme.colorScheme.onPrimary,
                        )
                        Spacer(Modifier.width(Space.sm))
                        Text("Processing…")
                    } else {
                        Text(payLabel)
                    }
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty cart — a Browse CTA, never a dead end (STATE-002).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun EmptyCart(padding: androidx.compose.foundation.layout.PaddingValues, onBrowse: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
            .padding(Space.xl),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                imageVector = Icons.Filled.ShoppingBag,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(Size.icon),
            )
            Spacer(Modifier.height(Space.md))
            Text(
                text = "Your cart is empty",
                style = CheckoutType.title,
                color = MaterialTheme.colorScheme.onSurface,
            )
            Spacer(Modifier.height(Space.xs))
            Text(
                text = "Add something you love and it'll show up here.",
                style = CheckoutType.body,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(Space.lg))
            Button(
                onClick = onBrowse,
                shape = PillShape,
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = Size.minTarget),
            ) {
                Text("Browse products")
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirmation — order number + receipt total + ETA + next steps. Offers "save details".
// A brief offset+alpha reveal (reduce-motion → snap); the receipt is never gated behind it.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun Confirmation(
    success: CheckoutStatus.Success,
    padding: androidx.compose.foundation.layout.PaddingValues,
    reduceMotion: Boolean,
) {
    var appeared by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { appeared = true }
    val offsetY by animateDpAsState(
        targetValue = if (appeared) Space.zero else Space.md,
        animationSpec = if (reduceMotion) snap() else tween(durationMillis = Motion.insertMillis),
        label = "confirmReveal",
    )
    val fade by animateFloatAsState(
        targetValue = if (appeared) 1f else 0f,
        animationSpec = if (reduceMotion) snap() else tween(durationMillis = Motion.insertMillis),
        label = "confirmFade",
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
            .padding(Space.md)
            .offset(y = offsetY)
            .alpha(fade)
            // The whole confirmation is announced as one polite region (success result).
            .semantics { liveRegion = LiveRegionMode.Polite },
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            imageVector = Icons.Filled.CheckCircle,
            contentDescription = null,
            tint = MaterialTheme.checkoutColors.statusSuccess,
            modifier = Modifier.size(Size.icon),
        )
        Spacer(Modifier.height(Space.sm))
        Text(
            text = "Order placed — you're all set",
            style = CheckoutType.title,
            color = MaterialTheme.checkoutColors.onSurfaceStrong,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(Space.md))

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(Space.md)) {
                ConfirmationRow(label = "Order number", value = success.orderNumber)
                Spacer(Modifier.height(Space.sm))
                ConfirmationRow(label = "Total charged", value = success.receiptTotal, strong = true)
                Spacer(Modifier.height(Space.sm))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = success.etaText,
                        style = CheckoutType.body,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }

        Spacer(Modifier.height(Space.md))
        // Post-purchase account ask (deferred, optional) — the honest place to offer it (PAY-008).
        OutlinedButton(
            onClick = { /* create account / save details from this order */ },
            shape = PillShape,
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = Size.minTarget),
        ) {
            Text("Save these details for next time")
        }
    }
}

@Composable
private fun ConfirmationRow(label: String, value: String, strong: Boolean = false) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .semantics { contentDescription = "$label $value" },
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = label, style = CheckoutType.body, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(
            text = value,
            style = if (strong) CheckoutType.total else CheckoutType.amount,
            color = MaterialTheme.checkoutColors.onSurfaceStrong,
            textAlign = TextAlign.End,
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Host Activity — edge-to-edge is enabled here; the composable inherits the insets.
// ─────────────────────────────────────────────────────────────────────────────
class CheckoutActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            CheckoutTheme {
                CheckoutScreen(
                    onBrowse = { /* navigate to catalog */ },
                    onOrderPlaced = { /* navigate to order tracking / deep link */ },
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Previews — one per state so the whole matrix is inspectable at a glance.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun PreviewHost(state: CheckoutUiState) = CheckoutTheme {
    CheckoutScreenContent(
        state = state,
        onQtyChange = { _, _ -> }, onAddressChange = {}, onSelectMethod = {}, onCardChange = {},
        onGuestContinue = {}, onSignIn = {}, onGooglePay = {}, onPay = {}, onBrowse = {},
        onTrackOrder = {}, onOpenSettings = {},
    )
}

@Preview(name = "Checkout — ideal (ready to pay)", showBackground = true)
@Composable
private fun CheckoutIdealPreview() = PreviewHost(CheckoutUiState())

@Preview(name = "Checkout — empty cart", showBackground = true)
@Composable
private fun CheckoutEmptyPreview() =
    PreviewHost(CheckoutUiState(cart = emptyList(), status = CheckoutStatus.Empty))

@Preview(name = "Checkout — loading (recomputing totals)", showBackground = true)
@Composable
private fun CheckoutLoadingPreview() =
    PreviewHost(CheckoutUiState(status = CheckoutStatus.Loading))

@Preview(name = "Checkout — processing (charging)", showBackground = true)
@Composable
private fun CheckoutProcessingPreview() =
    PreviewHost(CheckoutUiState(status = CheckoutStatus.Processing, idempotencyKey = "demo-key"))

@Preview(name = "Checkout — error (declined)", showBackground = true)
@Composable
private fun CheckoutErrorPreview() =
    PreviewHost(
        CheckoutUiState(
            paymentMethod = PaymentMethod.NewCard,
            card = CardInput(number = "4000000000000002", expiry = "12/28", cvv = "123"),
            status = CheckoutStatus.Error("Card declined — try another payment method."),
        ),
    )

@Preview(name = "Checkout — offline (charge blocked)", showBackground = true)
@Composable
private fun CheckoutOfflinePreview() =
    PreviewHost(CheckoutUiState(isOffline = true, status = CheckoutStatus.Offline))

@Preview(name = "Checkout — success (order placed)", showBackground = true)
@Composable
private fun CheckoutSuccessPreview() =
    PreviewHost(
        CheckoutUiState(
            status = CheckoutStatus.Success(
                orderNumber = "EZ2K-9F3C",
                etaText = "Arrives Tue–Thu, 3–5 business days",
                receiptTotal = "$149.80",
            ),
        ),
    )

@Preview(name = "Checkout — permission denied (native Pay)", showBackground = true)
@Composable
private fun CheckoutPermissionDeniedPreview() =
    PreviewHost(
        CheckoutUiState(paymentMethod = PaymentMethod.NewCard, status = CheckoutStatus.PermissionDenied),
    )
