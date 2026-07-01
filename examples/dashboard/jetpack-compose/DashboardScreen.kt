package ux.examples.dashboard

/**
 * DashboardScreen — a glanceable, RESPONSIVE dashboard for Jetpack Compose (Material 3
 * Expressive) where EACH WIDGET OWNS ITS OWN STATE. Implements the dashboard example spec:
 *
 *  - a RESPONSIVE grid of self-contained metric cards + a small bar chart + an activity list
 *    that re-flows by width class (BoxWithConstraints against the breakpoint tokens):
 *      • Compact  (< 600dp) → 1 column + bottom NavigationBar,
 *      • Medium   (600–839dp) → 2 columns + NavigationRail,
 *      • Expanded (≥ 840dp) → 3 columns (4 at ≥ 1240dp); the chart spans 2, LazyVerticalGrid,
 *    with a capped max content measure so tiles never stretch edge-to-edge on huge screens,
 *  - PER-WIDGET STATE — there is NO single global spinner. Every tile independently renders a
 *    shape-matched skeleton (Loading), a scoped inline error + Retry that leaves the other tiles
 *    live (Error), a first-use empty with a CTA (Empty), or cached values with a stale indicator
 *    (Offline). One failed metric never blanks the screen (STATE-014),
 *  - a GLOBAL, non-blocking offline banner; pull-to-refresh is disabled offline with a reason,
 *  - TABULAR numbers (fontFeatureSettings "tnum") formatted with NumberFormat for the locale,
 *  - TREND by icon + sign + text (never color alone),
 *  - a bar chart drawn with Canvas — each bar labeled — PLUS a screen-reader DATA-TABLE fallback,
 *  - PullToRefresh; the "Updated" result is announced through a liveRegion.
 *
 * RTL-safe (start/end + RTL-aware Arrangement/Alignment; amounts end-aligned), Dynamic-Type-safe
 * (typography roles, no fixed text heights), targets ≥ 48dp, cards grouped for one coherent
 * screen-reader name, motion animates alpha/offset only with a reduce-motion snap() fallback.
 * Every color / spacing / size / radius / breakpoint comes from DashboardTokens.
 */

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.filled.DirectionsWalk
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.TrendingFlat
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
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
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import java.text.NumberFormat
import java.util.Locale
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import androidx.compose.ui.geometry.Size as CanvasSize

// ─────────────────────────────────────────────────────────────────────────────
// PER-WIDGET STATE — the dashboard's defining rule. A sealed interface makes the
// seven states auditable; each TILE carries its own [WidgetState] so one failing
// metric never blanks the others (STATE-014). The words loading / empty / error /
// offline / success appear here by design.
// ─────────────────────────────────────────────────────────────────────────────
sealed interface WidgetState {
    /** Loading: a shape-matched skeleton (number block / chart / rows) — not a global spinner. */
    data object Loading : WidgetState

    /** Empty: first-use, no data yet — a positive message + an optional CTA, never a dead end. */
    data object Empty : WidgetState

    /** Error: this tile failed — a scoped inline message + Retry; the other tiles stay live. */
    data class Error(val message: String) : WidgetState

    /** Offline: source unreachable — show the cached value with a "stale / last updated" indicator. */
    data object Offline : WidgetState

    /** Success: freshly updated in place after a refresh/action — announced via a live region. */
    data object Success : WidgetState

    /** PermissionDenied: needs a permission (e.g. activity) — scoped explain + Settings + fallback. */
    data object PermissionDenied : WidgetState

    /** Ideal: steady state — value + trend rendered. */
    data object Ideal : WidgetState
}

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN — metric values are pre-formatted through NumberFormat for the locale and
// rendered with the tabular ('tnum') type role so number columns align (TYP-006, L10N-005).
// ─────────────────────────────────────────────────────────────────────────────
enum class TrendDirection { Up, Down, Flat }

/** A trend is conveyed by direction (icon) + sign + text — NEVER color alone (CHT-001, A11Y-012). */
data class Trend(val direction: TrendDirection, val text: String)

data class MetricValue(val display: String, val trend: Trend?)

data class MetricTile(
    val id: String,
    val title: String,
    val icon: ImageVector,
    val state: WidgetState,
    val value: MetricValue? = null,
    /** For Offline: how stale the cached value is (e.g. "Updated 2h ago"). */
    val staleLabel: String? = null,
    /** For Empty: the first-use call to action label. */
    val emptyCta: String? = null,
)

data class ChartBar(val label: String, val value: Double)
data class ChartData(val title: String, val bars: List<ChartBar>, val state: WidgetState)

data class ActivityItem(val id: String, val title: String, val meta: String)
data class ActivityFeed(val items: List<ActivityItem>, val state: WidgetState)

data class NavDestination(val label: String, val icon: ImageVector)

/** Hoisted, immutable UI state. Each tile owns its status; nothing is a single global flag. */
data class DashboardUiState(
    val greetingName: String = "Alex",
    val tiles: List<MetricTile> = DEMO_TILES,
    val chart: ChartData = DEMO_CHART,
    val activity: ActivityFeed = DEMO_ACTIVITY,
    val destinations: List<NavDestination> = DEMO_DESTINATIONS,
    val selectedTab: Int = 0,
    val isOffline: Boolean = false,
    val isRefreshing: Boolean = false,
    val justUpdated: Boolean = false,
    val lastUpdatedLabel: String = "just now",
    val refreshBlockedReason: String? = null,
)

// ── Demo data (a real screen sources these from per-metric repositories) ─────
private const val BALANCE_CENTS = 243000L
private const val WALLET_CENTS = 51999L
private const val ORDERS_COUNT = 128L

private fun currencyOf(cents: Long, locale: Locale): String =
    NumberFormat.getCurrencyInstance(locale).format(cents / 100.0)

private fun integerOf(n: Long, locale: Locale): String =
    NumberFormat.getIntegerInstance(locale).format(n)

private val DEMO_TILES: List<MetricTile> = listOf(
    // Ideal — value + upward trend.
    MetricTile(
        id = "balance",
        title = "Balance",
        icon = Icons.Filled.AccountBalanceWallet,
        state = WidgetState.Ideal,
        value = MetricValue(
            display = currencyOf(BALANCE_CENTS, Locale.getDefault()),
            trend = Trend(TrendDirection.Up, "4% this week"),
        ),
    ),
    // Success — just refreshed in place; the change is announced.
    MetricTile(
        id = "orders",
        title = "Orders today",
        icon = Icons.Filled.ShoppingCart,
        state = WidgetState.Success,
        value = MetricValue(
            display = integerOf(ORDERS_COUNT, Locale.getDefault()),
            trend = Trend(TrendDirection.Up, "12 since this morning"),
        ),
    ),
    // Offline — this source is unreachable; show the cached value + a stale indicator.
    MetricTile(
        id = "wallet",
        title = "Payouts",
        icon = Icons.Filled.ReceiptLong,
        state = WidgetState.Offline,
        value = MetricValue(
            display = currencyOf(WALLET_CENTS, Locale.getDefault()),
            trend = Trend(TrendDirection.Flat, "no change"),
        ),
        staleLabel = "Updated 2h ago",
    ),
    // Error — scoped inline failure + Retry; every other tile stays live.
    MetricTile(
        id = "conversion",
        title = "Conversion rate",
        icon = Icons.Filled.Insights,
        state = WidgetState.Error("Couldn't load conversion rate."),
    ),
    // Loading — a shape-matched skeleton, not a global spinner.
    MetricTile(
        id = "sessions",
        title = "Active sessions",
        icon = Icons.Filled.Groups,
        state = WidgetState.Loading,
    ),
    // Empty — first use, no data yet, with a CTA.
    MetricTile(
        id = "signups",
        title = "New signups",
        icon = Icons.Filled.Person,
        state = WidgetState.Empty,
        emptyCta = "Invite teammates",
    ),
    // PermissionDenied — needs activity permission; explain + Settings + fallback.
    MetricTile(
        id = "steps",
        title = "Steps today",
        icon = Icons.Filled.DirectionsWalk,
        state = WidgetState.PermissionDenied,
    ),
)

private val DEMO_CHART = ChartData(
    title = "Revenue, last 7 days",
    state = WidgetState.Ideal,
    bars = listOf(
        ChartBar("Mon", 1200.0),
        ChartBar("Tue", 1850.0),
        ChartBar("Wed", 1600.0),
        ChartBar("Thu", 2100.0),
        ChartBar("Fri", 2450.0),
        ChartBar("Sat", 1750.0),
        ChartBar("Sun", 900.0),
    ),
)

private val DEMO_ACTIVITY = ActivityFeed(
    state = WidgetState.Ideal,
    items = listOf(
        ActivityItem("a1", "Payout sent to bank", "2 min ago"),
        ActivityItem("a2", "New order from Priya S.", "18 min ago"),
        ActivityItem("a3", "Refund issued", "1h ago"),
        ActivityItem("a4", "Subscription renewed", "3h ago"),
    ),
)

private val DEMO_DESTINATIONS = listOf(
    NavDestination("Home", Icons.Filled.GridView),
    NavDestination("Activity", Icons.Filled.ReceiptLong),
    NavDestination("Wallet", Icons.Filled.AccountBalanceWallet),
    NavDestination("Alerts", Icons.Filled.Notifications),
    NavDestination("Profile", Icons.Filled.Person),
)

private enum class WidthClass { Compact, Medium, Expanded }

// ─────────────────────────────────────────────────────────────────────────────
// STATEFUL ENTRY POINT — owns the state machine: per-tile retry + the pull-to-refresh
// path (which is BLOCKED with a reason while offline).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun DashboardScreen(
    modifier: Modifier = Modifier,
    onOpenMetric: (id: String) -> Unit = {},
) {
    var state by remember { mutableStateOf(DashboardUiState()) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    DashboardScreenContent(
        state = state,
        modifier = modifier,
        onRefresh = {
            if (state.isOffline) {
                // Refresh is disabled offline — surfaced as a reason on the banner, never silent.
                state = state.copy(refreshBlockedReason = "Can't refresh while offline — showing saved data.")
            } else {
                state = state.copy(isRefreshing = true, justUpdated = false, refreshBlockedReason = null)
                scope.launch {
                    delay(Motion.refreshSettleMs) // demo: re-fetch every tile's source
                    state = state.copy(isRefreshing = false, justUpdated = true, lastUpdatedLabel = "just now")
                }
            }
        },
        onRetryTile = { id ->
            // Scoped retry: only THIS tile cycles Loading → Ideal; the rest are untouched.
            state = state.copy(tiles = state.tiles.map { if (it.id == id) it.copy(state = WidgetState.Loading) else it })
            scope.launch {
                delay(Motion.refreshSettleMs)
                state = state.copy(
                    tiles = state.tiles.map {
                        if (it.id == id) {
                            it.copy(
                                state = WidgetState.Success,
                                value = MetricValue("3.4%", Trend(TrendDirection.Up, "0.3 pts today")),
                            )
                        } else {
                            it
                        }
                    },
                )
            }
        },
        onSelectDestination = { state = state.copy(selectedTab = it) },
        onOpenMetric = onOpenMetric,
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
// STATELESS CONTENT — pure + previewable. BoxWithConstraints reads the available width
// and re-flows against the breakpoint tokens live (rotate / fold / split-screen) (GRD-008).
// ─────────────────────────────────────────────────────────────────────────────
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DashboardScreenContent(
    state: DashboardUiState,
    onRefresh: () -> Unit,
    onRetryTile: (String) -> Unit,
    onSelectDestination: (Int) -> Unit,
    onOpenMetric: (String) -> Unit,
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val reduceMotion = rememberReduceMotion()

    BoxWithConstraints(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            // Edge-to-edge: consume the safe-drawing insets so content clears the system bars.
            .windowInsetsPadding(WindowInsets.safeDrawing),
    ) {
        val widthClass = when {
            maxWidth < Breakpoint.compact -> WidthClass.Compact
            maxWidth < Breakpoint.expanded -> WidthClass.Medium
            else -> WidthClass.Expanded
        }
        val columns = when (widthClass) {
            WidthClass.Compact -> 1
            WidthClass.Medium -> 2
            WidthClass.Expanded -> if (maxWidth >= Breakpoint.large) 4 else 3
        }

        if (widthClass == WidthClass.Compact) {
            // Compact: one column; primary destinations sit in the bottom thumb arc (NAV-001).
            Column(modifier = Modifier.fillMaxSize()) {
                DashboardMainColumn(
                    state = state,
                    columns = columns,
                    reduceMotion = reduceMotion,
                    onRefresh = onRefresh,
                    onRetryTile = onRetryTile,
                    onOpenMetric = onOpenMetric,
                    onOpenSettings = onOpenSettings,
                    modifier = Modifier.weight(1f),
                )
                DashboardNavBar(
                    destinations = state.destinations,
                    selected = state.selectedTab,
                    onSelect = onSelectDestination,
                )
            }
        } else {
            // Medium / Expanded promote the bottom bar to a side rail so the thumb zone isn't
            // wasted on wide screens (NAV-003, GRD-003).
            Row(modifier = Modifier.fillMaxSize()) {
                DashboardNavRail(
                    destinations = state.destinations,
                    selected = state.selectedTab,
                    onSelect = onSelectDestination,
                )
                DashboardMainColumn(
                    state = state,
                    columns = columns,
                    reduceMotion = reduceMotion,
                    onRefresh = onRefresh,
                    onRetryTile = onRetryTile,
                    onOpenMetric = onOpenMetric,
                    onOpenSettings = onOpenSettings,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

// Header + offline banner + the pull-to-refresh grid — shared by every width class so the
// only thing that changes across the breakpoints is the nav container and the column count.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DashboardMainColumn(
    state: DashboardUiState,
    columns: Int,
    reduceMotion: Boolean,
    onRefresh: () -> Unit,
    onRetryTile: (String) -> Unit,
    onOpenMetric: (String) -> Unit,
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        DashboardHeader(
            name = state.greetingName,
            justUpdated = state.justUpdated,
            lastUpdatedLabel = state.lastUpdatedLabel,
            reduceMotion = reduceMotion,
            onRefresh = onRefresh,
        )

        // Global, non-blocking offline banner (announced politely).
        OfflineBanner(
            isOffline = state.isOffline,
            reason = state.refreshBlockedReason,
            reduceMotion = reduceMotion,
        )

        PullToRefreshBox(
            isRefreshing = state.isRefreshing,
            onRefresh = onRefresh,
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
        ) {
            // Cap the content measure and center it — never stretch tiles edge-to-edge (GRD-005).
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.TopCenter) {
                DashboardGrid(
                    state = state,
                    columns = columns,
                    reduceMotion = reduceMotion,
                    onRetryTile = onRetryTile,
                    onOpenMetric = onOpenMetric,
                    onOpenSettings = onOpenSettings,
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// THE GRID — a LazyVerticalGrid so the chart can span 2 columns on wide layouts while the
// metric tiles reflow 1 → 2 → 3/4. The activity list spans the full width (LST-002, GRD-004).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun DashboardGrid(
    state: DashboardUiState,
    columns: Int,
    reduceMotion: Boolean,
    onRetryTile: (String) -> Unit,
    onOpenMetric: (String) -> Unit,
    onOpenSettings: () -> Unit,
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(columns),
        modifier = Modifier
            .fillMaxSize()
            .widthIn(max = Size.maxContentWidth),
        contentPadding = PaddingValues(
            start = Space.md, end = Space.md, top = Space.md, bottom = Space.xl,
        ),
        horizontalArrangement = Arrangement.spacedBy(Space.gutter),
        verticalArrangement = Arrangement.spacedBy(Space.gutter),
    ) {
        items(items = state.tiles, key = { it.id }) { tile ->
            MetricCard(
                tile = tile,
                reduceMotion = reduceMotion,
                onOpen = onOpenMetric,
                onRetry = onRetryTile,
                onOpenSettings = onOpenSettings,
            )
        }
        // Chart spans 2 columns where there's room (min with the column count for compact).
        item(span = { GridItemSpan(minOf(columns, 2)) }) {
            ChartCard(chart = state.chart, reduceMotion = reduceMotion)
        }
        // Activity list takes the full row.
        item(span = { GridItemSpan(columns) }) {
            ActivityCard(feed = state.activity)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP ZONE — greeting + refresh trigger + avatar; the "Updated" result rides a polite
// live region so assistive tech hears it after a refresh (A11Y-019).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun DashboardHeader(
    name: String,
    justUpdated: Boolean,
    lastUpdatedLabel: String,
    reduceMotion: Boolean,
    onRefresh: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Space.md, vertical = Space.sm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Space.sm),
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "Hi $name",
                style = DashboardType.greeting,
                color = MaterialTheme.dashboardColors.onSurfaceStrong,
            )
            UpdatedIndicator(
                visible = justUpdated,
                label = lastUpdatedLabel,
                reduceMotion = reduceMotion,
            )
        }
        IconButton(
            onClick = onRefresh,
            modifier = Modifier.heightIn(min = Size.minTarget),
        ) {
            Icon(
                imageVector = Icons.Filled.Refresh,
                contentDescription = "Refresh dashboard",
                modifier = Modifier.size(Size.icon),
            )
        }
        Icon(
            imageVector = Icons.Filled.AccountCircle,
            contentDescription = "Account",
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(Size.avatar),
        )
    }
}

/** "Updated just now" — announced politely; only opacity animates (reduce-motion → snap). */
@Composable
private fun UpdatedIndicator(visible: Boolean, label: String, reduceMotion: Boolean) {
    val fade by animateFloatAsState(
        targetValue = if (visible) 1f else 0f,
        animationSpec = if (reduceMotion) snap() else tween(durationMillis = Motion.updatedMillis),
        label = "updatedFade",
    )
    Text(
        text = "Updated $label",
        style = DashboardType.meta,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier
            .alpha(fade)
            .semantics {
                liveRegion = LiveRegionMode.Polite
                contentDescription = if (visible) "Dashboard updated $label" else ""
            },
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOBAL OFFLINE BANNER — non-blocking, announced politely; explains that refresh is paused
// and tiles show cached data. Only opacity animates (MOT-004, OFF-004, STATE-008).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun OfflineBanner(isOffline: Boolean, reason: String?, reduceMotion: Boolean) {
    val visible = isOffline || reason != null
    val fade by animateFloatAsState(
        targetValue = if (visible) 1f else 0f,
        animationSpec = if (reduceMotion) snap() else tween(durationMillis = Motion.shortMillis),
        label = "offlineFade",
    )
    if (!visible) return

    val message = reason
        ?: "You're offline — showing saved data. We'll refresh automatically when you reconnect."
    Surface(
        color = MaterialTheme.colorScheme.secondaryContainer,
        shape = MaterialTheme.shapes.medium,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Space.md, vertical = Space.xs)
            .alpha(fade)
            .semantics {
                liveRegion = LiveRegionMode.Polite
                contentDescription = message
            },
    ) {
        Row(
            modifier = Modifier.padding(Space.md),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Space.sm),
        ) {
            Icon(
                imageVector = Icons.Filled.CloudOff,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSecondaryContainer,
                modifier = Modifier.size(Size.icon),
            )
            Text(
                text = message,
                style = DashboardType.body,
                color = MaterialTheme.colorScheme.onSecondaryContainer,
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// METRIC CARD — a self-contained tile. It is ONE tap target to its detail (info states);
// its per-widget state renders inline. The whole card is grouped for the screen reader with a
// coherent name that folds in the trend so it's never color/arrow-only (CRD-001, A11Y-014).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun MetricCard(
    tile: MetricTile,
    reduceMotion: Boolean,
    onOpen: (String) -> Unit,
    onRetry: (String) -> Unit,
    onOpenSettings: () -> Unit,
) {
    // Only tiles that resolve to a value are a single tap-to-detail target; tiles with an inner
    // action (Retry / Settings) leave that button as the target so the two never conflict.
    val canOpen = tile.state is WidgetState.Ideal ||
        tile.state is WidgetState.Success ||
        tile.state is WidgetState.Offline
    val openMod = if (canOpen) {
        Modifier.clickable(onClickLabel = "Open ${tile.title}", role = Role.Button) { onOpen(tile.id) }
    } else {
        Modifier
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Size.cardMinHeight)
            .then(openMod)
            .semantics(mergeDescendants = true) { contentDescription = tileA11y(tile) },
    ) {
        Column(modifier = Modifier.padding(Space.md)) {
            // Header: metric glyph + title (+ stale badge when offline).
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(Space.sm),
            ) {
                Icon(
                    imageVector = tile.icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(Size.icon),
                )
                Text(
                    text = tile.title,
                    style = DashboardType.cardTitle,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.weight(1f),
                )
            }
            Spacer(Modifier.height(Space.sm))

            when (val s = tile.state) {
                WidgetState.Loading -> MetricSkeleton(reduceMotion = reduceMotion)
                WidgetState.Empty -> EmptyState(cta = tile.emptyCta, onCta = { onOpen(tile.id) })
                is WidgetState.Error -> InlineError(message = s.message, onRetry = { onRetry(tile.id) })
                WidgetState.Offline -> MetricValueBlock(value = tile.value, stale = tile.staleLabel)
                WidgetState.Success -> MetricValueBlock(value = tile.value, stale = null)
                WidgetState.PermissionDenied -> PermissionDeniedBlock(onOpenSettings = onOpenSettings)
                WidgetState.Ideal -> MetricValueBlock(value = tile.value, stale = null)
            }
        }
    }
}

/** Coherent, non-color-only accessible name folding in the value + trend text (A11Y-014). */
private fun tileA11y(tile: MetricTile): String {
    val v = tile.value
    val trend = v?.trend?.let { "${directionWord(it.direction)} ${it.text}" }.orEmpty()
    return when (tile.state) {
        WidgetState.Loading -> "${tile.title}, loading"
        WidgetState.Empty -> "${tile.title}, no data yet"
        is WidgetState.Error -> "${tile.title}, couldn't load, retry available"
        WidgetState.Offline -> "${tile.title}, ${v?.display.orEmpty()}, cached, ${tile.staleLabel.orEmpty()}"
        WidgetState.Success -> "${tile.title}, ${v?.display.orEmpty()}, $trend, updated"
        WidgetState.PermissionDenied -> "${tile.title}, permission needed"
        WidgetState.Ideal -> "${tile.title}, ${v?.display.orEmpty()}, $trend"
    }
}

private fun directionWord(direction: TrendDirection): String = when (direction) {
    TrendDirection.Up -> "up"
    TrendDirection.Down -> "down"
    TrendDirection.Flat -> "unchanged"
}

// The value + trend block, shared by Ideal / Success / Offline (Offline adds a stale row).
@Composable
private fun MetricValueBlock(value: MetricValue?, stale: String?) {
    Column {
        Text(
            text = value?.display ?: "—",
            style = DashboardType.value, // tabular figures ('tnum')
            color = MaterialTheme.dashboardColors.onSurfaceStrong,
        )
        val trend = value?.trend
        if (trend != null) {
            Spacer(Modifier.height(Space.xxs))
            TrendRow(trend = trend)
        }
        if (stale != null) {
            Spacer(Modifier.height(Space.xs))
            StaleRow(label = stale)
        }
    }
}

// Trend = icon + SIGN + text, tinted by status — three redundant cues, never color alone.
@Composable
private fun TrendRow(trend: Trend) {
    val colors = MaterialTheme.dashboardColors
    val (icon, sign, color) = when (trend.direction) {
        TrendDirection.Up -> Triple(Icons.Filled.ArrowUpward, "+", colors.statusSuccess)
        TrendDirection.Down -> Triple(Icons.Filled.ArrowDownward, "−", colors.statusError)
        TrendDirection.Flat -> Triple(Icons.Filled.TrendingFlat, "", MaterialTheme.colorScheme.onSurfaceVariant)
    }
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Space.xxs),
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null, // direction is already in the sign + text + merged card name
            tint = color,
            modifier = Modifier.size(Size.trendIcon),
        )
        Text(
            text = "$sign${trend.text}",
            style = DashboardType.trend,
            color = color,
        )
    }
}

// Offline cached-value staleness — an honest "this is not live" cue (STATE-011).
@Composable
private fun StaleRow(label: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Space.xxs),
    ) {
        Icon(
            imageVector = Icons.Filled.CloudOff,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(Size.trendIcon),
        )
        Text(text = label, style = DashboardType.meta, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

// Loading — a shape-matched skeleton (a value block + a trend line), not a global spinner.
// Only opacity pulses; reduce-motion holds it steady (STATE-005, MOT-004).
@Composable
private fun MetricSkeleton(reduceMotion: Boolean) {
    val pulse = if (reduceMotion) {
        1f
    } else {
        val transition = rememberInfiniteTransition(label = "skeleton")
        transition.animateFloat(
            initialValue = 0.4f,
            targetValue = 1f,
            animationSpec = infiniteRepeatable(
                animation = tween(durationMillis = Motion.skeletonMs),
                repeatMode = RepeatMode.Reverse,
            ),
            label = "skeletonPulse",
        ).value
    }
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .alpha(pulse)
            .semantics { contentDescription = "Loading" },
    ) {
        SkeletonBlock(heightToken = Size.skeletonValue, fraction = SKELETON_VALUE_FRACTION)
        Spacer(Modifier.height(Space.sm))
        SkeletonBlock(heightToken = Size.skeletonLabel, fraction = SKELETON_LABEL_FRACTION)
    }
}

@Composable
private fun SkeletonBlock(heightToken: androidx.compose.ui.unit.Dp, fraction: Float) {
    Box(
        modifier = Modifier
            .fillMaxWidth(fraction)
            .height(heightToken)
            .background(
                color = MaterialTheme.colorScheme.surfaceContainerHighest,
                shape = MaterialTheme.shapes.small,
            ),
    )
}

// Empty — first-use, positive framing + a CTA (STATE-002, STATE-003).
@Composable
private fun EmptyState(cta: String?, onCta: () -> Unit) {
    Column {
        Text(
            text = "No data yet",
            style = DashboardType.body,
            color = MaterialTheme.colorScheme.onSurface,
        )
        Text(
            text = "You're all set — it'll appear here once there's activity.",
            style = DashboardType.meta,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        if (cta != null) {
            Spacer(Modifier.height(Space.xs))
            TextButton(
                onClick = onCta,
                modifier = Modifier.heightIn(min = Size.minTarget),
            ) {
                Text(text = cta, style = DashboardType.label)
            }
        }
    }
}

// Error — scoped, inline, with Retry; the rest of the dashboard keeps working (STATE-007, STATE-014).
@Composable
private fun InlineError(message: String, onRetry: () -> Unit) {
    Column {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Space.xs),
        ) {
            Icon(
                imageVector = Icons.Filled.ErrorOutline,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.error,
                modifier = Modifier.size(Size.trendIcon),
            )
            Text(
                text = message,
                style = DashboardType.body,
                color = MaterialTheme.colorScheme.onSurface,
            )
        }
        Spacer(Modifier.height(Space.xs))
        FilledTonalButton(
            onClick = onRetry,
            modifier = Modifier.heightIn(min = Size.minTarget),
        ) {
            Icon(
                imageVector = Icons.Filled.Refresh,
                contentDescription = null,
                modifier = Modifier.size(Size.trendIcon),
            )
            Spacer(Modifier.width(Space.xs))
            Text(text = "Retry", style = DashboardType.label)
        }
    }
}

// Permission-denied — scoped explain + Settings link + a graceful fallback line (STATE-010, PERM-003).
@Composable
private fun PermissionDeniedBlock(onOpenSettings: () -> Unit) {
    Column {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Space.xs),
        ) {
            Icon(
                imageVector = Icons.Filled.Lock,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(Size.trendIcon),
            )
            Text(
                text = "Activity access is off",
                style = DashboardType.body,
                color = MaterialTheme.colorScheme.onSurface,
            )
        }
        Text(
            text = "Turn it on to see steps. Everything else keeps working.",
            style = DashboardType.meta,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(Space.xs))
        OutlinedButton(
            onClick = onOpenSettings,
            modifier = Modifier.heightIn(min = Size.minTarget),
        ) {
            Text(text = "Open Settings", style = DashboardType.label)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHART CARD — a Canvas bar chart, each bar labeled, PLUS a screen-reader DATA-TABLE fallback
// so the numbers are never trapped in pixels (CHT-001, CHT-002). Chart draws in ≤400ms;
// reduce-motion renders the final state instantly.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun ChartCard(chart: ChartData, reduceMotion: Boolean) {
    val locale = LocalConfiguration.current.locales[0]
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(Space.md)) {
            Text(
                text = chart.title,
                style = DashboardType.cardTitle,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.semantics { heading() },
            )
            Spacer(Modifier.height(Space.sm))

            if (chart.state is WidgetState.Loading) {
                SkeletonBlock(heightToken = Size.chartHeight, fraction = SKELETON_FULL_FRACTION)
            } else {
                BarChart(bars = chart.bars, reduceMotion = reduceMotion)
                Spacer(Modifier.height(Space.xs))
                // Visible per-bar labels under the chart.
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    chart.bars.forEach { bar ->
                        Text(text = bar.label, style = DashboardType.meta, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                Spacer(Modifier.height(Space.sm))
                HorizontalDivider()
                Spacer(Modifier.height(Space.sm))
                ChartDataTable(bars = chart.bars, locale = locale)
            }
        }
    }
}

// The pure-Canvas bars. Colors come from the semantic chart series tokens; the chart is
// backed by the data table above, so color is never the only encoding.
@Composable
private fun BarChart(bars: List<ChartBar>, reduceMotion: Boolean) {
    val series = MaterialTheme.dashboardColors.chart
    val track = MaterialTheme.dashboardColors.chartTrack
    val cornerPxProvider = Radius.sm

    var drawn by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { drawn = true }
    val progress by animateFloatAsState(
        targetValue = if (drawn) 1f else 0f,
        animationSpec = if (reduceMotion) snap() else tween(durationMillis = Motion.chartDrawMillis),
        label = "chartDraw",
    )

    val maxValue = bars.maxOfOrNull { it.value } ?: 1.0
    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .height(Size.chartHeight)
            .semantics { contentDescription = "Bar chart. A labeled data table follows." },
    ) {
        val canvasW = size.width
        val canvasH = size.height
        val count = bars.size.coerceAtLeast(1)
        val slot = canvasW / count
        val barW = slot * BAR_FILL_RATIO
        val edge = (slot - barW) / 2f
        val cornerPx = cornerPxProvider.toPx()
        val trackStroke = Space.xxs.toPx()

        // Baseline / track.
        drawLine(
            color = track,
            start = Offset(edge, canvasH),
            end = Offset(canvasW - edge, canvasH),
            strokeWidth = trackStroke,
        )
        bars.forEachIndexed { index, bar ->
            val fraction = (bar.value / maxValue).toFloat() * progress
            val barH = canvasH * fraction
            val startX = slot * index + edge
            val topY = canvasH - barH
            drawRoundRect(
                color = series[index % series.size],
                topLeft = Offset(startX, topY),
                size = CanvasSize(barW, barH),
                cornerRadius = CornerRadius(cornerPx, cornerPx),
            )
        }
    }
}

// DATA-TABLE FALLBACK — real Text rows, each an accessible pair, reachable by TalkBack (CHT-002).
@Composable
private fun ChartDataTable(bars: List<ChartBar>, locale: Locale) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = "Data table",
            style = DashboardType.label,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.semantics { heading() },
        )
        Spacer(Modifier.height(Space.xs))
        bars.forEach { bar ->
            val amount = currencyOf((bar.value * 100).toLong(), locale)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = Space.xxs)
                    .semantics(mergeDescendants = true) { contentDescription = "${bar.label}, $amount" },
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(text = bar.label, style = DashboardType.body, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(
                    text = amount,
                    style = DashboardType.amount, // tabular figures, end-aligned so the column mirrors in RTL
                    color = MaterialTheme.colorScheme.onSurface,
                    textAlign = TextAlign.End,
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY CARD — the recent-activity feed. Its own state: rows, a skeleton, or a friendly empty.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun ActivityCard(feed: ActivityFeed) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(Space.md)) {
            Text(
                text = "Recent activity",
                style = DashboardType.cardTitle,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.semantics { heading() },
            )
            Spacer(Modifier.height(Space.sm))
            when (feed.state) {
                WidgetState.Loading -> {
                    repeat(3) {
                        SkeletonBlock(heightToken = Size.skeletonRow, fraction = SKELETON_FULL_FRACTION)
                        Spacer(Modifier.height(Space.sm))
                    }
                }
                WidgetState.Empty -> {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(Space.sm),
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Inbox,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(Size.icon),
                        )
                        Text(
                            text = "Nothing here yet — recent activity will show up here.",
                            style = DashboardType.body,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
                else -> {
                    feed.items.forEachIndexed { index, item ->
                        ActivityRow(item = item)
                        if (index < feed.items.lastIndex) {
                            HorizontalDivider(modifier = Modifier.padding(vertical = Space.sm))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ActivityRow(item: ActivityItem) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) { contentDescription = "${item.title}, ${item.meta}" },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Space.sm),
    ) {
        Text(
            text = item.title,
            style = DashboardType.body,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f),
        )
        Text(
            text = item.meta,
            style = DashboardType.meta,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.End,
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAVIGATION — bottom bar on compact, side rail on medium / expanded (NAV-001, NAV-003).
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun DashboardNavBar(destinations: List<NavDestination>, selected: Int, onSelect: (Int) -> Unit) {
    NavigationBar {
        destinations.forEachIndexed { index, dest ->
            NavigationBarItem(
                selected = index == selected,
                onClick = { onSelect(index) },
                icon = { Icon(imageVector = dest.icon, contentDescription = null) },
                label = { Text(text = dest.label, style = DashboardType.meta) },
            )
        }
    }
}

@Composable
private fun DashboardNavRail(destinations: List<NavDestination>, selected: Int, onSelect: (Int) -> Unit) {
    NavigationRail {
        destinations.forEachIndexed { index, dest ->
            NavigationRailItem(
                selected = index == selected,
                onClick = { onSelect(index) },
                icon = { Icon(imageVector = dest.icon, contentDescription = null) },
                label = { Text(text = dest.label, style = DashboardType.meta) },
            )
        }
    }
}

// Tuning ratios for the Canvas + skeleton widths (fractions of the available measure — not dp).
private const val BAR_FILL_RATIO = 0.62f
private const val SKELETON_VALUE_FRACTION = 0.6f
private const val SKELETON_LABEL_FRACTION = 0.4f
private const val SKELETON_FULL_FRACTION = 1f

// ─────────────────────────────────────────────────────────────────────────────
// Host Activity — edge-to-edge is enabled here; the composable inherits the insets.
// ─────────────────────────────────────────────────────────────────────────────
class DashboardActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            DashboardTheme {
                DashboardScreen(onOpenMetric = { /* navigate to the metric's detail */ })
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Previews — the state matrix + the responsive reflow, inspectable at a glance.
// ─────────────────────────────────────────────────────────────────────────────
@Composable
private fun PreviewHost(state: DashboardUiState) = DashboardTheme {
    DashboardScreenContent(
        state = state,
        onRefresh = {}, onRetryTile = {}, onSelectDestination = {},
        onOpenMetric = {}, onOpenSettings = {},
    )
}

@Preview(name = "Dashboard — compact (1 col + nav bar)", widthDp = 400, heightDp = 900, showBackground = true)
@Composable
private fun DashboardCompactPreview() = PreviewHost(DashboardUiState())

@Preview(name = "Dashboard — medium (2 col + rail)", widthDp = 720, heightDp = 900, showBackground = true)
@Composable
private fun DashboardMediumPreview() = PreviewHost(DashboardUiState())

@Preview(name = "Dashboard — expanded (3–4 col + rail)", widthDp = 1280, heightDp = 900, showBackground = true)
@Composable
private fun DashboardExpandedPreview() = PreviewHost(DashboardUiState())

@Preview(name = "Dashboard — offline (banner + cached tiles)", widthDp = 400, heightDp = 900, showBackground = true)
@Composable
private fun DashboardOfflinePreview() =
    PreviewHost(DashboardUiState(isOffline = true))

@Preview(name = "Dashboard — refreshed (Updated announced)", widthDp = 400, heightDp = 900, showBackground = true)
@Composable
private fun DashboardUpdatedPreview() =
    PreviewHost(DashboardUiState(justUpdated = true, lastUpdatedLabel = "just now"))
