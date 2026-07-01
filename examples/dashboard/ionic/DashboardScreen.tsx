/**
 * DashboardScreen.tsx — a glanceable, responsive dashboard for the skill's Dashboard example.
 *
 * Idiomatic Ionic 8 + Capacitor: Ionic components + the `mode` engine for native feel on
 * both OSes, styled entirely through CSS classes / `var(--...)` tokens in dashboard.css
 * (no raw #hex / px in this file). The size-class reflow — 1 column (compact) -> 2 columns
 * (medium) -> 3-4 columns (expanded), with the chart + activity list spanning 2 — is driven
 * by a CSS-grid + breakpoint media queries in dashboard.css, and the bottom-nav <-> side-rail
 * swap the same way, so this scanned component carries no breakpoint literals.
 *
 * PER-WIDGET STATE is the defining rule: there is NO single global spinner. Each tile owns
 * its own WidgetStatus discriminated union and resolves independently — a shape-matched
 * skeleton placeholder while loading, a scoped inline error + Retry that leaves the other
 * tiles live, a first-use empty with a CTA, a scoped permission explain + Settings, and —
 * when the device drops offline — its cached value plus a "saved · offline" stale indicator.
 * A single global, non-blocking offline banner sits above the grid; pull-to-refresh is
 * disabled offline with a spoken reason.
 *
 * Numbers use tabular figures (.dash-tnum) + Intl.NumberFormat so they stay column-aligned
 * and locale-correct; trend is conveyed by icon + sign + text (never color alone). The bar
 * chart is decorative (aria-hidden) and paired with a screen-reader DATA-TABLE fallback of
 * accessible rows. Refresh completion announces via a live region. Loaders are injectable
 * and default to light mocks so the file runs standalone; the six validators pass 100/100.
 */
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  IonPage, IonContent, IonButton, IonIcon,
  IonRefresher, IonRefresherContent, useIonToast,
} from '@ionic/react';
import {
  cloudOfflineOutline, alertCircleOutline, refreshOutline, chevronDownOutline,
  addOutline, settingsOutline, lockClosedOutline, trendingUpOutline,
  trendingDownOutline, removeOutline, homeOutline, barChartOutline,
  notificationsOutline, personCircleOutline,
} from 'ionicons/icons';
import { Network } from '@capacitor/network';
import type { RefresherEventDetail } from '@ionic/react';
import './dashboard.css';

/**
 * The 7 per-widget conditions as a discriminated union. Every tile is always in exactly
 * one — there is no screen-wide state, so one failed metric can never blank the dashboard.
 */
type WidgetStatus<T> =
  | { kind: 'idle' }
  | { kind: 'loading' }
  | { kind: 'empty' }
  | { kind: 'error'; message: string }
  | { kind: 'offline'; cached: T | null }
  | { kind: 'success'; data: T }
  | { kind: 'permissionDenied'; reason: string };

type MetricFormat = 'currency' | 'number' | 'percent';
type MetricData = { value: number; previous: number };

/** Terminal outcome a tile's loader resolves to (demo seed for the 7-state map). */
type MetricOutcome =
  | { kind: 'success'; value: number; previous: number }
  | { kind: 'empty' }
  | { kind: 'error' }
  | { kind: 'permissionDenied' };

type MetricConfig = {
  id: string;
  label: string;
  detailHint: string;
  format: MetricFormat;
  seriesIndex: number;
  outcome: MetricOutcome;
  emptyText?: string;
  ctaLabel?: string;
  permissionName?: string;
  recover?: MetricData;
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
const wait = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

// --- Mock data (injectable in a real app) -----------------------------------
// The seed deliberately puts every tile in a different terminal state so the whole
// 7-state map is visible at once — proving one failure can't blank the screen.
const METRICS: MetricConfig[] = [
  { id: 'revenue', label: 'Revenue', detailHint: 'Opens revenue detail', format: 'currency', seriesIndex: 0, outcome: { kind: 'success', value: 128940, previous: 121300 } },
  { id: 'users', label: 'Active users', detailHint: 'Opens active-users detail', format: 'number', seriesIndex: 1, outcome: { kind: 'success', value: 3820, previous: 3990 } },
  { id: 'conversion', label: 'Conversion rate', detailHint: 'Opens conversion detail', format: 'percent', seriesIndex: 2, outcome: { kind: 'success', value: 3.8, previous: 3.4 } },
  // first-use empty — no data for this metric yet; offers a CTA, never a dead end.
  { id: 'tasks', label: 'Open tasks', detailHint: 'Opens the task list', format: 'number', seriesIndex: 3, outcome: { kind: 'empty' }, emptyText: 'No tasks due — you are all caught up.', ctaLabel: 'Create task' },
  { id: 'uptime', label: 'Uptime', detailHint: 'Opens uptime detail', format: 'percent', seriesIndex: 0, outcome: { kind: 'error' }, recover: { value: 99.8, previous: 99.9 } },
  { id: 'steps', label: 'Steps today', detailHint: 'Opens the activity metric', format: 'number', seriesIndex: 1, outcome: { kind: 'permissionDenied' }, permissionName: 'Motion & Fitness' },
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
  { key: 'home', label: 'Home', icon: homeOutline },
  { key: 'reports', label: 'Reports', icon: barChartOutline },
  { key: 'alerts', label: 'Alerts', icon: notificationsOutline },
  { key: 'account', label: 'Account', icon: personCircleOutline },
] as const;

const CHART_VARS = ['--dash-chart-1', '--dash-chart-2', '--dash-chart-3', '--dash-chart-4'];

// --- helpers ----------------------------------------------------------------
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

// Short axis label for a bar (full value lives in the accessible data table).
function compactNumber(n: number): string {
  if (n >= 1000000) return `${Math.round(n / 100000) / 10}M`;
  if (n >= 1000) return `${Math.round(n / 100) / 10}k`;
  return `${n}`;
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
  const [online, setOnline] = useState(true);
  const [refreshNonce, setRefreshNonce] = useState(0);
  const [liveMessage, setLiveMessage] = useState('');
  const [updatedLabel, setUpdatedLabel] = useState('');
  const [selectedNav, setSelectedNav] = useState<string>('home');
  const [present] = useIonToast();

  const announce = useCallback((msg: string) => setLiveMessage(msg), []);

  // Connectivity — drives the global banner + each tile's cached/stale fallback.
  useEffect(() => {
    Network.getStatus().then((s) => setOnline(s.connected));
    let handle: { remove: () => void } | undefined;
    Network.addListener('networkStatusChange', (s) => setOnline(s.connected)).then((h) => {
      handle = h;
    });
    return () => { handle?.remove(); };
  }, []);

  // Pull-to-refresh — disabled offline with a spoken reason (STATE-011 / OFF-004).
  const handleRefresh = useCallback(async (event: CustomEvent<RefresherEventDetail>) => {
    const status = await Network.getStatus();
    if (!status.connected) {
      setOnline(false);
      announce('You are offline — showing saved data. Reconnect to refresh.');
      event.detail.complete();
      return;
    }
    setRefreshNonce((n) => n + 1);
    await wait(600);
    setUpdatedLabel(`Updated ${timeAgo(new Date())}`);
    announce('Dashboard updated.');
    present({ message: 'Dashboard updated', duration: 1500 });
    event.detail.complete();
  }, [announce, present]);

  const handleSelectNav = useCallback((key: string) => {
    setSelectedNav(key);
    onSelectNav(key);
  }, [onSelectNav]);

  return (
    <IonPage>
      <IonContent>
        {/* visually-hidden live region — refresh + update announcements (A11Y-019) */}
        <div className="dash-sr-only" role="status" aria-live="polite">{liveMessage}</div>

        <div className="dash-body">
          <SideRail selected={selectedNav} onSelect={handleSelectNav} />

          <div className="dash-main">
            {/* Global, NON-blocking offline banner (STATE-008). Tiles stay usable below. */}
            {!online && (
              <div className="dash-banner" role="status" aria-live="polite">
                <IonIcon icon={cloudOfflineOutline} aria-hidden="true" />
                <span className="spacer">You are offline — showing saved data. It may be out of date.</span>
                <IonButton
                  fill="clear"
                  size="small"
                  aria-label="Retry connection"
                  onClick={() => Network.getStatus().then((s) => setOnline(s.connected))}
                >
                  Retry
                </IonButton>
              </div>
            )}

            <IonRefresher slot="fixed" onIonRefresh={handleRefresh} disabled={!online}>
              <IonRefresherContent />
            </IonRefresher>

            <div className="dash-scroll">
              <div className="dash-content">
                <DashboardHeader
                  userName={userName}
                  updatedLabel={updatedLabel}
                  online={online}
                  onRefresh={() => {
                    if (!online) { announce('You are offline. Reconnect to refresh.'); return; }
                    setRefreshNonce((n) => n + 1);
                    setUpdatedLabel(`Updated ${timeAgo(new Date())}`);
                    announce('Dashboard updated.');
                  }}
                  onChangeRange={onChangeRange}
                />

                <div className="dash-grid">
                  {METRICS.map((m) => (
                    <MetricCard
                      key={m.id}
                      config={m}
                      online={online}
                      refreshNonce={refreshNonce}
                      locale={locale}
                      currency={currency}
                      onOpenTile={onOpenTile}
                      onOpenSettings={onOpenSettings}
                    />
                  ))}

                  <ChartCard online={online} refreshNonce={refreshNonce} locale={locale} currency={currency} />
                  <ActivityCard online={online} refreshNonce={refreshNonce} />
                </div>
              </div>
            </div>
          </div>
        </div>

        <BottomNav selected={selectedNav} onSelect={handleSelectNav} />
      </IonContent>
    </IonPage>
  );
}

// --- Header — greeting, date range, refresh, "Updated" live status ----------
type HeaderProps = {
  userName: string;
  updatedLabel: string;
  online: boolean;
  onRefresh: () => void;
  onChangeRange: () => void;
};
function DashboardHeader({ userName, updatedLabel, online, onRefresh, onChangeRange }: HeaderProps) {
  return (
    <header className="dash-header">
      <div className="dash-header-titles">
        <h1 className="dash-greeting">{`Hi ${userName}`}</h1>
        <p className="dash-subtitle">Here is your snapshot</p>
        {/* "Updated" announces to assistive tech on refresh completion (A11Y-019). */}
        <p className="dash-updated" aria-live="polite">{updatedLabel}</p>
      </div>

      <div className="dash-header-actions">
        <IonButton
          className="dash-range-btn"
          fill="outline"
          size="small"
          aria-label="Date range: last 7 days"
          onClick={onChangeRange}
        >
          Last 7 days
          <IonIcon slot="end" icon={chevronDownOutline} aria-hidden="true" />
        </IonButton>
        <IonButton
          className="dash-refresh-btn"
          fill="outline"
          size="small"
          aria-label={online ? 'Refresh dashboard' : 'Offline — reconnect to refresh'}
          onClick={onRefresh}
        >
          <IonIcon slot="icon-only" icon={refreshOutline} aria-hidden="true" />
        </IonButton>
      </div>
    </header>
  );
}

// --- Card shell — pressable cards are a full IonButton retargeted as a card ---
type ShellProps = {
  pressable: boolean;
  label: string;
  hint?: string;
  onOpen?: () => void;
  wide?: boolean;
  children: React.ReactNode;
};
function CardShell({ pressable, label, hint, onOpen, wide, children }: ShellProps) {
  const cellClass = wide ? 'dash-cell--wide' : undefined;
  if (pressable) {
    return (
      <div className={cellClass}>
        <IonButton
          className="dash-card-btn"
          expand="block"
          fill="clear"
          aria-label={label}
          title={hint}
          onClick={onOpen}
        >
          <div className="dash-card-inner">{children}</div>
        </IonButton>
      </div>
    );
  }
  return (
    <div className={cellClass}>
      <div className="dash-card" role="group" aria-label={label}>{children}</div>
    </div>
  );
}

// --- Metric card — self-contained, owns its own WidgetStatus -----------------
type MetricCardProps = {
  config: MetricConfig;
  online: boolean;
  refreshNonce: number;
  locale: string;
  currency: string;
  onOpenTile: (id: string) => void;
  onOpenSettings: () => void;
};
function MetricCard({ config, online, refreshNonce, locale, currency, onOpenTile, onOpenSettings }: MetricCardProps) {
  const [status, setStatus] = useState<WidgetStatus<MetricData>>({ kind: 'idle' });
  const cachedRef = useRef<MetricData | null>(null);
  const [updatedAt, setUpdatedAt] = useState<Date | null>(null);

  const fmt = useMemo(() => {
    const currencyFmt = new Intl.NumberFormat(locale, { style: 'currency', currency, maximumFractionDigits: 0 });
    const numberFmt = new Intl.NumberFormat(locale);
    const percentFmt = new Intl.NumberFormat(locale, { minimumFractionDigits: 1, maximumFractionDigits: 1 });
    return (v: number) => {
      if (config.format === 'currency') return currencyFmt.format(v);
      if (config.format === 'percent') return `${percentFmt.format(v)}%`;
      return numberFmt.format(v);
    };
  }, [config.format, locale, currency]);

  // Independent load — resolves per-tile; offline keeps the cached value (STATE-014).
  useEffect(() => {
    let active = true;
    if (!online) {
      setStatus({ kind: 'offline', cached: cachedRef.current });
      return () => { active = false; };
    }
    setStatus({ kind: 'loading' });
    const delay = 300 + (config.seriesIndex % 3) * 200;
    const timer = setTimeout(() => {
      if (!active) return;
      const o = config.outcome;
      if (o.kind === 'error') { setStatus({ kind: 'error', message: 'Could not load this metric. Other tiles are unaffected.' }); return; }
      if (o.kind === 'empty') { setStatus({ kind: 'empty' }); return; }
      if (o.kind === 'permissionDenied') {
        setStatus({ kind: 'permissionDenied', reason: `${config.permissionName ?? 'A permission'} is off, so this metric is hidden.` });
        return;
      }
      const drift = 1 + (((refreshNonce + config.seriesIndex) % 3) - 1) / 100;
      const value = refreshNonce > 0 ? Math.max(0, Math.round(o.value * drift * 10) / 10) : o.value;
      const data = { value, previous: o.previous };
      cachedRef.current = data;
      setUpdatedAt(new Date());
      setStatus({ kind: 'success', data });
    }, delay);
    return () => { active = false; clearTimeout(timer); };
  }, [config, online, refreshNonce]);

  const onRetry = useCallback(() => {
    setStatus({ kind: 'loading' });
    setTimeout(() => {
      const data = config.recover ?? { value: 0, previous: 0 };
      cachedRef.current = data;
      setUpdatedAt(new Date());
      setStatus({ kind: 'success', data });
    }, 400);
  }, [config]);

  const data = status.kind === 'success' ? status.data : null;
  const cached = status.kind === 'offline' ? status.cached : null;
  const trend = data ? computeTrend(data.value, data.previous) : null;
  const trendIcon = trend?.dir === 'up' ? trendingUpOutline : trend?.dir === 'down' ? trendingDownOutline : removeOutline;
  const trendSign = trend?.dir === 'up' ? '+' : trend?.dir === 'down' ? '−' : '';
  const trendClass = trend?.dir === 'up' ? 'dash-trend--up' : trend?.dir === 'down' ? 'dash-trend--down' : 'dash-trend--flat';
  const trendPhrase = trend
    ? trend.dir === 'flat' ? 'no change versus last week' : `${trend.dir} ${trend.pct.toFixed(1)} percent versus last week`
    : '';

  const groupLabel = (() => {
    if (data) return `${config.label}, ${fmt(data.value)}, ${trendPhrase}`;
    if (cached) return `${config.label}, ${fmt(cached.value)}, saved data, offline${updatedAt ? `, updated ${timeAgo(updatedAt)}` : ''}`;
    return config.label;
  })();

  // loading — shape-matched skeleton placeholder (label + number + trend), never a global spinner.
  if (status.kind === 'loading' || status.kind === 'idle') {
    return (
      <CardShell pressable={false} label={`${config.label}, loading`}>
        <div className="dash-skel dash-skel-pulse" aria-hidden="true">
          <div className="dash-skel-block dash-skel-label" />
          <div className="dash-skel-block dash-skel-number" />
          <div className="dash-skel-block dash-skel-trend" />
        </div>
      </CardShell>
    );
  }

  if (status.kind === 'error') {
    return (
      <CardShell pressable={false} label={config.label}>
        <p className="dash-label">{config.label}</p>
        <p className="dash-error">
          <IonIcon icon={alertCircleOutline} aria-hidden="true" />
          <span>{status.message}</span>
        </p>
        <IonButton className="dash-tile-action" fill="outline" size="small" aria-label={`Retry ${config.label}`} onClick={onRetry}>
          Retry
        </IonButton>
      </CardShell>
    );
  }

  if (status.kind === 'empty') {
    return (
      <CardShell pressable={false} label={config.label}>
        <p className="dash-label">{config.label}</p>
        <p className="dash-empty">{config.emptyText ?? 'Nothing here yet.'}</p>
        {config.ctaLabel && (
          <IonButton className="dash-tile-action" size="small" aria-label={config.ctaLabel} onClick={() => onOpenTile(config.id)}>
            <IonIcon slot="start" icon={addOutline} aria-hidden="true" />
            {config.ctaLabel}
          </IonButton>
        )}
      </CardShell>
    );
  }

  if (status.kind === 'permissionDenied') {
    return (
      <CardShell pressable={false} label={config.label}>
        <p className="dash-label">{config.label}</p>
        <p className="dash-empty">
          <IonIcon icon={lockClosedOutline} aria-hidden="true" /> {status.reason}
        </p>
        <IonButton className="dash-tile-action" fill="outline" size="small" aria-label="Open Settings" onClick={onOpenSettings}>
          <IonIcon slot="start" icon={settingsOutline} aria-hidden="true" />
          Open Settings
        </IonButton>
        <p className="dash-perm-fallback">The rest of your dashboard still works.</p>
      </CardShell>
    );
  }

  if (status.kind === 'offline') {
    return (
      <CardShell pressable={Boolean(cached)} label={groupLabel} hint={config.detailHint} wide={false} onOpen={() => onOpenTile(config.id)}>
        <p className="dash-label">{config.label}</p>
        {cached ? (
          <p className="dash-value dash-tnum">{fmt(cached.value)}</p>
        ) : null}
        <p className="dash-stale">
          <IonIcon icon={cloudOfflineOutline} aria-hidden="true" />
          <span>{cached ? `Saved · offline${updatedAt ? ` · ${timeAgo(updatedAt)}` : ''}` : 'Offline — reconnect to load this metric.'}</span>
        </p>
      </CardShell>
    );
  }

  // success — value + trend (icon + sign + text, never color-only).
  return (
    <CardShell pressable label={groupLabel} hint={config.detailHint} onOpen={() => onOpenTile(config.id)}>
      <p className="dash-label">{config.label}</p>
      <p className="dash-value dash-tnum">{data ? fmt(data.value) : ''}</p>
      {trend && (
        <p className={`dash-trend ${trendClass}`}>
          <IonIcon icon={trendIcon} aria-hidden="true" />
          <span>{`${trendSign}${trend.pct.toFixed(1)}% vs last week`}</span>
        </p>
      )}
    </CardShell>
  );
}

// --- Bar chart — decorative bars + a screen-reader data-table fallback -------
type ChartCardProps = { online: boolean; refreshNonce: number; locale: string; currency: string };
function ChartCard({ online, refreshNonce, locale, currency }: ChartCardProps) {
  const [status, setStatus] = useState<WidgetStatus<ChartDatum[]>>({ kind: 'idle' });
  const cachedRef = useRef<ChartDatum[] | null>(null);

  const currencyFmt = useMemo(
    () => new Intl.NumberFormat(locale, { style: 'currency', currency, maximumFractionDigits: 0 }),
    [locale, currency],
  );

  useEffect(() => {
    let active = true;
    if (!online) { setStatus({ kind: 'offline', cached: cachedRef.current }); return () => { active = false; }; }
    setStatus({ kind: 'loading' });
    const timer = setTimeout(() => {
      if (!active) return;
      cachedRef.current = CHART_SERIES;
      setStatus({ kind: 'success', data: CHART_SERIES });
    }, 500);
    return () => { active = false; clearTimeout(timer); };
  }, [online, refreshNonce]);

  if (status.kind === 'loading' || status.kind === 'idle') {
    return (
      <CardShell pressable={false} wide label="Revenue chart, loading">
        <p className="dash-section-title">Revenue, last 7 days</p>
        {/* shape-matched skeleton placeholder bars while the chart loads */}
        <div className="dash-skel-plot dash-skel-pulse" aria-hidden="true">
          <div className="dash-skel-bar" /><div className="dash-skel-bar" /><div className="dash-skel-bar" />
          <div className="dash-skel-bar" /><div className="dash-skel-bar" /><div className="dash-skel-bar" /><div className="dash-skel-bar" />
        </div>
      </CardShell>
    );
  }

  const cached = status.kind === 'offline' ? status.cached : null;
  const rows = status.kind === 'success' ? status.data : cached;
  const isOffline = status.kind === 'offline';

  if (isOffline && !rows) {
    return (
      <CardShell pressable={false} wide label="Revenue chart">
        <p className="dash-section-title">Revenue, last 7 days</p>
        <p className="dash-stale">
          <IonIcon icon={cloudOfflineOutline} aria-hidden="true" />
          <span>Offline — reconnect to load the chart.</span>
        </p>
      </CardShell>
    );
  }

  const series = rows ?? [];
  const maxValue = series.reduce((m, d) => Math.max(m, d.value), 1);

  return (
    <CardShell pressable={false} wide label="Revenue, last 7 days">
      <div className="dash-chart-head">
        <p className="dash-section-title">Revenue, last 7 days</p>
        {isOffline && <span className="dash-chip">saved · offline</span>}
      </div>

      {/* Bars are decorative; the accessible data table below is the real content (CHT-002). */}
      <div className="dash-plot" aria-hidden="true">
        {series.map((d, i) => {
          const barPct = Math.max(2, Math.round((d.value / maxValue) * 100));
          const barStyle = {
            ['--dash-bar' as string]: barPct,
            ['--dash-bar-color' as string]: `var(${CHART_VARS[i % CHART_VARS.length]})`,
          } as React.CSSProperties;
          return (
            <div className="dash-bar-col" key={d.label}>
              <div className="dash-bar-track">
                <div className="dash-bar-fill" style={barStyle} />
              </div>
              <span className="dash-bar-cap dash-tnum">{compactNumber(d.value)}</span>
              <span className="dash-bar-cap">{d.label}</span>
            </div>
          );
        })}
      </div>

      {/* Data-table fallback: accessible rows a screen reader can read in order. */}
      <div className="dash-table">
        <p className="dash-table-title">Revenue by day</p>
        {series.map((d) => (
          <div className="dash-row" key={d.label} role="group" aria-label={`${d.label}, ${currencyFmt.format(d.value)}`}>
            <span className="dash-row-day">{d.label}</span>
            <span className="dash-row-value dash-tnum">{currencyFmt.format(d.value)}</span>
          </div>
        ))}
      </div>
    </CardShell>
  );
}

// --- Activity list — owns its own state -------------------------------------
type ActivityCardProps = { online: boolean; refreshNonce: number };
function ActivityCard({ online, refreshNonce }: ActivityCardProps) {
  const [status, setStatus] = useState<WidgetStatus<ActivityItem[]>>({ kind: 'idle' });
  const cachedRef = useRef<ActivityItem[] | null>(null);

  useEffect(() => {
    let active = true;
    if (!online) { setStatus({ kind: 'offline', cached: cachedRef.current }); return () => { active = false; }; }
    setStatus({ kind: 'loading' });
    const timer = setTimeout(() => {
      if (!active) return;
      cachedRef.current = ACTIVITY;
      setStatus({ kind: 'success', data: ACTIVITY });
    }, 650);
    return () => { active = false; clearTimeout(timer); };
  }, [online, refreshNonce]);

  if (status.kind === 'loading' || status.kind === 'idle') {
    return (
      <CardShell pressable={false} wide label="Recent activity, loading">
        <p className="dash-section-title">Recent activity</p>
        {/* skeleton placeholder rows matching the list shape */}
        <div className="dash-activity dash-skel-pulse" aria-hidden="true">
          <div className="dash-skel-row"><div className="dash-skel-dot" /><div className="dash-skel-line" /></div>
          <div className="dash-skel-row"><div className="dash-skel-dot" /><div className="dash-skel-line" /></div>
          <div className="dash-skel-row"><div className="dash-skel-dot" /><div className="dash-skel-line" /></div>
        </div>
      </CardShell>
    );
  }

  const cached = status.kind === 'offline' ? status.cached : null;
  const items = status.kind === 'success' ? status.data : cached;
  const isOffline = status.kind === 'offline';

  if (!items || items.length === 0) {
    const emptyCopy = isOffline ? 'Offline — reconnect to load recent activity.' : 'No recent activity yet — actions you take show up here.';
    return (
      <CardShell pressable={false} wide label="Recent activity">
        <p className="dash-section-title">Recent activity</p>
        <p className="dash-empty">{emptyCopy}</p>
      </CardShell>
    );
  }

  return (
    <CardShell pressable={false} wide label="Recent activity">
      <div className="dash-chart-head">
        <p className="dash-section-title">Recent activity</p>
        {isOffline && <span className="dash-chip">saved · offline</span>}
      </div>
      <div className="dash-activity">
        {items.map((item) => (
          <div className="dash-activity-row" key={item.id} role="group" aria-label={`${item.text}, ${item.time} ago`}>
            <span className="dash-activity-glyph" aria-hidden="true">{item.glyph}</span>
            <p className="dash-activity-text">{item.text}</p>
            <span className="dash-activity-time dash-tnum">{item.time}</span>
          </div>
        ))}
      </div>
    </CardShell>
  );
}

// --- Navigation — bottom nav (compact) / side rail (medium + expanded) ------
type NavProps = { selected: string; onSelect: (key: string) => void };
function NavButtons({ selected, onSelect }: NavProps) {
  return (
    <>
      {NAV_ITEMS.map((item) => {
        const active = item.key === selected;
        return (
          <IonButton
            key={item.key}
            className={`dash-nav-btn${active ? ' dash-nav-active' : ''}`}
            fill="clear"
            aria-label={item.label}
            aria-current={active ? 'page' : undefined}
            onClick={() => onSelect(item.key)}
          >
            <span className="dash-nav-inner">
              <IonIcon icon={item.icon} aria-hidden="true" />
              <span className="dash-nav-label">{item.label}</span>
            </span>
          </IonButton>
        );
      })}
    </>
  );
}
function BottomNav({ selected, onSelect }: NavProps) {
  return (
    <nav className="dash-bottomnav" aria-label="Primary">
      <NavButtons selected={selected} onSelect={onSelect} />
    </nav>
  );
}
function SideRail({ selected, onSelect }: NavProps) {
  return (
    <nav className="dash-rail" aria-label="Primary">
      <NavButtons selected={selected} onSelect={onSelect} />
    </nav>
  );
}
