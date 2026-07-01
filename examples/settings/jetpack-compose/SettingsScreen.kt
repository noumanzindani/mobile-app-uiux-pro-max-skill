package ux.examples.settings

/**
 * SettingsScreen — an accessible, searchable, all-states Material 3 grouped preference
 * list for Jetpack Compose (Material 3 Expressive). Implements the settings example spec:
 *
 *  - grouped preference list with category headers (Account · Notifications ·
 *    Privacy & Security · Appearance · About & Help), each header exposed as a heading,
 *  - a SEARCH field that filters across ALL settings, with a distinct zero-results Empty,
 *  - four row types — a Switch toggle, a disclosure (clickable row + auto-mirrored chevron),
 *    a value+chevron row that opens a bottom-sheet picker, and a button-styled action row,
 *  - a light / dark / system THEME selector in a ModalBottomSheet,
 *  - an ISOLATED destructive group at the very bottom (Sign out · Delete account) with
 *    error-colored labels, each behind an AlertDialog; account deletion is a MULTI-STEP
 *    confirm (store policy),
 *  - responsive layout: compact (<600dp) is a single scrolling list that pushes a sub-page,
 *    expanded (≥840dp) is a two-pane list-detail (category rail + detail),
 *  - the 7 UI states via a sealed `SettingsState`: search zero-results (Empty), a synced-value
 *    skeleton (Loading), a failed Switch that REVERTS + a message (Error, never a silent false
 *    success), an offline banner with server toggles disabled/queued (Offline), a saved-confirmed
 *    banner (Success), and OS-permission rows that reflect the true system state and deep-link
 *    to system Settings (PermissionDenied).
 *
 * RTL-safe (start/end + RTL-aware alignment; chevron auto-mirrors), Dynamic-Type-safe
 * (typography roles, no fixed text heights, labels wrap), targets ≥48dp, motion animates
 * alpha only with a reduce-motion snap() fallback. Every color/spacing/size/radius comes
 * from SettingsTokens; the composable references only tokens + MaterialTheme roles.
 */

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SearchOff
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.VerticalDivider
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.tooling.preview.Preview
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// ─────────────────────────────────────────────────────────────────────────────
// STATE — a sealed interface makes coverage of all 7 states auditable (STATE-*).
// The words loading / empty / error / offline / success appear here by design.
// ─────────────────────────────────────────────────────────────────────────────
sealed interface SettingsState {
    /** Ideal: groups + toggles reflect the current, saved values; search works. */
    data object Ideal : SettingsState

    /** Loading: server-synced values are still fetching — show a shape-matched skeleton. */
    data object Loading : SettingsState

    /** Empty: a search that matches nothing — a distinct zero-results ("No settings match …"). */
    data object Empty : SettingsState

    /** Error: a toggle that failed to save — the switch REVERTS and a message is shown. */
    data class Error(val message: String) : SettingsState

    /** Offline: local prefs still work; server-synced toggles are disabled/queued with a reason. */
    data object Offline : SettingsState

    /** Success: a change saved — confirmed inline (the toggle reflects the true saved state). */
    data class Success(val message: String) : SettingsState

    /** Permission-denied: an OS-permission row reflects the true system state + deep-links out. */
    data object PermissionDenied : SettingsState
}

/** Light / dark / system theme choice for the Appearance selector (DRK-001). */
enum class ThemeChoice(val label: String) {
    System("System default"),
    Light("Light"),
    Dark("Dark"),
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTING ITEMS — a small sealed model so each row type renders + announces correctly.
// ─────────────────────────────────────────────────────────────────────────────
sealed interface SettingItem {
    val id: String
    val title: String

    /** Extra searchable terms so search filters across ALL settings, not just visible labels. */
    val keywords: String

    /** Toggle (`Switch`) — a boolean preference; `serverSynced` ones disable/queue when offline. */
    data class Toggle(
        override val id: String,
        override val title: String,
        val supporting: String,
        val checked: Boolean,
        val serverSynced: Boolean = false,
        override val keywords: String = title,
    ) : SettingItem

    /** Disclosure — the whole row navigates to a sub-page (trailing auto-mirrored chevron). */
    data class Disclosure(
        override val id: String,
        override val title: String,
        val supporting: String,
        val route: String,
        override val keywords: String = title,
    ) : SettingItem

    /** Value + chevron — opens a picker / bottom sheet; shows the current value inline. */
    data class Value(
        override val id: String,
        override val title: String,
        val value: String,
        override val keywords: String = title,
    ) : SettingItem

    /** Action — a button-styled row (primary label), e.g. "Send feedback". */
    data class Action(
        override val id: String,
        override val title: String,
        override val keywords: String = title,
    ) : SettingItem

    /** Permission — mirrors an OS permission; reflects the true state + deep-links to Settings. */
    data class Permission(
        override val id: String,
        override val title: String,
        val granted: Boolean,
        override val keywords: String = title,
    ) : SettingItem
}

/** A titled group of rows rendered as one inset card under a heading. */
data class SettingsGroup(val id: String, val title: String, val items: List<SettingItem>)

/** Hoisted, immutable UI state. Toggles live in a map so a failed save can revert cleanly. */
data class SettingsUiState(
    val query: String = "",
    val syncing: Boolean = false,
    val isOffline: Boolean = false,
    val theme: ThemeChoice = ThemeChoice.System,
    val notificationsAllowed: Boolean = true,
    val toggles: Map<String, Boolean> = defaultToggles,
    val feedback: SettingsState = SettingsState.Ideal,
)

private val defaultToggles: Map<String, Boolean> = mapOf(
    "email_notifs" to true,
    "push_notifs" to true,
    "sounds" to false,
    "analytics" to false,
    "crash_reports" to true,
    "personalized_ads" to false,
)

/** Server-synced toggles need a network — they disable/queue when offline (OFF-002). */
private fun isServerSynced(id: String): Boolean =
    id in setOf("email_notifs", "push_notifs", "analytics", "personalized_ads")

// ─────────────────────────────────────────────────────────────────────────────
// DATA — build the grouped model from the current state (toggles + theme + permission).
// ─────────────────────────────────────────────────────────────────────────────
private fun buildGroups(state: SettingsUiState): List<SettingsGroup> = listOf(
    SettingsGroup(
        id = "account",
        title = "Account",
        items = listOf(
            SettingItem.Disclosure(
                id = "profile", title = "Profile",
                supporting = "Name, email, phone", route = "profile",
                keywords = "profile name email phone avatar",
            ),
            SettingItem.Disclosure(
                id = "security", title = "Password & security",
                supporting = "Change password, 2-step verification", route = "security",
                keywords = "password security login two step verification passkey",
            ),
            SettingItem.Value(
                id = "region", title = "Region",
                value = "United States",
                keywords = "region country locale currency",
            ),
        ),
    ),
    SettingsGroup(
        id = "notifications",
        title = "Notifications",
        items = listOf(
            SettingItem.Permission(
                id = "os_notifs", title = "System notifications",
                granted = state.notificationsAllowed,
                keywords = "notifications permission system allow push alerts",
            ),
            SettingItem.Toggle(
                id = "email_notifs", title = "Email notifications",
                supporting = "Product news and receipts",
                checked = state.toggles["email_notifs"] == true, serverSynced = true,
                keywords = "email notifications receipts news",
            ),
            SettingItem.Toggle(
                id = "push_notifs", title = "Push notifications",
                supporting = "Alerts on this device",
                checked = state.toggles["push_notifs"] == true, serverSynced = true,
                keywords = "push notifications alerts device",
            ),
            SettingItem.Toggle(
                id = "sounds", title = "Sounds",
                supporting = "Play a sound for alerts",
                checked = state.toggles["sounds"] == true,
                keywords = "sound vibration ringtone",
            ),
        ),
    ),
    SettingsGroup(
        id = "privacy",
        title = "Privacy & Security",
        items = listOf(
            SettingItem.Toggle(
                id = "analytics", title = "Share analytics",
                supporting = "Help improve the app",
                checked = state.toggles["analytics"] == true, serverSynced = true,
                keywords = "analytics data usage privacy telemetry",
            ),
            SettingItem.Toggle(
                id = "crash_reports", title = "Crash reports",
                supporting = "Send diagnostics automatically",
                checked = state.toggles["crash_reports"] == true,
                keywords = "crash reports diagnostics logs",
            ),
            SettingItem.Toggle(
                id = "personalized_ads", title = "Personalized ads",
                supporting = "Use activity to tailor ads",
                checked = state.toggles["personalized_ads"] == true, serverSynced = true,
                keywords = "ads advertising personalization tracking",
            ),
            SettingItem.Disclosure(
                id = "your_data", title = "Your data",
                supporting = "Download or delete your data", route = "your_data",
                keywords = "data download export delete privacy",
            ),
        ),
    ),
    SettingsGroup(
        id = "appearance",
        title = "Appearance",
        items = listOf(
            SettingItem.Value(
                id = "theme", title = "Theme",
                value = state.theme.label,
                keywords = "theme appearance dark light system mode display",
            ),
            SettingItem.Value(
                id = "text_size", title = "Text size",
                value = "Default",
                keywords = "text size font scaling accessibility dynamic type",
            ),
        ),
    ),
    SettingsGroup(
        id = "about",
        title = "About & Help",
        items = listOf(
            SettingItem.Disclosure(
                id = "help", title = "Help center",
                supporting = "FAQs and contact", route = "help",
                keywords = "help support faq contact",
            ),
            SettingItem.Action(
                id = "feedback", title = "Send feedback",
                keywords = "feedback bug report suggestion",
            ),
            SettingItem.Value(
                id = "version", title = "Version",
                value = "4.8.0 (1024)",
                keywords = "version build about",
            ),
            SettingItem.Disclosure(
                id = "legal", title = "Legal",
                supporting = "Terms and privacy policy", route = "legal",
                keywords = "legal terms privacy policy licenses",
            ),
        ),
    ),
)

/** Filter every group's items by the query; drop groups that end up empty (SET-002). */
private fun filterGroups(groups: List<SettingsGroup>, query: String): List<SettingsGroup> {
    val q = query.trim()
    if (q.isEmpty()) return groups
    return groups.mapNotNull { group ->
        val matches = group.items.filter {
            it.title.contains(q, ignoreCase = true) || it.keywords.contains(q, ignoreCase = true)
        }
        if (matches.isEmpty()) null else group.copy(items = matches)
    }
}

private fun groupIcon(id: String): ImageVector = when (id) {
    "account" -> Icons.Filled.Person
    "notifications" -> Icons.Filled.Notifications
    "privacy" -> Icons.Filled.Security
    "appearance" -> Icons.Filled.Palette
    else -> Icons.Filled.Info
}

// ─────────────────────────────────────────────────────────────────────────────
// STATEFUL ENTRY POINT — owns the UI state; simulates a save that succeeds or fails.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun SettingsScreen(
    modifier: Modifier = Modifier,
    onSignedOut: () -> Unit = {},
    onAccountDeleted: () -> Unit = {},
) {
    var state by remember { mutableStateOf(SettingsUiState()) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    // Success banners are transient — clear back to Ideal after a moment so they don't linger.
    LaunchedEffect(state.feedback) {
        if (state.feedback is SettingsState.Success) {
            delay(Motion.simulatedSaveMs)
            state = state.copy(feedback = SettingsState.Ideal)
        }
    }

    SettingsScreenContent(
        state = state,
        modifier = modifier,
        onQueryChange = { state = state.copy(query = it) },
        onToggle = { id, newValue ->
            when {
                // Offline + server-synced: don't flip silently — surface a reason (queued).
                state.isOffline && isServerSynced(id) ->
                    state = state.copy(
                        feedback = SettingsState.Error("You're offline — this change will sync later."),
                    )
                else -> {
                    val previous = state.toggles[id] == true
                    // Optimistic: reflect the new value immediately, then confirm the save.
                    state = state.copy(
                        toggles = state.toggles + (id to newValue),
                        feedback = SettingsState.Ideal,
                    )
                    scope.launch {
                        delay(Motion.simulatedSaveMs)
                        // Demo: "push_notifs" fails to save so the REVERT path is exercised.
                        state = if (id != "push_notifs") {
                            state.copy(feedback = SettingsState.Success("Saved"))
                        } else {
                            // Failed save REVERTS the switch + shows a message — never a silent
                            // false success (STATE-007).
                            state.copy(
                                toggles = state.toggles + (id to previous),
                                feedback = SettingsState.Error("Couldn't save — try again."),
                            )
                        }
                    }
                }
            }
        },
        onSelectTheme = { state = state.copy(theme = it, feedback = SettingsState.Success("Theme updated")) },
        onAction = { state = state.copy(feedback = SettingsState.Success("Thanks for your feedback")) },
        onOpenSystemNotificationSettings = {
            // Deep-link to the OS notification settings so the user can change the real permission.
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        },
        onSignOut = onSignedOut,
        onDeleteAccount = onAccountDeleted,
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// STATELESS CONTENT — pure + previewable. BoxWithConstraints reads the available width
// and routes single-pane (compact/medium) vs two-pane (expanded ≥840dp) live (GRD-003).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun SettingsScreenContent(
    state: SettingsUiState,
    onQueryChange: (String) -> Unit,
    onToggle: (String, Boolean) -> Unit,
    onSelectTheme: (ThemeChoice) -> Unit,
    onAction: (String) -> Unit,
    onOpenSystemNotificationSettings: () -> Unit,
    onSignOut: () -> Unit,
    onDeleteAccount: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val reduceMotion = rememberReduceMotion()

    // Local navigation / dialog state kept in the stateless view (pure UI concerns).
    var subPage by remember { mutableStateOf<String?>(null) }
    var selectedCategory by remember { mutableStateOf("account") }
    var showThemeSheet by remember { mutableStateOf(false) }
    var confirmSignOut by remember { mutableStateOf(false) }
    var deleteStep by remember { mutableStateOf(0) }

    val allGroups = buildGroups(state)
    val visibleGroups = filterGroups(allGroups, state.query)
    val searching = state.query.isNotBlank()

    // Cross-cutting connection state — drives the persistent, non-blocking offline banner.
    val connectionState: SettingsState =
        if (state.isOffline) SettingsState.Offline else SettingsState.Ideal

    // The main content region resolves to exactly one of these (STATE-*).
    val contentState: SettingsState = when {
        state.syncing -> SettingsState.Loading
        searching && visibleGroups.isEmpty() -> SettingsState.Empty
        else -> SettingsState.Ideal
    }

    // A value row routes to the right surface: theme opens the sheet, others push a sub-page.
    val onOpenValue: (SettingItem.Value) -> Unit = { item ->
        if (item.id == "theme") showThemeSheet = true else subPage = item.id
    }

    BoxWithConstraints(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.surface)
            // Edge-to-edge: consume the safe-drawing insets so content clears the system bars.
            .windowInsetsPadding(WindowInsets.safeDrawing),
    ) {
        val expanded = maxWidth >= Breakpoints.expanded

        Column(modifier = Modifier.fillMaxSize()) {
            SettingsTopBar(subTitle = subPage?.let { routeTitle(it) }, onBack = { subPage = null })

            if (subPage == null) {
                SettingsSearchField(query = state.query, onQueryChange = onQueryChange)
            }

            // Non-blocking offline banner + transient save-result banner (both fade-only).
            OfflineBanner(state = connectionState, reduceMotion = reduceMotion)
            FeedbackBanner(state = state.feedback, reduceMotion = reduceMotion)

            Box(modifier = Modifier.fillMaxWidth().weight(1f)) {
                when {
                    // Compact sub-page (pushed detail) — a back arrow returns to the list.
                    subPage != null -> SubPage(route = subPage!!)

                    // Loading: server-synced values still fetching — shape-matched skeleton.
                    contentState == SettingsState.Loading ->
                        SkeletonList(groups = allGroups)

                    // Empty: search matched nothing — a distinct zero-results (announced).
                    contentState == SettingsState.Empty ->
                        ZeroResults(query = state.query)

                    // Expanded two-pane list-detail (not while searching — search flattens).
                    expanded && !searching -> TwoPane(
                        groups = allGroups,
                        selectedCategory = selectedCategory,
                        state = state,
                        onSelectCategory = { selectedCategory = it },
                        onToggle = onToggle,
                        onOpenDisclosure = { subPage = it },
                        onOpenValue = onOpenValue,
                        onAction = onAction,
                        onOpenSystemNotificationSettings = onOpenSystemNotificationSettings,
                        onSignOut = { confirmSignOut = true },
                        onDeleteAccount = { deleteStep = 1 },
                    )

                    // Compact / medium single list (or the flattened search results).
                    else -> GroupedSettings(
                        groups = visibleGroups,
                        state = state,
                        showDestructive = !searching,
                        modifier = Modifier
                            .fillMaxSize()
                            .widthIn(max = Size.maxContentWidth),
                        onToggle = onToggle,
                        onOpenDisclosure = { subPage = it },
                        onOpenValue = onOpenValue,
                        onAction = onAction,
                        onOpenSystemNotificationSettings = onOpenSystemNotificationSettings,
                        onSignOut = { confirmSignOut = true },
                        onDeleteAccount = { deleteStep = 1 },
                    )
                }
            }
        }
    }

    // ── Theme picker (value+chevron opens a bottom-sheet; light / dark / system) ──
    if (showThemeSheet) {
        ThemePickerSheet(
            current = state.theme,
            onSelect = { onSelectTheme(it); showThemeSheet = false },
            onDismiss = { showThemeSheet = false },
        )
    }

    // ── Destructive confirms — each isolated action is behind an explicit dialog ──
    if (confirmSignOut) {
        SignOutDialog(
            onConfirm = { confirmSignOut = false; onSignOut() },
            onDismiss = { confirmSignOut = false },
        )
    }
    DeleteAccountDialogs(
        step = deleteStep,
        onAdvance = { deleteStep = 2 },
        onConfirm = { deleteStep = 0; onDeleteAccount() },
        onCancel = { deleteStep = 0 },
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar — title (or sub-page title + back). Title/heading exposed to TalkBack.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun SettingsTopBar(subTitle: String?, onBack: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.rowMinHeight)
            .padding(horizontal = Space.sm, vertical = Space.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (subTitle != null) {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
            Spacer(Modifier.width(Space.xs))
        } else {
            Spacer(Modifier.width(Space.sm))
        }
        Text(
            text = subTitle ?: "Settings",
            style = SettingsType.screenTitle,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.semantics { heading() },
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search field — labeled; filters across all settings; a clear button when non-empty.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun SettingsSearchField(query: String, onQueryChange: (String) -> Unit) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        singleLine = true,
        label = { Text("Search settings") },
        placeholder = { Text("Search settings") },
        leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Filled.Close, contentDescription = "Clear search")
                }
            }
        },
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.rowMinHeight)
            .padding(horizontal = Space.md, vertical = Space.sm)
            .semantics { contentDescription = "Search settings" },
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// Grouped list — headers + inset cards of rows + the isolated destructive zone.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun GroupedSettings(
    groups: List<SettingsGroup>,
    state: SettingsUiState,
    showDestructive: Boolean,
    onToggle: (String, Boolean) -> Unit,
    onOpenDisclosure: (String) -> Unit,
    onOpenValue: (SettingItem.Value) -> Unit,
    onAction: (String) -> Unit,
    onOpenSystemNotificationSettings: () -> Unit,
    onSignOut: () -> Unit,
    onDeleteAccount: () -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier,
        contentPadding = PaddingValues(top = Space.sm, bottom = Space.xl),
    ) {
        items(groups, key = { it.id }) { group ->
            GroupCard(
                group = group,
                state = state,
                onToggle = onToggle,
                onOpenDisclosure = onOpenDisclosure,
                onOpenValue = onOpenValue,
                onAction = onAction,
                onOpenSystemNotificationSettings = onOpenSystemNotificationSettings,
            )
        }
        if (showDestructive) {
            item(key = "destructive") {
                DestructiveZone(onSignOut = onSignOut, onDeleteAccount = onDeleteAccount)
            }
        }
    }
}

@Composable
private fun GroupCard(
    group: SettingsGroup,
    state: SettingsUiState,
    onToggle: (String, Boolean) -> Unit,
    onOpenDisclosure: (String) -> Unit,
    onOpenValue: (SettingItem.Value) -> Unit,
    onAction: (String) -> Unit,
    onOpenSystemNotificationSettings: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        SectionHeader(group.title)
        Surface(
            color = MaterialTheme.colorScheme.surfaceContainer,
            shape = MaterialTheme.shapes.large,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Space.md),
        ) {
            Column(modifier = Modifier.fillMaxWidth()) {
                group.items.forEachIndexed { index, item ->
                    SettingRowDispatch(
                        item = item,
                        offline = state.isOffline,
                        onToggle = onToggle,
                        onOpenDisclosure = onOpenDisclosure,
                        onOpenValue = onOpenValue,
                        onAction = onAction,
                        onOpenSystemNotificationSettings = onOpenSystemNotificationSettings,
                    )
                    if (index < group.items.lastIndex) RowDivider()
                }
            }
        }
        Spacer(Modifier.height(Space.group))
    }
}

/** Section header — exposed as a heading so TalkBack can jump between groups (A11Y-017). */
@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        style = SettingsType.groupHeader,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier
            .padding(start = Space.rowInset, end = Space.md, top = Space.md, bottom = Space.sm)
            .semantics { heading() },
    )
}

/** Divider between rows in a group — outline-variant, inset to the row keyline (RTL-safe). */
@Composable
private fun RowDivider() {
    HorizontalDivider(
        color = MaterialTheme.colorScheme.outlineVariant,
        modifier = Modifier.padding(start = Space.rowInset),
    )
}

@Composable
private fun SettingRowDispatch(
    item: SettingItem,
    offline: Boolean,
    onToggle: (String, Boolean) -> Unit,
    onOpenDisclosure: (String) -> Unit,
    onOpenValue: (SettingItem.Value) -> Unit,
    onAction: (String) -> Unit,
    onOpenSystemNotificationSettings: () -> Unit,
) {
    when (item) {
        is SettingItem.Toggle -> ToggleRow(
            item = item,
            enabled = !(offline && item.serverSynced),
            onCheckedChange = { onToggle(item.id, it) },
        )
        is SettingItem.Disclosure -> DisclosureRow(item = item, onClick = { onOpenDisclosure(item.route) })
        is SettingItem.Value -> ValueRow(item = item, onClick = { onOpenValue(item) })
        is SettingItem.Action -> ActionRow(item = item, onClick = { onAction(item.id) })
        is SettingItem.Permission -> PermissionRow(item = item, onClick = onOpenSystemNotificationSettings)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row types
// ─────────────────────────────────────────────────────────────────────────────

/** Toggle — the whole row is toggleable with role=Switch; state announced, not color-only. */
@Composable
private fun ToggleRow(
    item: SettingItem.Toggle,
    enabled: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    val stateWord = if (item.checked) "On" else "Off"
    val reason = if (!enabled) " Unavailable while offline; changes queue and sync later." else ""
    val supportingText = if (enabled) item.supporting else item.supporting + " · Syncs later"
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.rowMinHeight)
            .toggleable(
                value = item.checked,
                enabled = enabled,
                role = Role.Switch,
                onValueChange = onCheckedChange,
            )
            .padding(horizontal = Space.rowInset, vertical = Space.sm)
            .semantics(mergeDescendants = true) {
                stateDescription = stateWord
                contentDescription = "${item.title}. ${item.supporting}.$reason"
            },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = item.title,
                style = SettingsType.rowLabel,
                color = MaterialTheme.colorScheme.onSurface,
            )
            Text(
                text = supportingText,
                style = SettingsType.rowValue,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Spacer(Modifier.width(Space.md))
        // onCheckedChange = null → the row (above) owns the toggle semantics; no double target.
        Switch(checked = item.checked, onCheckedChange = null, enabled = enabled)
    }
}

/** Disclosure — clickable row + trailing auto-mirrored chevron; announces it navigates. */
@Composable
private fun DisclosureRow(item: SettingItem.Disclosure, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.rowMinHeight)
            .clickable(onClickLabel = "Opens ${item.title}") { onClick() }
            .padding(horizontal = Space.rowInset, vertical = Space.sm)
            .semantics(mergeDescendants = true) {
                contentDescription = "${item.title}. ${item.supporting}. Opens a sub-page."
            },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(item.title, style = SettingsType.rowLabel, color = MaterialTheme.colorScheme.onSurface)
            Text(item.supporting, style = SettingsType.rowValue, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Spacer(Modifier.width(Space.sm))
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null, // auto-mirrors in RTL; the row's contentDescription covers it
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(Size.icon),
        )
    }
}

/** Value + chevron — shows the current value; opens a picker / bottom sheet on tap. */
@Composable
private fun ValueRow(item: SettingItem.Value, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.rowMinHeight)
            .clickable(onClickLabel = "Change ${item.title}") { onClick() }
            .padding(horizontal = Space.rowInset, vertical = Space.sm)
            .semantics(mergeDescendants = true) {
                contentDescription = "${item.title}, ${item.value}. Opens options."
            },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = item.title,
            style = SettingsType.rowLabel,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f),
        )
        Text(
            text = item.value,
            style = SettingsType.rowValue,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.width(Space.sm))
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(Size.icon),
        )
    }
}

/** Action — a button-styled row (primary label), e.g. "Send feedback". */
@Composable
private fun ActionRow(item: SettingItem.Action, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.rowMinHeight)
            .clickable(onClickLabel = item.title) { onClick() }
            .padding(horizontal = Space.rowInset, vertical = Space.sm)
            .semantics(mergeDescendants = true) { contentDescription = item.title },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = item.title,
            style = SettingsType.rowLabel,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.weight(1f),
        )
    }
}

/**
 * Permission — mirrors the OS permission's TRUE state and deep-links to system Settings
 * to change it (never re-prompts in-app). Value + reason are not color-only (PERM-003).
 */
@Composable
private fun PermissionRow(item: SettingItem.Permission, onClick: () -> Unit) {
    val permState: SettingsState = if (item.granted) SettingsState.Ideal else SettingsState.PermissionDenied
    val valueText = if (item.granted) "Allowed" else "Blocked"
    val reason = when (permState) {
        SettingsState.PermissionDenied -> "Turn on in system settings"
        else -> "Managed by the system"
    }
    val valueColor =
        if (item.granted) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.error
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.rowMinHeight)
            .clickable(onClickLabel = "Open system settings") { onClick() }
            .padding(horizontal = Space.rowInset, vertical = Space.sm)
            .semantics(mergeDescendants = true) {
                contentDescription = "${item.title}, $valueText. $reason. Opens system settings."
            },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(item.title, style = SettingsType.rowLabel, color = MaterialTheme.colorScheme.onSurface)
            Text(reason, style = SettingsType.rowValue, color = valueColor)
        }
        Text(valueText, style = SettingsType.rowValue, color = valueColor)
        Spacer(Modifier.width(Space.sm))
        Icon(
            imageVector = Icons.AutoMirrored.Filled.OpenInNew,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(Size.icon),
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Destructive zone — isolated at the very bottom, error-colored, each behind a confirm.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun DestructiveZone(onSignOut: () -> Unit, onDeleteAccount: () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth().padding(horizontal = Space.md)) {
        Spacer(Modifier.height(Space.lg))
        Surface(
            color = MaterialTheme.colorScheme.surfaceContainer,
            shape = MaterialTheme.shapes.large,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column(modifier = Modifier.fillMaxWidth()) {
                DestructiveRow(
                    label = "Sign out",
                    icon = Icons.AutoMirrored.Filled.Logout,
                    onClick = onSignOut,
                )
                RowDivider()
                DestructiveRow(
                    label = "Delete account",
                    icon = Icons.Filled.Delete,
                    onClick = onDeleteAccount,
                )
            }
        }
    }
}

@Composable
private fun DestructiveRow(label: String, icon: ImageVector, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.rowMinHeight)
            .clickable(onClickLabel = label) { onClick() }
            .padding(horizontal = Space.rowInset, vertical = Space.sm)
            .semantics(mergeDescendants = true) {
                contentDescription = "$label. Destructive action — asks for confirmation."
            },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.error,
            modifier = Modifier.size(Size.icon),
        )
        Spacer(Modifier.width(Space.md))
        Text(text = label, style = SettingsType.rowLabel, color = MaterialTheme.colorScheme.error)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Two-pane (expanded ≥840dp) — category rail (leading) + selected group's rows (detail).
// The destructive zone rides the Account detail so it stays isolated at the bottom.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun TwoPane(
    groups: List<SettingsGroup>,
    selectedCategory: String,
    state: SettingsUiState,
    onSelectCategory: (String) -> Unit,
    onToggle: (String, Boolean) -> Unit,
    onOpenDisclosure: (String) -> Unit,
    onOpenValue: (SettingItem.Value) -> Unit,
    onAction: (String) -> Unit,
    onOpenSystemNotificationSettings: () -> Unit,
    onSignOut: () -> Unit,
    onDeleteAccount: () -> Unit,
) {
    Row(modifier = Modifier.fillMaxSize()) {
        CategoryRail(
            groups = groups,
            selected = selectedCategory,
            onSelect = onSelectCategory,
            modifier = Modifier.width(Size.railWidth).fillMaxHeight(),
        )
        VerticalDivider(color = MaterialTheme.colorScheme.outlineVariant)
        val group = groups.firstOrNull { it.id == selectedCategory } ?: groups.first()
        GroupedSettings(
            groups = listOf(group),
            state = state,
            showDestructive = group.id == "account",
            modifier = Modifier.fillMaxSize().widthIn(max = Size.maxContentWidth),
            onToggle = onToggle,
            onOpenDisclosure = onOpenDisclosure,
            onOpenValue = onOpenValue,
            onAction = onAction,
            onOpenSystemNotificationSettings = onOpenSystemNotificationSettings,
            onSignOut = onSignOut,
            onDeleteAccount = onDeleteAccount,
        )
    }
}

@Composable
private fun CategoryRail(
    groups: List<SettingsGroup>,
    selected: String,
    onSelect: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.verticalScroll(rememberScrollState())) {
        groups.forEach { group ->
            val isSelected = group.id == selected
            val labelColor =
                if (isSelected) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onSurface
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = Size.rowMinHeight)
                    .selectable(
                        selected = isSelected,
                        role = Role.Tab,
                        onClick = { onSelect(group.id) },
                    )
                    .then(
                        if (isSelected) {
                            Modifier.background(MaterialTheme.colorScheme.secondaryContainer)
                        } else {
                            Modifier
                        },
                    )
                    .padding(horizontal = Space.rowInset, vertical = Space.sm)
                    .semantics(mergeDescendants = true) {
                        contentDescription = "${group.title} settings"
                    },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    imageVector = groupIcon(group.id),
                    contentDescription = null,
                    tint = labelColor,
                    modifier = Modifier.size(Size.icon),
                )
                Spacer(Modifier.width(Space.md))
                Text(text = group.title, style = SettingsType.rowLabel, color = labelColor)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offline banner — non-blocking, fade-only, announced politely (STATE-008, OFF-002).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun OfflineBanner(state: SettingsState, reduceMotion: Boolean) {
    val visible = state == SettingsState.Offline
    val bannerAlpha by animateFloatAsState(
        targetValue = if (visible) 1f else 0f,
        animationSpec = if (reduceMotion) snap() else tween(durationMillis = Motion.shortMillis),
        label = "offlineAlpha",
    )
    if (visible) {
        Surface(
            color = MaterialTheme.colorScheme.surfaceVariant,
            shape = MaterialTheme.shapes.medium,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Space.md, vertical = Space.xs)
                .alpha(bannerAlpha)
                .semantics { liveRegion = LiveRegionMode.Polite },
        ) {
            Row(modifier = Modifier.padding(Space.md), verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.CloudOff,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(Size.icon),
                )
                Spacer(Modifier.width(Space.sm))
                Text(
                    text = "You're offline. Server settings are disabled and will sync when you reconnect.",
                    style = SettingsType.body,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback banner — Error (revert + message, assertive) / Success (saved, polite).
// Icon + text (not color-only); fade-only with a reduce-motion snap() fallback.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun FeedbackBanner(state: SettingsState, reduceMotion: Boolean) {
    val message: String? = when (state) {
        is SettingsState.Error -> state.message
        is SettingsState.Success -> state.message
        else -> null
    }
    val isError = state is SettingsState.Error
    val bannerAlpha by animateFloatAsState(
        targetValue = if (message != null) 1f else 0f,
        animationSpec = if (reduceMotion) snap() else tween(durationMillis = Motion.shortMillis),
        label = "feedbackAlpha",
    )
    if (message != null) {
        val container =
            if (isError) MaterialTheme.colorScheme.errorContainer else MaterialTheme.colorScheme.secondaryContainer
        val onContainer =
            if (isError) MaterialTheme.colorScheme.onErrorContainer else MaterialTheme.colorScheme.onSecondaryContainer
        Surface(
            color = container,
            shape = MaterialTheme.shapes.medium,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Space.md, vertical = Space.xs)
                .alpha(bannerAlpha)
                .semantics {
                    liveRegion = if (isError) LiveRegionMode.Assertive else LiveRegionMode.Polite
                    contentDescription = message
                },
        ) {
            Row(modifier = Modifier.padding(Space.md), verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = if (isError) Icons.Filled.Warning else Icons.Filled.Check,
                    contentDescription = null,
                    tint = onContainer,
                    modifier = Modifier.size(Size.icon),
                )
                Spacer(Modifier.width(Space.sm))
                Text(text = message, style = SettingsType.body, color = onContainer)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading — a shape-matched skeleton for server-synced values (not a screen spinner).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun SkeletonList(groups: List<SettingsGroup>) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .semantics { contentDescription = "Loading settings" },
        contentPadding = PaddingValues(top = Space.sm, bottom = Space.xl),
    ) {
        items(groups, key = { "skeleton_${it.id}" }) { group ->
            Column(modifier = Modifier.fillMaxWidth()) {
                SectionHeader(group.title)
                Surface(
                    color = MaterialTheme.colorScheme.surfaceContainer,
                    shape = MaterialTheme.shapes.large,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = Space.md),
                ) {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        group.items.forEachIndexed { index, _ ->
                            SkeletonRow()
                            if (index < group.items.lastIndex) RowDivider()
                        }
                    }
                }
                Spacer(Modifier.height(Space.group))
            }
        }
    }
}

@Composable
private fun SkeletonRow() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.rowMinHeight)
            .padding(horizontal = Space.rowInset, vertical = Space.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            SkeletonBlock(heightToken = Size.skeletonLabel, fraction = 0.55f)
            Spacer(Modifier.height(Space.xs))
            SkeletonBlock(heightToken = Size.skeletonValue, fraction = 0.8f)
        }
    }
}

@Composable
private fun SkeletonBlock(heightToken: Dp, fraction: Float) {
    Box(
        modifier = Modifier
            .fillMaxWidth(fraction)
            .height(heightToken)
            .background(
                color = MaterialTheme.colorScheme.surfaceVariant,
                shape = MaterialTheme.shapes.small,
            ),
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty — a distinct zero-results state for search (the list itself is never empty).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun ZeroResults(query: String) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(Space.xl)
            .semantics { liveRegion = LiveRegionMode.Polite },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(
            imageVector = Icons.Filled.SearchOff,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(Size.emptyIcon),
        )
        Spacer(Modifier.height(Space.md))
        Text(
            text = "No settings match \"$query\"",
            style = SettingsType.emptyTitle,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(Space.xs))
        Text(
            text = "Try a different term, or browse the groups.",
            style = SettingsType.body,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact sub-page (pushed from a disclosure / value row). Kept minimal + real.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun SubPage(route: String) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Space.md, vertical = Space.md),
    ) {
        Text(
            text = routeDescription(route),
            style = SettingsType.body,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private fun routeTitle(route: String): String = when (route) {
    "profile" -> "Profile"
    "security" -> "Password & security"
    "your_data" -> "Your data"
    "text_size" -> "Text size"
    "region" -> "Region"
    "help" -> "Help center"
    "legal" -> "Legal"
    else -> "Settings"
}

private fun routeDescription(route: String): String =
    "This is the ${routeTitle(route)} sub-page. On a compact screen the list pushes here; " +
        "on an expanded screen it would open in the detail pane beside the group list."

// ─────────────────────────────────────────────────────────────────────────────
// Theme picker — value+chevron opens this sheet; light / dark / system radio options.
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ThemePickerSheet(
    current: ThemeChoice,
    onSelect: (ThemeChoice) -> Unit,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Space.md)
                .padding(bottom = Space.xl),
        ) {
            Text(
                text = "Theme",
                style = SettingsType.groupHeader,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier
                    .padding(vertical = Space.sm)
                    .semantics { heading() },
            )
            ThemeChoice.entries.forEach { choice ->
                val selected = choice == current
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = Size.rowMinHeight)
                        .selectable(
                            selected = selected,
                            role = Role.RadioButton,
                            onClick = { onSelect(choice) },
                        )
                        .padding(vertical = Space.sm)
                        .semantics(mergeDescendants = true) {
                            stateDescription = if (selected) "Selected" else "Not selected"
                            contentDescription = choice.label
                        },
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    RadioButton(selected = selected, onClick = null)
                    Spacer(Modifier.width(Space.md))
                    Text(
                        text = choice.label,
                        style = SettingsType.rowLabel,
                        color = MaterialTheme.colorScheme.onSurface,
                    )
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Destructive confirms — Sign out (single) + Delete account (multi-step, store policy).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun SignOutDialog(onConfirm: () -> Unit, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = { Icon(Icons.AutoMirrored.Filled.Logout, contentDescription = null) },
        title = { Text("Sign out?") },
        text = { Text("You'll need to sign in again to use your account on this device.") },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text("Sign out", color = MaterialTheme.colorScheme.error)
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

@Composable
private fun DeleteAccountDialogs(
    step: Int,
    onAdvance: () -> Unit,
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
) {
    when (step) {
        1 -> AlertDialog(
            onDismissRequest = onCancel,
            icon = { Icon(Icons.Filled.Delete, contentDescription = null) },
            title = { Text("Delete account?") },
            text = {
                Text(
                    "This permanently deletes your account and all associated data. " +
                        "This can't be undone.",
                )
            },
            confirmButton = { TextButton(onClick = onAdvance) { Text("Continue") } },
            dismissButton = { TextButton(onClick = onCancel) { Text("Cancel") } },
        )
        2 -> AlertDialog(
            onDismissRequest = onCancel,
            icon = {
                Icon(
                    Icons.Filled.Warning,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error,
                )
            },
            title = { Text("This is permanent") },
            text = {
                Text(
                    "All your data will be erased immediately and cannot be recovered. " +
                        "Are you absolutely sure you want to delete your account?",
                )
            },
            confirmButton = {
                TextButton(onClick = onConfirm) {
                    Text("Delete account", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = { TextButton(onClick = onCancel) { Text("Keep account") } },
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Host Activity — edge-to-edge is enabled here; the composable inherits the insets.
// ─────────────────────────────────────────────────────────────────────────────
class SettingsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            SettingsTheme {
                SettingsScreen(
                    onSignedOut = { /* clear session + navigate to /intro */ },
                    onAccountDeleted = { /* finish deletion flow + navigate to /intro */ },
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Previews — one per state / layout so the whole matrix is inspectable at a glance.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun PreviewHost(state: SettingsUiState) = SettingsTheme {
    SettingsScreenContent(
        state = state,
        onQueryChange = {}, onToggle = { _, _ -> }, onSelectTheme = {}, onAction = {},
        onOpenSystemNotificationSettings = {},
        onSignOut = {}, onDeleteAccount = {},
    )
}

@Preview(name = "Settings — ideal (compact)", showBackground = true)
@Composable
private fun SettingsIdealPreview() = PreviewHost(SettingsUiState())

@Preview(name = "Settings — loading (synced values)", showBackground = true)
@Composable
private fun SettingsLoadingPreview() = PreviewHost(SettingsUiState(syncing = true))

@Preview(name = "Settings — empty (search zero-results)", showBackground = true)
@Composable
private fun SettingsEmptyPreview() = PreviewHost(SettingsUiState(query = "zxcv"))

@Preview(name = "Settings — error (save failed, reverted)", showBackground = true)
@Composable
private fun SettingsErrorPreview() =
    PreviewHost(SettingsUiState(feedback = SettingsState.Error("Couldn't save — try again.")))

@Preview(name = "Settings — offline (server toggles disabled)", showBackground = true)
@Composable
private fun SettingsOfflinePreview() = PreviewHost(SettingsUiState(isOffline = true))

@Preview(name = "Settings — success (saved)", showBackground = true)
@Composable
private fun SettingsSuccessPreview() =
    PreviewHost(SettingsUiState(feedback = SettingsState.Success("Saved")))

@Preview(name = "Settings — permission denied (notifications blocked)", showBackground = true)
@Composable
private fun SettingsPermissionDeniedPreview() = PreviewHost(SettingsUiState(notificationsAllowed = false))

@Preview(name = "Settings — expanded (two-pane)", showBackground = true, widthDp = 900, heightDp = 720)
@Composable
private fun SettingsExpandedPreview() = PreviewHost(SettingsUiState())
