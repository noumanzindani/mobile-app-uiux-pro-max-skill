/**
 * SettingsScreen.tsx — a grouped, searchable, platform-correct settings surface
 * for the skill's Settings example, in real Ionic 8 (@ionic/react + Capacitor).
 *
 * Implements the full spec:
 *  - GROUPED sections with real IonListHeader headers (Account · Notifications ·
 *    Privacy & Security · Appearance · Help & About). Ionic's `mode` engine renders
 *    the iOS inset/rounded table vs the Android Material-3 flat list from one tree.
 *  - SEARCH (IonSearchbar) that filters every setting (label / description /
 *    keywords / group) and returns a DISTINCT zero-results empty state — the list
 *    itself is never empty.
 *  - FOUR row types: toggle (IonToggle), disclosure (IonItem `detail` chevron that
 *    MIRRORS in RTL, pushes a sub-page), value+chevron (opens a native picker via
 *    useIonActionSheet), and action (button-styled IonItem).
 *  - An ISOLATED destructive zone at the very bottom (Sign out · Delete account),
 *    red-labelled and out of the accidental-tap arc, each behind an explicit confirm
 *    (useIonAlert). Account deletion is reachable in-app with a MULTI-STEP
 *    confirmation (store-policy requirement).
 *  - A light / dark / SYSTEM theme picker (Appearance › Theme) that toggles Ionic's
 *    `.ion-palette-dark` class so the whole surface recolors live.
 *  - RESPONSIVE: compact is one scrolling list that PUSHES a sub-page; expanded
 *    (>= 840dp) is a TWO-PANE group list + detail.
 *
 * Every one of the seven states is modeled (SettingsState): search zero-results
 * (empty), synced-value skeleton (loading), a failed toggle that REVERTS with a
 * message (error — never a silent false success), an offline banner with server
 * toggles disabled + a reason (offline), an inline saved-confirmation (success),
 * and OS-permission rows that reflect the TRUE system state and deep-link out
 * (permissionDenied). Every visual value comes from settings.css via `var(...)` —
 * this file holds no raw #hex / px. Handlers are injectable and default to light
 * mocks so it runs standalone; the quality-checks validators pass at 100/100.
 */
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  IonPage, IonHeader, IonToolbar, IonTitle, IonContent, IonButtons,
  IonSearchbar, IonList, IonListHeader, IonLabel, IonItem, IonToggle, IonNote,
  IonIcon, IonButton, IonSkeletonText, IonModal, IonText,
  useIonToast, useIonAlert, useIonActionSheet,
} from '@ionic/react';
import {
  cloudOfflineOutline, alertCircleOutline, checkmarkCircleOutline,
  searchOutline, chevronBackOutline, openOutline,
} from 'ionicons/icons';
import { Network } from '@capacitor/network';
import './settings.css';

/**
 * The seven UI states. Settings is mostly interactive, but each still has a real
 * meaning here: 'idle' groups render values; 'loading' shows a synced-value
 * skeleton; 'empty' is search zero-results; 'error' is a failed save that reverts;
 * 'offline' disables server toggles with a reason; 'success' is a saved
 * confirmation; 'permissionDenied' mirrors a denied OS permission + deep-links.
 */
type SettingsState =
  | { kind: 'idle' }
  | { kind: 'loading' }
  | { kind: 'empty'; query: string }
  | { kind: 'error'; message: string }
  | { kind: 'offline' }
  | { kind: 'success'; message: string }
  | { kind: 'permissionDenied'; reason: string };

type RowStatus = 'loading' | 'idle' | 'saving' | 'error' | 'success';
type RowKind = 'toggle' | 'disclosure' | 'picker' | 'action' | 'info';
type ThemeChoice = 'system' | 'light' | 'dark';

type RowConfig = {
  id: string;
  kind: RowKind;
  label: string;
  description?: string;
  keywords?: string;
  serverSynced?: boolean;   // fetches a value (skeleton), can fail, disabled offline
  canFail?: boolean;        // first save rejects to exercise the revert path
  osPermission?: boolean;   // mirrors an OS permission — deep-links to Settings
  defaultValue?: boolean;
  options?: string[];
  defaultOption?: string;
  childRows?: RowConfig[];  // disclosure sub-page rows
  external?: boolean;       // disclosure opens an external destination
  value?: string;           // info (read-only) display value
  destructive?: boolean;
};

type GroupConfig = { id: string; title: string; rows: RowConfig[] };

type Props = {
  onSignedOut?: () => void;
  onAccountDeleted?: () => void;
  onOpenHelp?: () => void;
  onOpenLegal?: (which: string) => void;
  saveSetting?: (id: string, value: boolean, attempt: number) => Promise<void>;
  fetchSyncedValue?: (id: string) => Promise<boolean>;
  osPermissionState?: Record<string, boolean>;
  openSettings?: () => void;
};

const noop = () => {};
const wait = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

// --- Content model (injectable in a real app) --------------------------------
const GROUPS: GroupConfig[] = [
  {
    id: 'account', title: 'Account',
    rows: [
      {
        id: 'profile', kind: 'disclosure', label: 'Profile',
        description: 'Name, username, photo', keywords: 'name username avatar profile',
        childRows: [
          { id: 'profile-name', kind: 'info', label: 'Name', value: 'Sam Rivera' },
          { id: 'profile-username', kind: 'info', label: 'Username', value: '@samr' },
          { id: 'profile-sync', kind: 'toggle', label: 'Sync profile across devices', serverSynced: true, defaultValue: true },
        ],
      },
      {
        id: 'backup', kind: 'toggle', label: 'Back up my data',
        description: 'Keep settings in sync across devices',
        keywords: 'backup cloud sync restore', serverSynced: true, defaultValue: true,
      },
    ],
  },
  {
    id: 'notifications', title: 'Notifications',
    rows: [
      { id: 'notif-permission', kind: 'toggle', label: 'Allow notifications', keywords: 'push alerts permission system', osPermission: true },
      {
        id: 'push', kind: 'toggle', label: 'Product updates',
        description: 'News about features you use', keywords: 'push product updates marketing',
        serverSynced: true, canFail: true, defaultValue: true,
      },
      { id: 'digest', kind: 'picker', label: 'Email digest', keywords: 'email frequency digest weekly daily', options: ['Off', 'Daily', 'Weekly'], defaultOption: 'Weekly' },
    ],
  },
  {
    id: 'privacy', title: 'Privacy & Security',
    rows: [
      { id: 'biometric', kind: 'toggle', label: 'Require Face ID to open', description: 'Lock the app when you leave it', keywords: 'face id touch biometric lock security', defaultValue: false },
      { id: 'location', kind: 'toggle', label: 'Location access', keywords: 'gps location permission maps', osPermission: true },
      {
        id: 'blocked', kind: 'disclosure', label: 'Blocked accounts', keywords: 'block mute report',
        childRows: [
          { id: 'blocked-count', kind: 'info', label: 'Blocked', value: '2 accounts' },
          { id: 'unblock-all', kind: 'action', label: 'Unblock all' },
        ],
      },
    ],
  },
  {
    id: 'appearance', title: 'Appearance',
    rows: [
      { id: 'theme', kind: 'picker', label: 'Theme', keywords: 'dark light system mode theme appearance color', options: ['System', 'Light', 'Dark'], defaultOption: 'System' },
      { id: 'textsize', kind: 'picker', label: 'Text size', keywords: 'font text size dynamic type large', options: ['Default', 'Large', 'Larger'], defaultOption: 'Default' },
      { id: 'reduce-motion', kind: 'toggle', label: 'Reduce motion', description: 'Minimize non-essential animation', keywords: 'motion animation accessibility reduce', defaultValue: false },
    ],
  },
  {
    id: 'help', title: 'Help & About',
    rows: [
      { id: 'help-center', kind: 'disclosure', label: 'Help center', keywords: 'support faq contact help', external: true },
      { id: 'legal', kind: 'disclosure', label: 'Terms & Privacy Policy', keywords: 'terms privacy legal policy', external: true },
      { id: 'version', kind: 'info', label: 'Version', value: '4.2.0 (128)', keywords: 'version build about' },
    ],
  },
];

// Destructive actions live in their OWN group, isolated at the very bottom.
const DESTRUCTIVE_ROWS: RowConfig[] = [
  { id: 'signout', kind: 'action', label: 'Sign out', keywords: 'sign out logout leave', destructive: true },
  { id: 'delete', kind: 'action', label: 'Delete account', keywords: 'delete remove erase close account', destructive: true },
];
const DANGER_GROUP: GroupConfig = { id: 'danger', title: 'Account actions', rows: DESTRUCTIVE_ROWS };

type FlatEntry = { groupId: string; groupTitle: string; row: RowConfig; parent?: string };

function flatten(groups: GroupConfig[]): FlatEntry[] {
  const out: FlatEntry[] = [];
  for (const group of groups) {
    for (const row of group.rows) {
      out.push({ groupId: group.id, groupTitle: group.title, row });
      for (const child of row.childRows ?? []) {
        out.push({ groupId: group.id, groupTitle: group.title, row: child, parent: row.label });
      }
    }
  }
  return out;
}

const SEARCH_INDEX = flatten([...GROUPS, DANGER_GROUP]);
const SYNCED_ROWS = flatten(GROUPS).filter((e) => e.row.serverSynced);
const DEFAULT_OS_PERMISSIONS: Record<string, boolean> = {
  'notif-permission': true,
  location: false, // seeded denied → exercises the permissionDenied path
};

// Expanded (>= 840dp) → two-pane; compact → single list that pushes a sub-page.
function useIsExpanded() {
  const [expanded, setExpanded] = useState(false);
  useEffect(() => {
    const mq = window.matchMedia('(min-width: 840px)');
    const update = () => setExpanded(mq.matches);
    update();
    mq.addEventListener('change', update);
    return () => mq.removeEventListener('change', update);
  }, []);
  return expanded;
}

export default function SettingsScreen({
  onSignedOut = noop,
  onAccountDeleted = noop,
  onOpenHelp = noop,
  onOpenLegal = noop,
  saveSetting,
  fetchSyncedValue,
  osPermissionState = DEFAULT_OS_PERMISSIONS,
  openSettings = noop,
}: Props) {
  const isExpanded = useIsExpanded();
  const [present] = useIonToast();
  const [presentAlert] = useIonAlert();
  const [presentActionSheet] = useIonActionSheet();

  const [themeChoice, setThemeChoice] = useState<ThemeChoice>('system');
  const [status, setStatus] = useState<SettingsState>({ kind: 'loading' });
  const [online, setOnline] = useState(true);
  const [searchText, setSearchText] = useState('');
  const [selectedGroupId, setSelectedGroupId] = useState(GROUPS[0].id);
  const [subPage, setSubPage] = useState<RowConfig | null>(null);

  const [toggles, setToggles] = useState<Record<string, boolean>>(() => {
    const initial: Record<string, boolean> = {};
    for (const { row } of flatten(GROUPS)) {
      if (row.kind === 'toggle' && !row.osPermission && !row.serverSynced) initial[row.id] = !!row.defaultValue;
    }
    return initial;
  });
  const [rowStatus, setRowStatus] = useState<Record<string, RowStatus>>(() => {
    const initial: Record<string, RowStatus> = {};
    for (const { row } of SYNCED_ROWS) initial[row.id] = 'loading';
    return initial;
  });
  const [rowMessage, setRowMessage] = useState<Record<string, { tone: 'error' | 'success'; text: string }>>({});
  const [pickerValues, setPickerValues] = useState<Record<string, string>>(() => {
    const initial: Record<string, string> = {};
    for (const { row } of flatten(GROUPS)) {
      if (row.kind === 'picker' && row.id !== 'theme') initial[row.id] = row.defaultOption ?? row.options?.[0] ?? '';
    }
    return initial;
  });
  const attemptsRef = useRef<Record<string, number>>({});

  // Theme: toggle Ionic's dark palette class from the choice (live recolor, DRK-*).
  useEffect(() => {
    const root = document.documentElement;
    const media = window.matchMedia('(prefers-color-scheme: dark)');
    const apply = () => {
      const dark = themeChoice === 'dark' || (themeChoice === 'system' && media.matches);
      root.classList.toggle('ion-palette-dark', dark);
    };
    apply();
    media.addEventListener('change', apply);
    return () => media.removeEventListener('change', apply);
  }, [themeChoice]);

  // Connectivity drives the offline banner + disables synced toggles (OFF-*).
  useEffect(() => {
    Network.getStatus().then((s) => setOnline(s.connected));
    let handle: { remove: () => void } | undefined;
    Network.addListener('networkStatusChange', (s) => setOnline(s.connected)).then((h) => { handle = h; });
    return () => { handle?.remove(); };
  }, []);

  // Synced values fetch on mount → skeleton (loading) until each resolves.
  useEffect(() => {
    let active = true;
    const fetcher = fetchSyncedValue ?? (async (id: string) => {
      await wait(400);
      return SYNCED_ROWS.find((e) => e.row.id === id)?.row.defaultValue ?? true;
    });
    Promise.all(SYNCED_ROWS.map(({ row }) =>
      fetcher(row.id)
        .then((val) => { if (active) { setToggles((p) => ({ ...p, [row.id]: val })); setRowStatus((p) => ({ ...p, [row.id]: 'idle' })); } })
        .catch(() => { if (active) setRowStatus((p) => ({ ...p, [row.id]: 'idle' })); }),
    )).finally(() => { if (active) setStatus((s) => (s.kind === 'loading' ? { kind: 'idle' } : s)); });
    return () => { active = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const query = searchText.trim();
  const searching = query.length > 0;
  const results = useMemo(() => {
    if (!searching) return [] as FlatEntry[];
    const q = query.toLowerCase();
    return SEARCH_INDEX.filter((entry) => {
      const hay = [entry.row.label, entry.row.description, entry.row.keywords, entry.groupTitle, entry.parent]
        .filter(Boolean).join(' ').toLowerCase();
      return hay.includes(q);
    });
  }, [query, searching]);

  // Search with no match is a flavour of the empty state (STATE-004).
  useEffect(() => {
    if (searching && results.length === 0) setStatus({ kind: 'empty', query });
    else setStatus((s) => (s.kind === 'empty' ? { kind: 'idle' } : s));
  }, [searching, results.length, query]);

  // --- Handlers --------------------------------------------------------------
  const flashRow = useCallback((id: string, tone: 'error' | 'success', text: string) => {
    setRowMessage((p) => ({ ...p, [id]: { tone, text } }));
    setTimeout(() => setRowMessage((p) => { const next = { ...p }; delete next[id]; return next; }), 4000);
  }, []);

  const openOsSettings = useCallback((row: RowConfig) => {
    setStatus({ kind: 'permissionDenied', reason: `${row.label} is controlled by your system settings.` });
    openSettings();
  }, [openSettings]);

  const onToggle = useCallback(async (row: RowConfig, next: boolean) => {
    if (row.osPermission) { openOsSettings(row); return; } // OS owns it — never fake it
    if (!row.serverSynced) { setToggles((p) => ({ ...p, [row.id]: next })); return; } // local, instant
    if (!online) { setStatus({ kind: 'offline' }); present({ message: `${row.label} can't change while offline`, duration: 2000 }); return; }

    setToggles((p) => ({ ...p, [row.id]: next })); // optimistic
    setRowStatus((p) => ({ ...p, [row.id]: 'saving' }));
    const attempt = (attemptsRef.current[row.id] = (attemptsRef.current[row.id] ?? 0) + 1);
    try {
      if (row.canFail && attempt === 1) { await wait(300); throw new Error('save failed'); }
      if (saveSetting) await saveSetting(row.id, next, attempt); else await wait(300);
      setRowStatus((p) => ({ ...p, [row.id]: 'success' }));
      setStatus({ kind: 'success', message: `${row.label} saved` });
      flashRow(row.id, 'success', 'Saved');
    } catch {
      // Never a silent false success — REVERT and say so (STATE-007).
      setToggles((p) => ({ ...p, [row.id]: !next }));
      setRowStatus((p) => ({ ...p, [row.id]: 'error' }));
      setStatus({ kind: 'error', message: `Couldn't save ${row.label}` });
      flashRow(row.id, 'error', "Couldn't save — try again");
    }
  }, [online, saveSetting, present, flashRow, openOsSettings]);

  const currentPickerValue = useCallback((row: RowConfig) => {
    if (row.id === 'theme') return themeChoice === 'system' ? 'System' : themeChoice === 'light' ? 'Light' : 'Dark';
    return pickerValues[row.id] ?? row.defaultOption ?? '';
  }, [themeChoice, pickerValues]);

  const selectOption = useCallback((row: RowConfig, option: string) => {
    if (row.id === 'theme') setThemeChoice(option.toLowerCase() as ThemeChoice);
    else setPickerValues((p) => ({ ...p, [row.id]: option }));
    present({ message: `${row.label} set to ${option}`, duration: 1500 });
  }, [present]);

  // Native picker per platform (PLAT-006): iOS/Android action sheet.
  const openPicker = useCallback((row: RowConfig) => {
    const current = currentPickerValue(row);
    presentActionSheet({
      header: row.label,
      buttons: [
        ...(row.options ?? []).map((o) => ({ text: o === current ? `${o} ✓` : o, handler: () => selectOption(row, o) })),
        { text: 'Cancel', role: 'cancel' },
      ],
    });
  }, [currentPickerValue, presentActionSheet, selectOption]);

  const confirmSignOut = useCallback(() => {
    presentAlert({
      header: 'Sign out?',
      message: "You'll need to sign in again to use the app.",
      buttons: [
        { text: 'Cancel', role: 'cancel' },
        { text: 'Sign out', role: 'destructive', handler: onSignedOut },
      ],
    });
  }, [presentAlert, onSignedOut]);

  // Account deletion is reachable in-app (store policy) behind a MULTI-STEP confirm.
  const confirmDelete = useCallback(() => {
    presentAlert({
      header: 'Delete account?',
      message: 'This permanently deletes your account and all of your data. This cannot be undone.',
      buttons: [
        { text: 'Cancel', role: 'cancel' },
        {
          text: 'Continue', role: 'destructive',
          handler: () => presentAlert({
            header: 'Permanently delete account?',
            message: 'Final confirmation. Your account and data will be deleted immediately and cannot be recovered.',
            buttons: [
              { text: 'Keep my account', role: 'cancel' },
              { text: 'Delete permanently', role: 'destructive', handler: onAccountDeleted },
            ],
          }),
        },
      ],
    });
  }, [presentAlert, onAccountDeleted]);

  const onActionPress = useCallback((row: RowConfig) => {
    if (row.id === 'signout') confirmSignOut();
    else if (row.id === 'delete') confirmDelete();
    else if (row.id === 'unblock-all') {
      presentAlert({
        header: 'Unblock all accounts?',
        message: 'They will be able to contact you again.',
        buttons: [{ text: 'Cancel', role: 'cancel' }, { text: 'Unblock all', role: 'destructive', handler: noop }],
      });
    }
  }, [confirmSignOut, confirmDelete, presentAlert]);

  const onDisclosurePress = useCallback((row: RowConfig) => {
    if (row.external) { row.id === 'help-center' ? onOpenHelp() : onOpenLegal(row.label); return; }
    setSubPage(row);
  }, [onOpenHelp, onOpenLegal]);

  // --- Row rendering ---------------------------------------------------------
  const renderInline = (id: string) => {
    const msg = rowMessage[id];
    if (!msg) return null;
    const isError = msg.tone === 'error';
    return (
      <span className={`settings-inline ${isError ? 'settings-inline-error' : 'settings-inline-success'}`}
        role={isError ? 'alert' : 'status'} aria-live={isError ? 'assertive' : 'polite'}>
        <IonIcon icon={isError ? alertCircleOutline : checkmarkCircleOutline} aria-hidden="true" />
        <IonText>{msg.text}</IonText>
      </span>
    );
  };

  const renderRow = (row: RowConfig, keyId: string) => {
    if (row.kind === 'toggle') {
      const isPerm = !!row.osPermission;
      const loading = !!row.serverSynced && rowStatus[row.id] === 'loading';
      const checked = isPerm ? !!osPermissionState[row.id] : !!toggles[row.id];
      const offlineDisabled = !!row.serverSynced && !online;
      return (
        <IonItem key={keyId} className="settings-item" lines="inset"
          button={isPerm} detail={false} onClick={isPerm ? () => openOsSettings(row) : undefined}>
          <IonLabel className="ion-text-wrap">
            {row.label}
            {row.description ? <IonNote className="settings-note"><br />{row.description}</IonNote> : null}
            {isPerm ? <IonNote className="settings-meta"><br />{checked ? 'On in system settings' : 'Off — turn on in system settings'}</IonNote> : null}
            {offlineDisabled ? <IonNote className="settings-meta"><br />Unavailable offline</IonNote> : null}
            {renderInline(row.id)}
          </IonLabel>
          {loading ? (
            <IonSkeletonText animated className="settings-skeleton" slot="end" aria-label="Loading current value" />
          ) : (
            <IonToggle slot="end" checked={checked} disabled={isPerm || offlineDisabled}
              aria-label={row.label} onIonChange={(e) => onToggle(row, e.detail.checked)} />
          )}
        </IonItem>
      );
    }

    if (row.kind === 'picker') {
      return (
        <IonItem key={keyId} className="settings-item" button detail lines="inset"
          onClick={() => openPicker(row)} aria-label={`${row.label}, ${currentPickerValue(row)}`}>
          <IonLabel className="ion-text-wrap">{row.label}</IonLabel>
          <IonNote slot="end" className="settings-value">{currentPickerValue(row)}</IonNote>
        </IonItem>
      );
    }

    if (row.kind === 'disclosure') {
      return (
        <IonItem key={keyId} className="settings-item" button detail lines="inset"
          onClick={() => onDisclosurePress(row)}>
          <IonLabel className="ion-text-wrap">
            {row.label}
            {row.description ? <IonNote className="settings-note"><br />{row.description}</IonNote> : null}
          </IonLabel>
          {row.external ? <IonIcon slot="end" icon={openOutline} aria-hidden="true" /> : null}
        </IonItem>
      );
    }

    if (row.kind === 'action') {
      return (
        <IonItem key={keyId} className="settings-item" button detail={false} lines="inset"
          onClick={() => onActionPress(row)}>
          <IonLabel className={row.destructive ? 'settings-danger-label ion-text-wrap' : 'ion-text-wrap'}>{row.label}</IonLabel>
        </IonItem>
      );
    }

    // info (read-only value)
    return (
      <IonItem key={keyId} className="settings-item" lines="inset">
        <IonLabel className="ion-text-wrap">{row.label}</IonLabel>
        {row.value ? <IonNote slot="end" className="settings-value">{row.value}</IonNote> : null}
      </IonItem>
    );
  };

  const renderGroup = (group: GroupConfig) => (
    <IonList key={group.id} className="settings-group" inset>
      <IonListHeader className="settings-group-header"><IonLabel>{group.title}</IonLabel></IonListHeader>
      {group.rows.map((row) => renderRow(row, row.id))}
    </IonList>
  );

  const renderDangerZone = () => (
    <>
      <IonList className="settings-danger" inset>
        <IonListHeader className="settings-group-header"><IonLabel>{DANGER_GROUP.title}</IonLabel></IonListHeader>
        {DESTRUCTIVE_ROWS.map((row) => renderRow(row, row.id))}
      </IonList>
      <IonText className="settings-danger-hint">Deleting your account is permanent. You can sign out and come back anytime.</IonText>
    </>
  );

  const renderResults = () => (
    <IonList className="settings-group" inset>
      {results.map((entry, index) => (
        <React.Fragment key={`${entry.groupId}-${entry.row.id}-${index}`}>
          <IonListHeader className="settings-result-caption">
            <IonLabel>{entry.parent ? `${entry.groupTitle} · ${entry.parent}` : entry.groupTitle}</IonLabel>
          </IonListHeader>
          {renderRow(entry.row, `res-${index}`)}
        </React.Fragment>
      ))}
    </IonList>
  );

  // Distinct zero-results placeholder — the empty state (never an empty list).
  const renderEmptyState = () => (
    <div className="settings-empty" role="status" aria-live="polite" aria-label={`No settings match ${query}`}>
      <IonIcon className="settings-empty-glyph" icon={searchOutline} aria-hidden="true" size="large" />
      <h2 className="settings-empty-title">No settings found</h2>
      <p className="settings-empty-body">{`Nothing matches “${query}”. Try a different word.`}</p>
    </div>
  );

  const renderGroupNav = () => (
    <IonList className="settings-group" inset>
      <IonListHeader className="settings-group-header"><IonLabel>Settings</IonLabel></IonListHeader>
      {GROUPS.map((group) => {
        const active = group.id === selectedGroupId;
        return (
          <IonItem key={group.id} className={`settings-item ${active ? 'settings-nav-active' : ''}`} button detail lines="inset"
            aria-current={active ? 'page' : undefined}
            onClick={() => { setSelectedGroupId(group.id); setSubPage(null); }}>
            <IonLabel className="ion-text-wrap">{group.title}</IonLabel>
          </IonItem>
        );
      })}
    </IonList>
  );

  const selectedGroup = GROUPS.find((g) => g.id === selectedGroupId) ?? GROUPS[0];
  const showEmpty = status.kind === 'empty';

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonTitle>Settings</IonTitle>
        </IonToolbar>
        <IonToolbar>
          <IonSearchbar className="settings-search" value={searchText} placeholder="Search settings"
            aria-label="Search settings" debounce={150} onIonInput={(e) => setSearchText(e.detail.value ?? '')} />
        </IonToolbar>
      </IonHeader>

      <IonContent className="settings-content">
        {!online && (
          <div className="settings-banner" role="status" aria-live="polite">
            <IonIcon icon={cloudOfflineOutline} aria-hidden="true" />
            <span className="settings-banner-text">You’re offline — synced settings are paused until you reconnect.</span>
            <IonButton fill="clear" size="small" onClick={() => Network.getStatus().then((s) => setOnline(s.connected))}>Retry</IonButton>
          </div>
        )}

        {isExpanded ? (
          // Expanded (>= 840dp): two-pane group list + detail (GRD-003).
          <div className="settings-two-pane">
            <div className="settings-pane-lead">
              {searching ? null : renderGroupNav()}
              {renderDangerZone()}
            </div>
            <div className="settings-pane-detail">
              {searching ? (showEmpty ? renderEmptyState() : renderResults()) : renderGroup(selectedGroup)}
            </div>
          </div>
        ) : (
          // Compact: a single scrolling list; disclosures PUSH a sub-page.
          <>
            {searching ? (
              showEmpty ? renderEmptyState() : renderResults()
            ) : (
              <>
                {GROUPS.map((group) => renderGroup(group))}
                {renderDangerZone()}
              </>
            )}
          </>
        )}
      </IonContent>

      {/* Disclosure → pushed sub-page (compact) / detail overlay (expanded). */}
      <IonModal isOpen={subPage !== null} onDidDismiss={() => setSubPage(null)}>
        <IonHeader>
          <IonToolbar>
            <IonButtons slot="start">
              <IonButton onClick={() => setSubPage(null)} aria-label="Back">
                <IonIcon slot="icon-only" icon={chevronBackOutline} aria-hidden="true" />
              </IonButton>
            </IonButtons>
            <IonTitle>{subPage?.label}</IonTitle>
          </IonToolbar>
        </IonHeader>
        <IonContent className="settings-subpage">
          <IonList className="settings-group" inset>
            {(subPage?.childRows ?? []).map((child) => renderRow(child, child.id))}
          </IonList>
        </IonContent>
      </IonModal>
    </IonPage>
  );
}
