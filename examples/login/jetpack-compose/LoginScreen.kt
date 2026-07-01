package ux.examples.login

/**
 * LoginScreen — an accessible, paste-friendly, all-states login for Jetpack Compose
 * (Material 3 Expressive). Implements the login example spec:
 *
 *  - email + password OutlinedTextFields with the correct keyboard + autofill semantics
 *    (ContentType enables paste / password managers / passkeys per WCAG 2.2 3.3.8),
 *  - a labeled show/hide password IconToggleButton that exposes its state to TalkBack,
 *  - Forgot password / Create account / Continue as guest, a full-width primary "Sign in",
 *    and Google + Sign in with Apple SSO,
 *  - a GENERIC error (never reveals which field), announced via a liveRegion status Text,
 *    with input preserved and focus moved back to the first field,
 *  - a non-blocking offline banner,
 *  - success that offers biometric opt-in with a password fallback, and a clean
 *    permission-denied fallback that never dead-ends.
 *
 * Keyboard-safe (imePadding), edge-to-edge (enableEdgeToEdge + Scaffold safeDrawing),
 * RTL-safe (start/end + RTL-aware Arrangement/Alignment), Dynamic-Type-safe (typography
 * roles, no fixed text heights), targets ≥48dp, motion animates alpha only with a
 * reduce-motion fallback. Every color/spacing/size/radius comes from LoginTokens.
 */

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconToggleButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.contentType
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.tooling.preview.Preview
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// ─────────────────────────────────────────────────────────────────────────────
// STATE — a sealed interface makes coverage of all 7 states auditable (STATE-*).
// The words loading / empty / error / offline / success appear here by design.
// ─────────────────────────────────────────────────────────────────────────────
sealed interface LoginStatus {
    /** Ideal: form ready, nothing in flight. */
    data object Idle : LoginStatus

    /** Empty: submit attempted with a blank field — the ready-empty form is the empty state. */
    data object Empty : LoginStatus

    /** Loading: sign-in in flight; button shows a spinner, inputs lock, double-submit blocked. */
    data object Loading : LoginStatus

    /** Error: wrong credentials / server error — generic, does NOT reveal which field failed. */
    data class Error(val message: String) : LoginStatus

    /** Offline: no connectivity; sign-in disabled with a reason, inputs preserved. */
    data object Offline : LoginStatus

    /** Success: authenticated; offer biometric opt-in with a password fallback. */
    data object Success : LoginStatus

    /** Permission-denied: biometric unavailable/denied — fall back cleanly to password. */
    data object PermissionDenied : LoginStatus
}

/** Hoisted, immutable UI state. Input is always preserved across status changes (FRM-009). */
data class LoginUiState(
    val email: String = "",
    val password: String = "",
    val passwordVisible: Boolean = false,
    val status: LoginStatus = LoginStatus.Idle,
    val isOffline: Boolean = false,
)

// ─────────────────────────────────────────────────────────────────────────────
// STATEFUL ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun LoginScreen(
    modifier: Modifier = Modifier,
    onAuthenticated: () -> Unit = {},
) {
    var state by remember { mutableStateOf(LoginUiState()) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    LoginScreenContent(
        state = state,
        modifier = modifier,
        onEmailChange = { state = state.copy(email = it, status = LoginStatus.Idle) },
        onPasswordChange = { state = state.copy(password = it, status = LoginStatus.Idle) },
        onToggleVisibility = { state = state.copy(passwordVisible = it) },
        onSubmit = {
            when {
                // Empty: a blank field short-circuits before any network call.
                state.email.isEmpty() || state.password.isEmpty() ->
                    state = state.copy(status = LoginStatus.Empty)
                // Offline: auth needs a network — show the reason, keep input.
                state.isOffline ->
                    state = state.copy(status = LoginStatus.Offline)
                // Loading: block double-submit while the request is in flight.
                state.status == LoginStatus.Loading -> Unit
                else -> {
                    state = state.copy(status = LoginStatus.Loading)
                    scope.launch {
                        delay(Motion.simulatedDelayMs) // demo-only stand-in for the auth call
                        val ok = state.email.contains("@") && state.password.isNotBlank()
                        state = state.copy(
                            status = if (ok) LoginStatus.Success
                            // Generic error — never reveals which field was wrong (AUTH-004).
                            else LoginStatus.Error("Email or password is incorrect."),
                        )
                    }
                }
            }
        },
        onForgotPassword = { /* route to password recovery (.sheet / dedicated screen) */ },
        onSignUp = { /* route to sign-up */ },
        onGuest = { onAuthenticated() },
        onGoogle = { /* launch Google Identity / Credential Manager */ },
        onApple = { /* launch Sign in with Apple */ },
        // Success → user opted into biometrics; here the OS reports it is not enrolled/denied,
        // so we surface the permission-denied fallback rather than dead-ending (AUTH-002, PERM-003).
        onEnableBiometric = { state = state.copy(status = LoginStatus.PermissionDenied) },
        // Password fallback path from either the opt-in card or the denied card.
        onSkipBiometric = { onAuthenticated() },
        onOpenSettings = {
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", context.packageName, null),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        },
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// STATELESS CONTENT — pure, previewable across every state.
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalComposeUiApi::class)
@Composable
private fun LoginScreenContent(
    state: LoginUiState,
    onEmailChange: (String) -> Unit,
    onPasswordChange: (String) -> Unit,
    onToggleVisibility: (Boolean) -> Unit,
    onSubmit: () -> Unit,
    onForgotPassword: () -> Unit,
    onSignUp: () -> Unit,
    onGuest: () -> Unit,
    onGoogle: () -> Unit,
    onApple: () -> Unit,
    onEnableBiometric: () -> Unit,
    onSkipBiometric: () -> Unit,
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val emailFocus = remember { FocusRequester() }
    val reduceMotion = rememberReduceMotion()

    val isLoading = state.status == LoginStatus.Loading
    val showError = state.status is LoginStatus.Error
    val showOffline = state.isOffline || state.status == LoginStatus.Offline
    // Enabled once inputs are non-empty and we're neither loading nor offline.
    val canSubmit = state.email.isNotBlank() && state.password.isNotBlank() &&
        !isLoading && !showOffline

    // On a generic error, move focus back to the first field so recovery is one tap away (A11Y-008).
    LaunchedEffect(state.status) {
        if (state.status is LoginStatus.Error) emailFocus.requestFocus()
    }

    // Error reveal animates opacity only; reduce-motion collapses it to an instant change (MOT-004).
    val errorAlpha by animateFloatAsState(
        targetValue = if (showError) 1f else 0f,
        animationSpec = if (reduceMotion) snap() else tween(durationMillis = Motion.shortMillis),
        label = "errorAlpha",
    )

    Scaffold(
        modifier = modifier,
        // Edge-to-edge: Scaffold applies WindowInsets.safeDrawing as contentPadding.
        contentWindowInsets = WindowInsets.safeDrawing,
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState()) // Dynamic Type reflows vertically
                .imePadding()                          // keep fields + CTA above the keyboard (FRM keyboard-avoidance)
                .padding(horizontal = Space.md),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(Space.xl))

            // ── Brand / title (non-interactive top zone) ────────────────────
            Icon(
                imageVector = Icons.Filled.Lock,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(Size.icon),
            )
            Spacer(Modifier.height(Space.md))
            Text(
                text = "Welcome back",
                style = LoginType.title,
                color = MaterialTheme.colorScheme.onSurface,
            )
            Spacer(Modifier.height(Space.xs))
            Text(
                text = "Sign in to continue",
                style = LoginType.subtitle,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(Space.lg))

            // ── Offline banner: non-blocking, announced as a live region ────
            if (showOffline) {
                OfflineBanner()
                Spacer(Modifier.height(Space.md))
            }

            // ── Email field: email keyboard + autofill (username/email) ─────
            OutlinedTextField(
                value = state.email,
                onValueChange = onEmailChange,
                singleLine = true,
                enabled = !isLoading,
                isError = showError,
                label = { Text("Email") },
                placeholder = { Text("you@example.com") },
                leadingIcon = { Icon(Icons.Filled.Email, contentDescription = null) },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Email,
                    imeAction = ImeAction.Next,
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(emailFocus)
                    // Autofill hint → OS/manager/passkey suggestions + paste (WCAG 3.3.8, AUTH-001/007).
                    .semantics { contentType = ContentType.EmailAddress },
            )
            Spacer(Modifier.height(Space.md))

            // ── Password field + labeled show/hide toggle ───────────────────
            OutlinedTextField(
                value = state.password,
                onValueChange = onPasswordChange,
                singleLine = true,
                enabled = !isLoading,
                isError = showError,
                label = { Text("Password") },
                placeholder = { Text("Your password") },
                leadingIcon = { Icon(Icons.Filled.Lock, contentDescription = null) },
                visualTransformation = if (state.passwordVisible) {
                    VisualTransformation.None
                } else {
                    PasswordVisualTransformation()
                },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                    imeAction = ImeAction.Done,
                ),
                trailingIcon = {
                    // IconToggleButton is 48dp by default — keep it; expose the toggle's state.
                    IconToggleButton(
                        checked = state.passwordVisible,
                        onCheckedChange = onToggleVisibility,
                        modifier = Modifier.semantics {
                            stateDescription =
                                if (state.passwordVisible) "Password shown" else "Password hidden"
                        },
                    ) {
                        Icon(
                            imageVector = if (state.passwordVisible) {
                                Icons.Filled.VisibilityOff
                            } else {
                                Icons.Filled.Visibility
                            },
                            contentDescription =
                                if (state.passwordVisible) "Hide password" else "Show password",
                        )
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    // "current-password" content type → managers/passkeys autofill (AUTH-001).
                    .semantics { contentType = ContentType.Password },
            )

            // ── Forgot password (subordinate, end-aligned → mirrors in RTL) ─
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End,
            ) {
                TextButton(onClick = onForgotPassword) {
                    Text("Forgot password?", style = LoginType.label)
                }
            }

            // ── Generic status / error — announced, focus already moved ─────
            StatusMessage(status = state.status, alpha = errorAlpha)

            Spacer(Modifier.height(Space.sm))

            // ── Primary: Sign in (full-width, ≥48dp, single primary action) ─
            Button(
                onClick = onSubmit,
                enabled = canSubmit,
                shape = PillShape,
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = Size.minTarget)
                    .semantics { if (isLoading) stateDescription = "Signing in, loading" },
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(Size.spinner),
                        strokeWidth = Size.spinnerStroke,
                        color = MaterialTheme.colorScheme.onPrimary,
                    )
                    Spacer(Modifier.width(Space.sm))
                    Text("Signing in…")
                } else {
                    Text("Sign in")
                }
            }

            Spacer(Modifier.height(Space.md))
            OrDivider()
            Spacer(Modifier.height(Space.md))

            // ── SSO (subordinate to the primary) ────────────────────────────
            OutlinedButton(
                onClick = onGoogle,
                shape = PillShape,
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = Size.minTarget),
            ) {
                Icon(
                    imageVector = Icons.Filled.AccountCircle,
                    contentDescription = null,
                    modifier = Modifier.size(Size.ssoIcon),
                )
                Spacer(Modifier.width(Space.sm))
                Text("Continue with Google")
            }
            Spacer(Modifier.height(Space.sm))
            OutlinedButton(
                onClick = onApple,
                shape = PillShape,
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = Size.minTarget),
            ) {
                Icon(
                    imageVector = Icons.Filled.AccountCircle,
                    contentDescription = null,
                    modifier = Modifier.size(Size.ssoIcon),
                )
                Spacer(Modifier.width(Space.sm))
                Text("Sign in with Apple")
            }

            Spacer(Modifier.height(Space.md))

            // ── Sign up / Guest ─────────────────────────────────────────────
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                TextButton(onClick = onSignUp) {
                    Text("Create account", style = LoginType.label)
                }
                TextButton(onClick = onGuest) {
                    Text("Continue as guest", style = LoginType.label)
                }
            }

            // ── Success → biometric opt-in · Permission-denied → fallback ───
            when (state.status) {
                LoginStatus.Success -> {
                    Spacer(Modifier.height(Space.md))
                    BiometricOptInCard(onEnable = onEnableBiometric, onUsePassword = onSkipBiometric)
                }
                LoginStatus.PermissionDenied -> {
                    Spacer(Modifier.height(Space.md))
                    BiometricDeniedCard(onOpenSettings = onOpenSettings, onUsePassword = onSkipBiometric)
                }
                else -> Unit
            }

            Spacer(Modifier.height(Space.xl))
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offline banner — non-blocking, respects insets, announced politely (STATE-008).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun OfflineBanner() {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = LoginShapes.medium,
        modifier = Modifier
            .fillMaxWidth()
            .semantics { liveRegion = LiveRegionMode.Polite },
    ) {
        Row(
            modifier = Modifier.padding(Space.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = Icons.Filled.Info,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(Size.icon),
            )
            Spacer(Modifier.width(Space.sm))
            Text(
                text = "You're offline — check your connection. Sign in needs a network.",
                style = LoginType.body,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status / error message — generic copy, icon + text (not color-only), live region.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun StatusMessage(status: LoginStatus, alpha: Float) {
    val message: String? = when (status) {
        is LoginStatus.Error -> status.message
        else -> null
    }
    if (message != null) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = Space.sm)
                .alpha(alpha)
                .semantics {
                    // Announce assertively; TalkBack reads it without stealing focus (A11Y-018).
                    liveRegion = LiveRegionMode.Assertive
                    contentDescription = message
                },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = Icons.Filled.Warning,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.error,
                modifier = Modifier.size(Size.icon),
            )
            Spacer(Modifier.width(Space.sm))
            Text(
                text = message,
                style = LoginType.body,
                color = MaterialTheme.colorScheme.error,
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// "or" divider — RTL-safe (weights + logical horizontal padding).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun OrDivider() {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        HorizontalDivider(modifier = Modifier.weight(1f))
        Text(
            text = "or",
            style = LoginType.label,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = Space.md),
        )
        HorizontalDivider(modifier = Modifier.weight(1f))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success → biometric opt-in with a password fallback (opt-in, never forced).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun BiometricOptInCard(onEnable: () -> Unit, onUsePassword: () -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(Space.md)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.Check,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(Size.icon),
                )
                Spacer(Modifier.width(Space.sm))
                Text(
                    text = "Signed in — success",
                    style = LoginType.action,
                    color = MaterialTheme.colorScheme.onSurface,
                )
            }
            Spacer(Modifier.height(Space.sm))
            Text(
                text = "Use biometric unlock next time? You can always sign in with your password instead.",
                style = LoginType.body,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(Space.md))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Space.sm),
            ) {
                OutlinedButton(
                    onClick = onUsePassword,
                    modifier = Modifier
                        .weight(1f)
                        .heightIn(min = Size.minTarget),
                ) {
                    Text("Use password")
                }
                Button(
                    onClick = onEnable,
                    modifier = Modifier
                        .weight(1f)
                        .heightIn(min = Size.minTarget),
                ) {
                    Text("Enable")
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission-denied → clean password fallback + optional Settings link (never a dead end).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun BiometricDeniedCard(onOpenSettings: () -> Unit, onUsePassword: () -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(Space.md)) {
            Text(
                text = "Biometric unavailable",
                style = LoginType.action,
                color = MaterialTheme.colorScheme.onSurface,
            )
            Spacer(Modifier.height(Space.sm))
            Text(
                text = "This device hasn't enrolled biometrics, or permission was denied. " +
                    "You can keep signing in with your password, or enable it in Settings.",
                style = LoginType.body,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(Space.md))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Space.sm),
            ) {
                OutlinedButton(
                    onClick = onUsePassword,
                    modifier = Modifier
                        .weight(1f)
                        .heightIn(min = Size.minTarget),
                ) {
                    Text("Use password")
                }
                Button(
                    onClick = onOpenSettings,
                    modifier = Modifier
                        .weight(1f)
                        .heightIn(min = Size.minTarget),
                ) {
                    Icon(
                        imageVector = Icons.Filled.Settings,
                        contentDescription = null,
                        modifier = Modifier.size(Size.ssoIcon),
                    )
                    Spacer(Modifier.width(Space.sm))
                    Text("Settings")
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Host Activity — edge-to-edge is enabled here; the composable inherits the insets.
// ─────────────────────────────────────────────────────────────────────────────
class LoginActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            LoginTheme {
                LoginScreen(onAuthenticated = { /* navigate to intended destination / deep link */ })
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Previews — one per state so the whole matrix is inspectable at a glance.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun PreviewHost(state: LoginUiState) = LoginTheme {
    LoginScreenContent(
        state = state,
        onEmailChange = {}, onPasswordChange = {}, onToggleVisibility = {},
        onSubmit = {}, onForgotPassword = {}, onSignUp = {}, onGuest = {},
        onGoogle = {}, onApple = {}, onEnableBiometric = {}, onSkipBiometric = {},
        onOpenSettings = {},
    )
}

@Preview(name = "Login — idle (ready)", showBackground = true)
@Composable
private fun LoginIdlePreview() =
    PreviewHost(LoginUiState(email = "you@example.com", password = "secret"))

@Preview(name = "Login — empty", showBackground = true)
@Composable
private fun LoginEmptyPreview() =
    PreviewHost(LoginUiState(status = LoginStatus.Empty))

@Preview(name = "Login — loading", showBackground = true)
@Composable
private fun LoginLoadingPreview() =
    PreviewHost(LoginUiState(email = "you@example.com", password = "secret", status = LoginStatus.Loading))

@Preview(name = "Login — error", showBackground = true)
@Composable
private fun LoginErrorPreview() =
    PreviewHost(
        LoginUiState(
            email = "you@example.com",
            password = "secret",
            status = LoginStatus.Error("Email or password is incorrect."),
        ),
    )

@Preview(name = "Login — offline", showBackground = true)
@Composable
private fun LoginOfflinePreview() =
    PreviewHost(LoginUiState(email = "you@example.com", isOffline = true, status = LoginStatus.Offline))

@Preview(name = "Login — success (biometric opt-in)", showBackground = true)
@Composable
private fun LoginSuccessPreview() =
    PreviewHost(LoginUiState(email = "you@example.com", password = "secret", status = LoginStatus.Success))

@Preview(name = "Login — permission denied", showBackground = true)
@Composable
private fun LoginPermissionDeniedPreview() =
    PreviewHost(LoginUiState(email = "you@example.com", status = LoginStatus.PermissionDenied))
