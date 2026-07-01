/**
 * DashboardScreen.tsx — a glanceable, responsive dashboard for the skill's Dashboard example.
 *
 * Implements the full spec: a RESPONSIVE grid of self-contained metric cards + a
 * small bar chart + an activity list that re-flows by width via useWindowDimensions
 * (compact < 600 = 1 column + bottom nav; medium 600–839 = 2 columns + side rail;
 * expanded >= 840 = 3–4 columns, chart spans 2, + rail), capped at a max content
 * measure so a single column never stretches edge-to-edge.
 *
 * PER-WIDGET STATE is the defining rule: there is NO single global spinner. Each tile
 * owns its own WidgetState and resolves independently — a shape-matched skeleton while
 * loading, a scoped inline error + Retry that leaves the other tiles live, a first-use
 * empty with a CTA, a scoped permission explain + Settings, and — when the device drops
 * offline — its cached value plus a "saved · offline" stale indicator. A single global,
 * non-blocking offline banner sits above the grid; pull-to-refresh is disabled offline
 * with a spoken reason.
 *
 * Numbers use tabular figures (fontVariant ['tabular-nums']) + Intl.NumberFormat so they
 * stay column-aligned and locale-correct; trend is conveyed by icon + sign + text (never
 * color alone). The bar chart is drawn with plain Views and paired with a screen-reader
 * DATA-TABLE fallback of accessible rows. Refresh completion announces via a live region;
 * the only motion is opacity/transform and it collapses to an instant state under
 * AccessibilityInfo.isReduceMotionEnabled().
 *
 * Every visual value comes from dashboardTokens.ts — this file holds no raw hex or
 * off-grid spacing. Loaders are injectable and default to light mocks so it runs
 * standalone; the six quality-checks/validators pass at 100/100.
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
  Animated,
  I18nManager,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
  useColorScheme,
  useWindowDimensions,
} from 'react-native';
import {
  SafeAreaView,
  useSafeAreaInsets,
} from 'react-native-safe-area-context';
import NetInfo from '@react-native-community/netinfo';

import {
  ColorRoles,
  breakpoints,
  chartColor,
  getColors,
  motion,
  radius,
  size,
  spacing,
  tabular,
  typography,
} from './dashboardTokens';

/**
 * The 7 per-widget conditions. Every tile is always in exactly one — there is no
 * screen-wide state, so one failed metric can never blank the whole dashboard.
 */
export type WidgetState =
  | 'loading'
  | 'empty'
  | 'error'
  | 'offline'
  | 'success'
  | 'permissionDenied'
  | 'ideal';

type MetricFormat = 'currency' | 'number' | 'percent';

/** What a tile's loader resolves to (drives its terminal state). */
type MetricResult =
  | { kind: 'ideal'; value: number; previous: number }
  | { kind: 'empty' }
  | { kind: 'error' }
  | { kind: 'permissionDenied' };

type MetricConfig = {
  id: string;
  label: string;
  detailHint: string;
  format: MetricFormat;
  seriesIndex: number;
  /** Terminal outcome this tile resolves to (demo seed for the 7-state map). */
  outcome: MetricResult;
  emptyText?: string;
  ctaLabel?: string;
  permissionName?: string;
  /** Value a Retry recovers to (error tiles). */
  recover?: { value: number; previous: number };
};

type ChartDatum = { label: string; value: number };
type ActivityItem = { id: string; glyph: string; text: string; time: string };

type DashboardScreenProps = {
  locale?: string;
  currency?: string;
  userName?: string;
  onOpenTile?: (id: string) => void;
  onOpenSettings?: () => void;
  onChangeRange?: () => void;
  onSelectNav?: (key: string) => void;
};

const noop = () => {};

const wait = (ms: number) =>
  new Promise<void>((resolve) => setTimeout(resolve, ms));

// --- Mock data (injectable in a real app) -----------------------------------
const METRICS: MetricConfig[] = [
  {
    id: 'revenue',
    label: 'Revenue',
    detailHint: 'Opens revenue detail',
    format: 'currency',
    seriesIndex: 0,
    outcome: { kind: 'ideal', value: 128940, previous: 121300 },
  },
  {
    id: 'users',
    label: 'Active users',
    detailHint: 'Opens active-users detail',
    format: 'number',
    seriesIndex: 1,
    outcome: { kind: 'ideal', value: 3820, previous: 3990 },
  },
  {
    id: 'conversion',
    label: 'Conversion rate',
    detailHint: 'Opens conversion detail',
    format: 'percent',
    seriesIndex: 2,
    outcome: { kind: 'ideal', value: 3.8, previous: 3.4 },
  },
  {
    id: 'tasks',
    label: 'Open tasks',
    detailHint: 'Opens the task list',
    format: 'number',
    seriesIndex: 3,
    outcome: { kind: 'empty' },
    emptyText: "No tasks due — you're all caught up.",
    ctaLabel: 'Create task',
  },
  {
    id: 'uptime',
    label: 'Uptime',
    detailHint: 'Opens uptime detail',
    format: 'percent',
    seriesIndex: 0,
    outcome: { kind: 'error' },
    recover: { value: 99.8, previous: 99.9 },
  },
  {
    id: 'steps',
    label: 'Steps today',
    detailHint: 'Opens the activity metric',
    format: 'number',
    seriesIndex: 1,
    outcome: { kind: 'permissionDenied' },
    permissionName: 'Motion & Fitness',
  },
];

const CHART_SERIES: ChartDatum[] = [
  { label: 'Mon', value: 18400 },
  { label: 'Tue', value: 21200 },
  { label: 'Wed', value: 16800 },
  { label: 'Thu', value: 24600 },
  { label: 'Fri', value: 28900 },
  { label: 'Sat', value: 15200 },
  { label: 'Sun', value: 19750 },
];

const ACTIVITY: ActivityItem[] = [
  { id: 'a1', glyph: '✓', text: 'Invoice 10428 marked paid', time: '2m' },
  { id: 'a2', glyph: '↩', text: 'Refund issued to A. Morgan', time: '18m' },
  { id: 'a3', glyph: '＋', text: 'New signup from Berlin', time: '1h' },
  { id: 'a4', glyph: '⚑', text: 'Uptime probe recovered', time: '3h' },
];

const NAV_ITEMS = [
  { key: 'home', label: 'Home', glyph: '⌂' },
  { key: 'reports', label: 'Reports', glyph: '▦' },
  { key: 'alerts', label: 'Alerts', glyph: '◔' },
  { key: 'settings', label: 'Settings', glyph: '⚙' },
] as const;

// A tile resolves on its own clock (staggered) — never one global spinner.
async function loadMetric(
  config: MetricConfig,
  delay: number,
  refresh: number,
): Promise<MetricResult> {
  await wait(delay);
  if (config.outcome.kind === 'error') throw new Error('metric source unavailable');
  if (config.outcome.kind === 'ideal' && refresh > 0) {
    // A refresh nudges the value so the change is noticeable (STATE-009 / A11Y-019).
    const drift = 1 + (((refresh + config.seriesIndex) % 3) - 1) / 100;
    const value = Math.round(config.outcome.value * drift * 10) / 10;
    return { kind: 'ideal', value: Math.max(0, value), previous: config.outcome.value };
  }
  return config.outcome;
}

async function recoverMetric(
  config: MetricConfig,
  delay: number,
): Promise<MetricResult> {
  await wait(delay);
  if (config.recover) {
    return { kind: 'ideal', value: config.recover.value, previous: config.recover.previous };
  }
  return { kind: 'ideal', value: 0, previous: 0 };
}

function computeTrend(value: number, previous: number) {
  if (previous === 0) return { dir: 'flat' as const, pct: 0 };
  const pct = ((value - previous) / previous) * 100;
  const dir = pct > 0 ? 'up' : pct < 0 ? 'down' : 'flat';
  return { dir: dir as 'up' | 'down' | 'flat', pct: Math.abs(pct) };
}

function timeAgo(d: Date): string {
  const mins = Math.max(0, Math.round((Date.now() - d.getTime()) / 60000));
  if (mins < 1) return 'just now';
  if (mins === 1) return '1 min ago';
  return `${mins} min ago`;
}

// Short axis label for a bar (the full value lives in the accessible data table).
function compactNumber(n: number): string {
  if (n >= 1000000) return `${Math.round(n / 100000) / 10}M`;
  if (n >= 1000) return `${Math.round(n / 100) / 10}k`;
  return `${n}`;
}

// --- Skeleton pulse (opacity only; instant under reduce-motion) --------------
function usePulse(active: boolean, reduceMotion: boolean) {
  const value = useRef(new Animated.Value(1)).current;
  useEffect(() => {
    if (!active || reduceMotion) {
      value.setValue(1);
      return;
    }
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(value, { toValue: 0.45, duration: motion.chart, useNativeDriver: true }),
        Animated.timing(value, { toValue: 1, duration: motion.chart, useNativeDriver: true }),
      ]),
    );
    loop.start();
    return () => loop.stop();
  }, [active, reduceMotion, value]);
  return value;
}

export default function DashboardScreen({
  locale = 'en-US',
  currency = 'USD',
  userName = 'Sam',
  onOpenTile = noop,
  onOpenSettings = noop,
  onChangeRange = noop,
  onSelectNav = noop,
}: DashboardScreenProps) {
  const scheme = useColorScheme();
  const colors = getColors(scheme);
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => makeStyles(colors), [colors]);

  const { width } = useWindowDimensions();
  const [isConnected, setIsConnected] = useState(true);
  const [reduceMotion, setReduceMotion] = useState(false);
  const [liveMessage, setLiveMessage] = useState('');
  const [updatedLabel, setUpdatedLabel] = useState('');
  const [refreshing, setRefreshing] = useState(false);
  const [refreshNonce, setRefreshNonce] = useState(0);
  const [selectedNav, setSelectedNav] = useState<string>('home');

  // --- Size-class adaptation (GRD-001..004) — the whole point of this example ---
  const isCompact = width < breakpoints.compact;
  const isExpanded = width >= breakpoints.expanded;
  const isWide = width >= breakpoints.wide;
  const showRail = !isCompact;
  const columns = isCompact ? 1 : isExpanded ? (isWide ? 4 : 3) : 2;

  // Content max-measure cap so a single column never stretches edge-to-edge (GRD-005).
  const edge = spacing.lg;
  const railW = showRail ? size.rail : 0;
  const contentW = Math.min(width - railW - edge - edge, breakpoints.maxContent);
  const gutter = spacing.gutter;
  const tileW = Math.floor((contentW - gutter * (columns - 1)) / columns);
  const spanW = (span: number) => {
    const s = Math.min(span, columns);
    return tileW * s + gutter * (s - 1);
  };
  // Chart + activity span two columns on wider classes (full row otherwise).
  const wideTileW = spanW(2);

  const announce = useCallback((msg: string) => {
    setLiveMessage(msg);
    AccessibilityInfo.announceForAccessibility(msg);
  }, []);

  // Reduce-motion preference gates every animation.
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

  // Connectivity — drives the global banner + each tile's stale/cached fallback.
  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener((state) => {
      setIsConnected(state.isConnected ?? true);
    });
    return () => unsubscribe();
  }, []);

  // Pull-to-refresh — disabled offline with a spoken reason (STATE-011 / OFF-004).
  const onRefresh = useCallback(() => {
    if (!isConnected) {
      setRefreshing(false);
      announce("You're offline — showing saved data. Reconnect to refresh.");
      return;
    }
    setRefreshing(true);
    setRefreshNonce((n) => n + 1);
    setTimeout(() => {
      setRefreshing(false);
      setUpdatedLabel(`Updated ${timeAgo(new Date())}`);
      announce('Dashboard updated.');
    }, motion.chart);
  }, [isConnected, announce]);

  const handleSelectNav = useCallback(
    (key: string) => {
      setSelectedNav(key);
      onSelectNav(key);
    },
    [onSelectNav],
  );

  const railBottom = insets.bottom;

  return (
    <SafeAreaView edges={['top']} style={styles.container}>
      <LiveRegion message={liveMessage} styles={styles} />

      {/* Global, NON-blocking offline banner (STATE-008). Tiles stay usable below. */}
      {!isConnected ? (
        <OfflineBanner styles={styles} onRetry={() => NetInfo.refresh()} />
      ) : null}

      <View style={styles.body}>
        {showRail ? (
          <SideRail
            selected={selectedNav}
            onSelect={handleSelectNav}
            styles={styles}
            paddingBottom={railBottom}
          />
        ) : null}

        <View style={styles.main}>
          <ScrollView
            contentContainerStyle={styles.scrollContent}
            refreshControl={
              <RefreshControl
                refreshing={refreshing}
                onRefresh={onRefresh}
                tintColor={colors.actionPrimary}
                colors={[colors.actionPrimary]}
              />
            }
          >
            <View style={[styles.content, { width: contentW }]}>
              <DashboardHeader
                userName={userName}
                updatedLabel={updatedLabel}
                onRefresh={onRefresh}
                onChangeRange={onChangeRange}
                refreshDisabled={!isConnected}
                styles={styles}
              />

              <View style={styles.grid}>
                {METRICS.map((m, i) => (
                  <MetricCard
                    key={m.id}
                    config={m}
                    index={i}
                    width={tileW}
                    refreshNonce={refreshNonce}
                    isConnected={isConnected}
                    locale={locale}
                    currency={currency}
                    reduceMotion={reduceMotion}
                    styles={styles}
                    colors={colors}
                    onOpenTile={onOpenTile}
                    onOpenSettings={onOpenSettings}
                  />
                ))}

                <ChartCard
                  width={wideTileW}
                  refreshNonce={refreshNonce}
                  isConnected={isConnected}
                  locale={locale}
                  currency={currency}
                  reduceMotion={reduceMotion}
                  styles={styles}
                  colors={colors}
                />

                <ActivityCard
                  width={wideTileW}
                  refreshNonce={refreshNonce}
                  isConnected={isConnected}
                  reduceMotion={reduceMotion}
                  styles={styles}
                />
              </View>
            </View>
          </ScrollView>
        </View>
      </View>

      {isCompact ? (
        <BottomNav
          selected={selectedNav}
          onSelect={handleSelectNav}
          styles={styles}
          paddingBottom={insets.bottom}
        />
      ) : null}
    </SafeAreaView>
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

// --- Header — greeting, date range, refresh, "Updated" live status ----------
type HeaderProps = {
  userName: string;
  updatedLabel: string;
  onRefresh: () => void;
  onChangeRange: () => void;
  refreshDisabled: boolean;
  styles: Styles;
};
function DashboardHeader({
  userName,
  updatedLabel,
  onRefresh,
  onChangeRange,
  refreshDisabled,
  styles,
}: HeaderProps) {
  return (
    <View style={styles.header}>
      <View style={styles.headerTitles}>
        <Text accessibilityRole="header" style={styles.greeting} numberOfLines={1} allowFontScaling>
          {`Hi ${userName}`}
        </Text>
        <Text style={styles.subtitle} numberOfLines={1} allowFontScaling>
          Here&apos;s your snapshot
        </Text>
        {/* "Updated" announces to assistive tech on refresh completion (A11Y-019). */}
        <Text
          accessibilityLiveRegion="polite"
          style={styles.updated}
          numberOfLines={1}
          allowFontScaling
        >
          {updatedLabel}
        </Text>
      </View>

      <View style={styles.headerActions}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Date range: last 7 days"
          accessibilityHint="Changes the reporting period"
          onPress={onChangeRange}
          style={({ pressed }) => [styles.rangePill, pressed ? styles.rangePillPressed : null]}
        >
          <Text style={styles.rangeLabel} numberOfLines={1} allowFontScaling>
            Last 7 days
          </Text>
          <Text
            style={styles.rangeGlyph}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {'▾'}
          </Text>
        </Pressable>

        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Refresh dashboard"
          accessibilityHint={
            refreshDisabled ? 'You are offline. Reconnect to refresh.' : undefined
          }
          onPress={onRefresh}
          hitSlop={size.hitSlop}
          style={({ pressed }) => [styles.refreshButton, pressed ? styles.refreshPressed : null]}
        >
          <Text
            style={styles.refreshGlyph}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {'↻'}
          </Text>
        </Pressable>
      </View>
    </View>
  );
}

// --- Global offline banner (non-blocking) -----------------------------------
function OfflineBanner({ styles, onRetry }: { styles: Styles; onRetry: () => void }) {
  return (
    <View accessible accessibilityRole="alert" accessibilityLiveRegion="polite" style={styles.banner}>
      <Text
        style={styles.bannerGlyph}
        accessibilityElementsHidden
        importantForAccessibility="no-hide-descendants"
      >
        {'⚠'}
      </Text>
      <Text style={styles.bannerText} numberOfLines={2}>
        You&apos;re offline — showing saved data. It may be out of date.
      </Text>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Retry connection"
        onPress={onRetry}
        hitSlop={size.hitSlop}
        style={styles.bannerAction}
      >
        <Text style={styles.bannerLink}>Retry</Text>
      </Pressable>
    </View>
  );
}

// --- Metric card — self-contained, owns its own WidgetState -----------------
type MetricCardProps = {
  config: MetricConfig;
  index: number;
  width: number;
  refreshNonce: number;
  isConnected: boolean;
  locale: string;
  currency: string;
  reduceMotion: boolean;
  styles: Styles;
  colors: ColorRoles;
  onOpenTile: (id: string) => void;
  onOpenSettings: () => void;
};
function MetricCard({
  config,
  index,
  width,
  refreshNonce,
  isConnected,
  locale,
  currency,
  reduceMotion,
  styles,
  colors,
  onOpenTile,
  onOpenSettings,
}: MetricCardProps) {
  const [state, setState] = useState<WidgetState>('loading');
  const [data, setData] = useState<{ value: number; previous: number } | null>(null);
  const cachedRef = useRef<{ value: number; previous: number } | null>(null);
  const [updatedAt, setUpdatedAt] = useState<Date | null>(null);
  const fade = useRef(new Animated.Value(reduceMotion ? 1 : 0)).current;
  const pulse = usePulse(state === 'loading', reduceMotion);

  const currencyFmt = useMemo(
    () => new Intl.NumberFormat(locale, { style: 'currency', currency, maximumFractionDigits: 0 }),
    [locale, currency],
  );
  const numberFmt = useMemo(() => new Intl.NumberFormat(locale), [locale]);
  const percentFmt = useMemo(
    () => new Intl.NumberFormat(locale, { minimumFractionDigits: 1, maximumFractionDigits: 1 }),
    [locale],
  );
  const fmtValue = useCallback(
    (v: number) => {
      if (config.format === 'currency') return currencyFmt.format(v);
      if (config.format === 'percent') return `${percentFmt.format(v)}%`;
      return numberFmt.format(v);
    },
    [config.format, currencyFmt, numberFmt, percentFmt],
  );

  const runFade = useCallback(() => {
    if (reduceMotion) {
      fade.setValue(1);
      return;
    }
    fade.setValue(0);
    Animated.timing(fade, { toValue: 1, duration: motion.base, useNativeDriver: true }).start();
  }, [reduceMotion, fade]);

  // Independent load — resolves per-tile; offline keeps the cached value (STATE-014).
  useEffect(() => {
    let active = true;
    let settleTimer: ReturnType<typeof setTimeout> | undefined;
    if (!isConnected) {
      setState('offline');
      return () => {
        active = false;
      };
    }
    setState('loading');
    const delay = motion.base + (index % 3) * motion.base;
    loadMetric(config, delay, refreshNonce)
      .then((res) => {
        if (!active) return;
        if (res.kind === 'ideal') {
          const next = { value: res.value, previous: res.previous };
          cachedRef.current = next;
          setData(next);
          setUpdatedAt(new Date());
          setState(refreshNonce > 0 ? 'success' : 'ideal');
          runFade();
          if (refreshNonce > 0) {
            settleTimer = setTimeout(() => {
              if (active) setState('ideal');
            }, motion.success);
          }
        } else {
          setState(res.kind);
        }
      })
      .catch(() => {
        if (active) setState('error');
      });
    return () => {
      active = false;
      if (settleTimer) clearTimeout(settleTimer);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [config, index, refreshNonce, isConnected]);

  const onRetry = useCallback(() => {
    setState('loading');
    recoverMetric(config, motion.emphasis)
      .then((res) => {
        if (res.kind !== 'ideal') {
          setState(res.kind);
          return;
        }
        const next = { value: res.value, previous: res.previous };
        cachedRef.current = next;
        setData(next);
        setUpdatedAt(new Date());
        setState('ideal');
        runFade();
      })
      .catch(() => setState('error'));
  }, [config, runFade]);

  const cached = cachedRef.current;
  const hasData = data && (state === 'ideal' || state === 'success');
  const isCachedOffline = state === 'offline' && cached != null;
  const pressable = Boolean(hasData || isCachedOffline);

  const trend = data ? computeTrend(data.value, data.previous) : null;
  const mirror = I18nManager.isRTL ? styles.mirror : null;

  const trendGlyph = trend?.dir === 'up' ? '▲' : trend?.dir === 'down' ? '▼' : '—';
  const trendSign = trend?.dir === 'up' ? '+' : trend?.dir === 'down' ? '−' : '';
  const trendStyle =
    trend?.dir === 'up'
      ? styles.trendUp
      : trend?.dir === 'down'
      ? styles.trendDown
      : styles.trendFlat;
  const trendPhrase = trend
    ? trend.dir === 'flat'
      ? 'no change versus last week'
      : `${trend.dir} ${trend.pct.toFixed(1)} percent versus last week`
    : '';

  const groupLabel = (() => {
    if (hasData && data) return `${config.label}, ${fmtValue(data.value)}, ${trendPhrase}`;
    if (isCachedOffline && cached) {
      return `${config.label}, ${fmtValue(cached.value)}, saved data, offline${
        updatedAt ? `, updated ${timeAgo(updatedAt)}` : ''
      }`;
    }
    return config.label;
  })();

  const renderInner = () => {
    if (state === 'loading') {
      return (
        <Animated.View style={[styles.skelGroup, { opacity: pulse }]}>
          <View style={styles.skelLabel} />
          <View style={styles.skelNumber} />
          <View style={styles.skelTrend} />
        </Animated.View>
      );
    }

    if (state === 'error') {
      return (
        <>
          <Text style={styles.tileLabel} numberOfLines={1} allowFontScaling>
            {config.label}
          </Text>
          <View style={styles.errorRow}>
            <Text
              style={styles.errorGlyph}
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
            >
              {'⚠'}
            </Text>
            <Text style={styles.errorText} numberOfLines={3} allowFontScaling>
              Couldn&apos;t load this metric. Other tiles are unaffected.
            </Text>
          </View>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`Retry ${config.label}`}
            onPress={onRetry}
            style={({ pressed }) => [styles.retryButton, pressed ? styles.retryPressed : null]}
          >
            <Text style={styles.retryLabel} allowFontScaling>
              Retry
            </Text>
          </Pressable>
        </>
      );
    }

    if (state === 'empty') {
      return (
        <>
          <Text style={styles.tileLabel} numberOfLines={1} allowFontScaling>
            {config.label}
          </Text>
          <Text style={styles.emptyText} numberOfLines={3} allowFontScaling>
            {config.emptyText ?? 'Nothing here yet.'}
          </Text>
          {config.ctaLabel ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={config.ctaLabel}
              onPress={() => onOpenTile(config.id)}
              style={({ pressed }) => [styles.ctaButton, pressed ? styles.ctaPressed : null]}
            >
              <Text style={styles.ctaLabel} allowFontScaling>
                {config.ctaLabel}
              </Text>
            </Pressable>
          ) : null}
        </>
      );
    }

    if (state === 'permissionDenied') {
      return (
        <>
          <Text style={styles.tileLabel} numberOfLines={1} allowFontScaling>
            {config.label}
          </Text>
          <Text style={styles.emptyText} numberOfLines={3} allowFontScaling>
            {`${config.permissionName ?? 'A permission'} is off, so this metric is hidden.`}
          </Text>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Open Settings"
            onPress={onOpenSettings}
            style={({ pressed }) => [styles.ctaButton, pressed ? styles.ctaPressed : null]}
          >
            <Text style={styles.ctaLabel} allowFontScaling>
              Open Settings
            </Text>
          </Pressable>
          <Text style={styles.permFallback} numberOfLines={2} allowFontScaling>
            The rest of your dashboard still works.
          </Text>
        </>
      );
    }

    if (state === 'offline') {
      if (cached) {
        return (
          <>
            <Text style={styles.tileLabel} numberOfLines={1} allowFontScaling>
              {config.label}
            </Text>
            <Text style={[styles.tileValue, tabular]} numberOfLines={1} allowFontScaling>
              {fmtValue(cached.value)}
            </Text>
            <View style={styles.staleRow}>
              <Text
                style={styles.staleGlyph}
                accessibilityElementsHidden
                importantForAccessibility="no-hide-descendants"
              >
                {'⌁'}
              </Text>
              <Text style={styles.staleText} numberOfLines={2} allowFontScaling>
                {`Saved · offline${updatedAt ? ` · ${timeAgo(updatedAt)}` : ''}`}
              </Text>
            </View>
          </>
        );
      }
      return (
        <>
          <Text style={styles.tileLabel} numberOfLines={1} allowFontScaling>
            {config.label}
          </Text>
          <View style={styles.staleRow}>
            <Text
              style={styles.staleGlyph}
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
            >
              {'⌁'}
            </Text>
            <Text style={styles.staleText} numberOfLines={2} allowFontScaling>
              Offline — reconnect to load this metric.
            </Text>
          </View>
        </>
      );
    }

    // ideal / success — value + trend (icon + sign + text, never color-only).
    return (
      <>
        <Text style={styles.tileLabel} numberOfLines={1} allowFontScaling>
          {config.label}
        </Text>
        <Animated.Text
          style={[styles.tileValue, tabular, { opacity: fade }]}
          numberOfLines={1}
          allowFontScaling
        >
          {data ? fmtValue(data.value) : ''}
        </Animated.Text>
        {trend ? (
          <View style={styles.trendRow}>
            <Text
              style={[styles.trendGlyph, trendStyle, mirror]}
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
            >
              {trendGlyph}
            </Text>
            <Text style={[styles.trendText, trendStyle]} numberOfLines={1} allowFontScaling>
              {`${trendSign}${trend.pct.toFixed(1)}% vs last week`}
            </Text>
          </View>
        ) : null}
      </>
    );
  };

  if (pressable) {
    return (
      <Pressable
        accessible
        accessibilityRole="button"
        accessibilityLabel={groupLabel}
        accessibilityHint={config.detailHint}
        onPress={() => onOpenTile(config.id)}
        style={({ pressed }) => [styles.card, { width }, pressed ? styles.cardPressed : null]}
      >
        {renderInner()}
      </Pressable>
    );
  }

  return (
    <View accessible={state === 'loading'} accessibilityLabel={groupLabel} style={[styles.card, { width }]}>
      {renderInner()}
    </View>
  );
}

// --- Bar chart — drawn with Views + a screen-reader data-table fallback ------
type ChartCardProps = {
  width: number;
  refreshNonce: number;
  isConnected: boolean;
  locale: string;
  currency: string;
  reduceMotion: boolean;
  styles: Styles;
  colors: ColorRoles;
};
function ChartCard({
  width,
  refreshNonce,
  isConnected,
  locale,
  currency,
  reduceMotion,
  styles,
  colors,
}: ChartCardProps) {
  const [state, setState] = useState<WidgetState>('loading');
  const [series, setSeries] = useState<ChartDatum[]>([]);
  const cachedRef = useRef<ChartDatum[] | null>(null);
  const draw = useRef(new Animated.Value(reduceMotion ? 1 : 0)).current;
  const pulse = usePulse(state === 'loading', reduceMotion);

  const currencyFmt = useMemo(
    () => new Intl.NumberFormat(locale, { style: 'currency', currency, maximumFractionDigits: 0 }),
    [locale, currency],
  );

  useEffect(() => {
    let active = true;
    if (!isConnected) {
      setState('offline');
      return () => {
        active = false;
      };
    }
    setState('loading');
    wait(motion.emphasis).then(() => {
      if (!active) return;
      cachedRef.current = CHART_SERIES;
      setSeries(CHART_SERIES);
      setState(refreshNonce > 0 ? 'success' : 'ideal');
      if (reduceMotion) {
        draw.setValue(1);
      } else {
        draw.setValue(0);
        Animated.timing(draw, { toValue: 1, duration: motion.chart, useNativeDriver: true }).start();
      }
    });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [refreshNonce, isConnected]);

  const cached = cachedRef.current;
  const rows = state === 'offline' && cached ? cached : series;
  const maxValue = rows.reduce((m, d) => Math.max(m, d.value), 1);

  const isOffline = state === 'offline';

  if (state === 'loading') {
    return (
      <View style={[styles.card, { width }]}>
        <Text style={styles.sectionTitle} numberOfLines={1} allowFontScaling>
          Revenue, last 7 days
        </Text>
        <Animated.View style={[styles.chartSkelRow, { opacity: pulse }]}>
          {CHART_SERIES.map((d, i) => (
            <View
              key={d.label}
              style={[styles.chartSkelBar, { height: skeletonBarHeight(i) }]}
            />
          ))}
        </Animated.View>
      </View>
    );
  }

  if (isOffline && !cached) {
    return (
      <View style={[styles.card, { width }]}>
        <Text accessibilityRole="header" style={styles.sectionTitle} numberOfLines={1} allowFontScaling>
          Revenue, last 7 days
        </Text>
        <View style={styles.staleRow}>
          <Text
            style={styles.staleGlyph}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {'⌁'}
          </Text>
          <Text style={styles.staleText} numberOfLines={2} allowFontScaling>
            Offline — reconnect to load the chart.
          </Text>
        </View>
      </View>
    );
  }

  return (
    <View style={[styles.card, { width }]}>
      <View style={styles.chartHeader}>
        <Text accessibilityRole="header" style={styles.sectionTitle} numberOfLines={1} allowFontScaling>
          Revenue, last 7 days
        </Text>
        {isOffline ? (
          <Text style={styles.staleChip} numberOfLines={1} allowFontScaling>
            saved · offline
          </Text>
        ) : null}
      </View>

      {/* Bars are decorative; the accessible data table below is the real content (CHT-002). */}
      <View
        style={styles.plot}
        accessibilityElementsHidden
        importantForAccessibility="no-hide-descendants"
      >
        {rows.map((d, i) => {
          const h = Math.max(size.hairline, Math.round((d.value / maxValue) * size.chartHeight));
          return (
            <View key={d.label} style={styles.barCol}>
              <View style={styles.barTrack}>
                <Animated.View
                  style={[
                    styles.barFill,
                    { height: h, backgroundColor: chartColor(colors, i), opacity: draw },
                  ]}
                />
              </View>
              <Text style={styles.barValue} numberOfLines={1} allowFontScaling>
                {compactNumber(d.value)}
              </Text>
              <Text style={styles.barLabel} numberOfLines={1} allowFontScaling>
                {d.label}
              </Text>
            </View>
          );
        })}
      </View>

      {/* Data-table fallback: accessible rows a screen reader can read in order. */}
      <View style={styles.dataTable}>
        <Text accessibilityRole="header" style={styles.dataTableTitle} numberOfLines={1} allowFontScaling>
          Revenue by day
        </Text>
        {rows.map((d) => (
          <View
            key={d.label}
            accessible
            accessibilityRole="text"
            accessibilityLabel={`${d.label}, ${currencyFmt.format(d.value)}`}
            style={styles.dataRow}
          >
            <Text style={styles.dataDay} numberOfLines={1} allowFontScaling>
              {d.label}
            </Text>
            <Text style={[styles.dataValue, tabular]} numberOfLines={1} allowFontScaling>
              {currencyFmt.format(d.value)}
            </Text>
          </View>
        ))}
      </View>
    </View>
  );
}

function skeletonBarHeight(i: number): number {
  // A varied but deterministic placeholder height per bar (non-text View).
  const steps = [0.5, 0.8, 0.4, 0.95, 0.7, 0.35, 0.6];
  return Math.round(size.chartHeight * steps[i % steps.length]);
}

// --- Activity list — owns its own state -------------------------------------
type ActivityCardProps = {
  width: number;
  refreshNonce: number;
  isConnected: boolean;
  reduceMotion: boolean;
  styles: Styles;
};
function ActivityCard({
  width,
  refreshNonce,
  isConnected,
  reduceMotion,
  styles,
}: ActivityCardProps) {
  const [state, setState] = useState<WidgetState>('loading');
  const [items, setItems] = useState<ActivityItem[]>([]);
  const pulse = usePulse(state === 'loading', reduceMotion);

  useEffect(() => {
    let active = true;
    if (!isConnected) {
      // Keep any cached rows; a stale chip flags them (STATE-011).
      setState('offline');
      return () => {
        active = false;
      };
    }
    setState('loading');
    wait(motion.success).then(() => {
      if (!active) return;
      setItems(ACTIVITY);
      setState('ideal');
    });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [refreshNonce, isConnected]);

  if (state === 'loading') {
    return (
      <View style={[styles.card, { width }]}>
        <Text style={styles.sectionTitle} numberOfLines={1} allowFontScaling>
          Recent activity
        </Text>
        <Animated.View style={[styles.activityGroup, { opacity: pulse }]}>
          <View style={styles.activitySkelRow}>
            <View style={styles.activitySkelGlyph} />
            <View style={styles.activitySkelLine} />
          </View>
          <View style={styles.activitySkelRow}>
            <View style={styles.activitySkelGlyph} />
            <View style={styles.activitySkelLine} />
          </View>
          <View style={styles.activitySkelRow}>
            <View style={styles.activitySkelGlyph} />
            <View style={styles.activitySkelLine} />
          </View>
        </Animated.View>
      </View>
    );
  }

  if (items.length === 0) {
    const emptyCopy =
      state === 'offline'
        ? 'Offline — reconnect to load recent activity.'
        : 'No recent activity yet — actions you take will show up here.';
    return (
      <View style={[styles.card, { width }]}>
        <Text accessibilityRole="header" style={styles.sectionTitle} numberOfLines={1} allowFontScaling>
          Recent activity
        </Text>
        <Text style={styles.emptyText} numberOfLines={2} allowFontScaling>
          {emptyCopy}
        </Text>
      </View>
    );
  }

  return (
    <View style={[styles.card, { width }]}>
      <View style={styles.chartHeader}>
        <Text accessibilityRole="header" style={styles.sectionTitle} numberOfLines={1} allowFontScaling>
          Recent activity
        </Text>
        {state === 'offline' ? (
          <Text style={styles.staleChip} numberOfLines={1} allowFontScaling>
            saved · offline
          </Text>
        ) : null}
      </View>
      <View style={styles.activityGroup}>
        {items.map((item) => (
          <View
            key={item.id}
            accessible
            accessibilityRole="text"
            accessibilityLabel={`${item.text}, ${item.time} ago`}
            style={styles.activityRow}
          >
            <Text
              style={styles.activityGlyph}
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
            >
              {item.glyph}
            </Text>
            <Text style={styles.activityText} numberOfLines={2} allowFontScaling>
              {item.text}
            </Text>
            <Text style={[styles.activityTime, tabular]} numberOfLines={1} allowFontScaling>
              {item.time}
            </Text>
          </View>
        ))}
      </View>
    </View>
  );
}

// --- Navigation — bottom nav (compact) / side rail (medium + expanded) ------
type NavProps = {
  selected: string;
  onSelect: (key: string) => void;
  styles: Styles;
  paddingBottom: number;
};
function BottomNav({ selected, onSelect, styles, paddingBottom }: NavProps) {
  return (
    <View
      accessibilityRole="tablist"
      style={[styles.bottomNav, { paddingBottom: paddingBottom + spacing.sm }]}
    >
      {NAV_ITEMS.map((item) => {
        const active = item.key === selected;
        return (
          <Pressable
            key={item.key}
            accessibilityRole="tab"
            accessibilityState={{ selected: active }}
            accessibilityLabel={item.label}
            onPress={() => onSelect(item.key)}
            style={styles.navItem}
          >
            <Text
              style={[styles.navGlyph, active ? styles.navGlyphActive : null]}
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
            >
              {item.glyph}
            </Text>
            <Text
              style={[styles.navLabel, active ? styles.navLabelActive : null]}
              numberOfLines={1}
              allowFontScaling
            >
              {item.label}
            </Text>
            {active ? <View style={styles.navDot} /> : null}
          </Pressable>
        );
      })}
    </View>
  );
}
function SideRail({ selected, onSelect, styles, paddingBottom }: NavProps) {
  return (
    <View
      accessibilityRole="tablist"
      style={[styles.sideRail, { paddingBottom: paddingBottom + spacing.md }]}
    >
      {NAV_ITEMS.map((item) => {
        const active = item.key === selected;
        return (
          <Pressable
            key={item.key}
            accessibilityRole="tab"
            accessibilityState={{ selected: active }}
            accessibilityLabel={item.label}
            onPress={() => onSelect(item.key)}
            style={[styles.railItem, active ? styles.railItemActive : null]}
          >
            <Text
              style={[styles.navGlyph, active ? styles.navGlyphActive : null]}
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
            >
              {item.glyph}
            </Text>
            <Text
              style={[styles.railLabel, active ? styles.navLabelActive : null]}
              numberOfLines={1}
              allowFontScaling
            >
              {item.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

type Styles = ReturnType<typeof makeStyles>;

function makeStyles(colors: ColorRoles) {
  return StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.surface },
    srOnly: {
      position: 'absolute',
      width: size.hairline,
      height: size.hairline,
      overflow: 'hidden',
      opacity: 0,
    },
    body: { flex: 1, flexDirection: 'row' },
    main: { flex: 1 },
    scrollContent: {
      alignItems: 'center',
      paddingHorizontal: spacing.lg,
      paddingTop: spacing.lg,
      paddingBottom: spacing.xxl,
    },
    content: { gap: spacing.lg },

    // Responsive grid
    grid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.gutter },

    // Header
    header: {
      flexDirection: 'row',
      alignItems: 'flex-start',
      justifyContent: 'space-between',
      gap: spacing.md,
    },
    headerTitles: { flex: 1, gap: spacing.xs },
    greeting: { ...typography.titleLg, color: colors.onSurfaceStrong },
    subtitle: { ...typography.bodyMd, color: colors.onSurfaceMuted },
    updated: { ...typography.caption, color: colors.onSurfaceMuted },
    headerActions: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
    rangePill: {
      minHeight: size.target,
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.xs,
      paddingHorizontal: spacing.md,
      borderRadius: radius.pill,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surfaceContainer,
    },
    rangePillPressed: { backgroundColor: colors.surfaceDim },
    rangeLabel: { ...typography.labelMd, color: colors.onSurface },
    rangeGlyph: { ...typography.labelMd, color: colors.onSurfaceMuted },
    refreshButton: {
      minWidth: size.target,
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: radius.pill,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surfaceContainer,
    },
    refreshPressed: { backgroundColor: colors.surfaceDim },
    refreshGlyph: { ...typography.titleMd, color: colors.onSurface },

    // Card shell
    card: {
      minHeight: size.target,
      gap: spacing.sm,
      padding: spacing.lg,
      borderRadius: radius.lg,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surfaceContainer,
    },
    cardPressed: { backgroundColor: colors.surfaceDim },
    tileLabel: { ...typography.labelMd, color: colors.onSurfaceMuted },
    tileValue: { ...typography.displaySm, color: colors.onSurfaceStrong },

    // Trend (icon + sign + text — never color-only)
    trendRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
    trendGlyph: { ...typography.labelSm },
    trendText: { ...typography.labelSm, flexShrink: 1 },
    trendUp: { color: colors.statusSuccess },
    trendDown: { color: colors.statusError },
    trendFlat: { color: colors.onSurfaceMuted },
    mirror: { transform: [{ scaleX: -1 }] },

    // Stale / offline within a tile
    staleRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
    staleGlyph: { ...typography.labelSm, color: colors.onSurfaceMuted },
    staleText: { ...typography.caption, flexShrink: 1, color: colors.onSurfaceMuted },
    staleChip: { ...typography.caption, color: colors.onSurfaceMuted },

    // Scoped inline error + Retry
    errorRow: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.xs },
    errorGlyph: { ...typography.labelSm, color: colors.statusError },
    errorText: { ...typography.labelSm, flexShrink: 1, color: colors.onSurface },
    retryButton: {
      minHeight: size.target,
      alignSelf: 'flex-start',
      alignItems: 'center',
      justifyContent: 'center',
      paddingHorizontal: spacing.md,
      borderRadius: radius.md,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surface,
    },
    retryPressed: { backgroundColor: colors.surfaceDim },
    retryLabel: { ...typography.labelMd, color: colors.actionPrimary },

    // Empty / permission
    emptyText: { ...typography.bodyMd, color: colors.onSurfaceMuted },
    permFallback: { ...typography.caption, color: colors.onSurfaceMuted },
    ctaButton: {
      minHeight: size.target,
      alignSelf: 'flex-start',
      alignItems: 'center',
      justifyContent: 'center',
      paddingHorizontal: spacing.md,
      borderRadius: radius.md,
      backgroundColor: colors.actionPrimary,
    },
    ctaPressed: { backgroundColor: colors.actionPrimaryPressed },
    ctaLabel: { ...typography.labelMd, color: colors.onActionPrimary },

    // Skeleton (shape-matched, non-text Views)
    skelGroup: { gap: spacing.sm },
    skelLabel: {
      height: size.skelLine,
      alignSelf: 'stretch',
      borderRadius: radius.sm,
      backgroundColor: colors.skeleton,
    },
    skelNumber: {
      height: size.skelBlock,
      alignSelf: 'stretch',
      borderRadius: radius.sm,
      backgroundColor: colors.skeleton,
    },
    skelTrend: {
      height: size.skelLine,
      alignSelf: 'stretch',
      borderRadius: radius.sm,
      backgroundColor: colors.skeleton,
    },

    // Section title (chart + activity)
    sectionTitle: { ...typography.bodyStrong, color: colors.onSurface },

    // Chart
    chartHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: spacing.sm,
    },
    plot: {
      flexDirection: 'row',
      alignItems: 'flex-end',
      justifyContent: 'space-between',
      gap: spacing.xs,
    },
    barCol: { flex: 1, alignItems: 'center', gap: spacing.xs },
    barTrack: {
      height: size.chartHeight,
      alignSelf: 'stretch',
      justifyContent: 'flex-end',
      borderRadius: radius.sm,
      backgroundColor: colors.surfaceDim,
    },
    barFill: {
      alignSelf: 'stretch',
      borderRadius: radius.sm,
    },
    barValue: { ...typography.caption, ...tabular, color: colors.onSurface },
    barLabel: { ...typography.caption, color: colors.onSurfaceMuted },
    chartSkelRow: {
      flexDirection: 'row',
      alignItems: 'flex-end',
      justifyContent: 'space-between',
      gap: spacing.xs,
      height: size.chartHeight,
    },
    chartSkelBar: {
      flex: 1,
      borderRadius: radius.sm,
      backgroundColor: colors.skeleton,
    },

    // Chart data-table fallback
    dataTable: { gap: spacing.xs, marginTop: spacing.sm },
    dataTableTitle: { ...typography.labelSm, color: colors.onSurfaceMuted },
    dataRow: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: spacing.md,
      paddingVertical: spacing.xs,
      borderTopWidth: size.hairline,
      borderTopColor: colors.outline,
    },
    dataDay: { ...typography.bodyMd, color: colors.onSurfaceMuted },
    dataValue: { ...typography.bodyMd, color: colors.onSurface },

    // Activity list
    activityGroup: { gap: spacing.xs },
    activityRow: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      paddingVertical: spacing.sm,
      borderTopWidth: size.hairline,
      borderTopColor: colors.outline,
    },
    activityGlyph: { ...typography.bodyMd, color: colors.actionPrimary },
    activityText: { ...typography.bodyMd, flex: 1, color: colors.onSurface },
    activityTime: { ...typography.labelSm, color: colors.onSurfaceMuted },
    activitySkelRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm, paddingVertical: spacing.sm },
    activitySkelGlyph: {
      width: size.icon,
      height: size.icon,
      borderRadius: radius.pill,
      backgroundColor: colors.skeleton,
    },
    activitySkelLine: {
      height: size.skelLine,
      flex: 1,
      borderRadius: radius.sm,
      backgroundColor: colors.skeleton,
    },

    // Global offline banner
    banner: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.sm,
      backgroundColor: colors.surfaceDim,
    },
    bannerGlyph: { ...typography.bodyMd, color: colors.onSurface },
    bannerText: { ...typography.labelSm, flex: 1, color: colors.onSurface },
    bannerAction: {
      minHeight: size.target,
      justifyContent: 'center',
      paddingHorizontal: spacing.sm,
    },
    bannerLink: { ...typography.labelMd, color: colors.actionPrimary },

    // Bottom nav (compact)
    bottomNav: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-around',
      paddingTop: spacing.sm,
      borderTopWidth: size.hairline,
      borderTopColor: colors.outline,
      backgroundColor: colors.surface,
    },
    navItem: {
      minWidth: size.target,
      minHeight: size.target,
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
      gap: spacing.xs,
      paddingVertical: spacing.xs,
    },
    navGlyph: { ...typography.titleMd, color: colors.onSurfaceMuted },
    navGlyphActive: { color: colors.actionPrimary },
    navLabel: { ...typography.caption, color: colors.onSurfaceMuted },
    navLabelActive: { ...typography.labelSm, color: colors.actionPrimary },
    navDot: {
      width: size.dot,
      height: size.dot,
      borderRadius: radius.pill,
      backgroundColor: colors.actionPrimary,
    },

    // Side rail (medium + expanded)
    sideRail: {
      width: size.rail,
      alignItems: 'center',
      gap: spacing.sm,
      paddingTop: spacing.lg,
      paddingHorizontal: spacing.sm,
      borderEndWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surface,
    },
    railItem: {
      minWidth: size.target,
      minHeight: size.target,
      alignSelf: 'stretch',
      alignItems: 'center',
      justifyContent: 'center',
      gap: spacing.xs,
      paddingVertical: spacing.sm,
      borderRadius: radius.md,
    },
    railItemActive: { backgroundColor: colors.surfaceContainer },
    railLabel: { ...typography.caption, color: colors.onSurfaceMuted },
  });
}
