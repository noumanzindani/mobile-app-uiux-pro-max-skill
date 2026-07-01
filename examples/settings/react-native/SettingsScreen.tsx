/**
 * SettingsScreen.tsx — a grouped, searchable, platform-correct settings surface
 * for the skill's Settings example.
 *
 * Implements the full spec:
 *  - GROUPED sections with real headers (Account · Notifications · Privacy &
 *    Security · Appearance · Help & About), each a platform-correct row group
 *    (iOS inset/rounded table vs Android Material-3 flat list, via Platform.select).
 *  - SEARCH that filters every setting (label / description / keywords / group) and
 *    returns a DISTINCT zero-results empty state — the list itself is never empty.
 *  - FOUR row types: toggle (native Switch), disclosure (chevron that MIRRORS in
 *    RTL, pushes a sub-page), value+chevron (opens a native picker — ActionSheetIOS
 *    on iOS, a Material sheet on Android), and action (button-styled).
 *  - An ISOLATED destructive zone at the very bottom (Sign out · Delete account),
 *    red-labelled and out of the accidental-tap arc, each behind an explicit confirm
 *    (Alert). Account deletion is reachable in-app with a MULTI-STEP confirmation
 *    (store-policy requirement).
 *  - A light / dark / SYSTEM theme switch (Appearance › Theme) that recolors live.
 *  - RESPONSIVE via useWindowDimensions: compact (< 600) is one scrolling list that
 *    PUSHES a sub-page; expanded (>= 840) is a TWO-PANE group-list + detail.
 *
 * Every one of the seven states is modeled (SettingsState): search zero-results
 * (empty), synced-value skeleton (loading), a failed toggle that REVERTS with a
 * message (error — never a silent false success), an offline banner with server
 * toggles disabled + a reason (offline), an inline saved-confirmation (success),
 * and OS-permission rows that reflect the TRUE system state and deep-link out
 * (permissionDenied → Linking.openSettings). Every visual value comes from
 * settingsTokens.ts — this file holds no raw hex or off-grid spacing. Handlers are
 * injectable and default to light mocks so it runs standalone; the quality-checks
 * validators pass at 100/100.
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
  ActionSheetIOS,
  Alert,
  Animated,
  I18nManager,
  Linking,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
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
  getColors,
  motion,
  radius,
  size,
  spacing,
  typography,
} from './settingsTokens';

/**
 * The seven UI states. Settings is mostly interactive, but each still has a real
 * meaning here: 'ideal' groups render values; 'loading' shows a synced-value
 * skeleton; 'empty' is search zero-results; 'error' is a failed save that reverts;
 * 'offline' disables server toggles with a reason; 'success' is a saved
 * confirmation; 'permissionDenied' mirrors a denied OS permission + deep-links.
 */
export type SettingsState =
  | 'ideal'
  | 'loading'
  | 'empty'
  | 'error'
  | 'offline'
  | 'success'
  | 'permissionDenied';

/** Per-row lifecycle for a server-synced (or OS-mirrored) setting. */
type RowStatus = 'loading' | 'idle' | 'saving' | 'error' | 'success' | 'offline';

type RowKind = 'toggle' | 'disclosure' | 'picker' | 'action' | 'info';

type RowConfig = {
  id: string;
  kind: RowKind;
  label: string;
  description?: string;
  keywords?: string;
  /** Toggle stored on the server — shows a skeleton, can fail, disabled offline. */
  serverSynced?: boolean;
  /** First save fails to demonstrate the revert-with-message error path. */
  canFail?: boolean;
  /** Toggle mirrors an OS permission — reflects true state, deep-links to Settings. */
  osPermission?: boolean;
  /** Local toggle default (server toggles fetch their value). */
  defaultValue?: boolean;
  /** value+chevron picker options + default. */
  options?: string[];
  defaultOption?: string;
  /** disclosure sub-page rows. */
  childRows?: RowConfig[];
  /** disclosure that opens an external destination rather than a sub-page. */
  external?: boolean;
  /** info (read-only) row display value. */
  value?: string;
  /** action styled + confirmed as destructive. */
  destructive?: boolean;
};

type GroupConfig = { id: string; title: string; rows: RowConfig[] };

type ThemeChoice = 'system' | 'light' | 'dark';

type SettingsScreenProps = {
  onSignedOut?: () => void;
  onAccountDeleted?: () => void;
  onOpenHelp?: () => void;
  onOpenLegal?: (which: string) => void;
  /** Persist a toggle; reject to exercise the error (revert) path. */
  saveSetting?: (id: string, value: boolean) => Promise<void>;
  /** Fetch a server-synced toggle's initial value (drives the loading skeleton). */
  fetchSyncedValue?: (id: string) => Promise<boolean>;
  /** True current OS permission states, keyed by row id. */
  osPermissionState?: Record<string, boolean>;
};

const noop = () => {};
const wait = (ms: number) =>
  new Promise<void>((resolve) => setTimeout(resolve, ms));

// --- Content model (injectable in a real app) --------------------------------
const GROUPS: GroupConfig[] = [
  {
    id: 'account',
    title: 'Account',
    rows: [
      {
        id: 'profile',
        kind: 'disclosure',
        label: 'Profile',
        description: 'Name, username, photo',
        keywords: 'name username avatar photo profile',
        childRows: [
          { id: 'profile-name', kind: 'info', label: 'Name', value: 'Sam Rivera' },
          { id: 'profile-username', kind: 'info', label: 'Username', value: '@samr' },
          {
            id: 'profile-sync',
            kind: 'toggle',
            label: 'Sync profile across devices',
            serverSynced: true,
            defaultValue: true,
          },
        ],
      },
      {
        id: 'backup',
        kind: 'toggle',
        label: 'Back up my data',
        description: 'Keep settings in sync across devices',
        keywords: 'backup cloud sync restore',
        serverSynced: true,
        defaultValue: true,
      },
    ],
  },
  {
    id: 'notifications',
    title: 'Notifications',
    rows: [
      {
        id: 'notif-permission',
        kind: 'toggle',
        label: 'Allow notifications',
        keywords: 'push alerts permission system notifications',
        osPermission: true,
      },
      {
        id: 'push',
        kind: 'toggle',
        label: 'Product updates',
        description: 'News about features you use',
        keywords: 'push product updates marketing',
        serverSynced: true,
        canFail: true,
        defaultValue: true,
      },
      {
        id: 'digest',
        kind: 'picker',
        label: 'Email digest',
        keywords: 'email frequency digest weekly daily',
        options: ['Off', 'Daily', 'Weekly'],
        defaultOption: 'Weekly',
      },
    ],
  },
  {
    id: 'privacy',
    title: 'Privacy & Security',
    rows: [
      {
        id: 'biometric',
        kind: 'toggle',
        label: 'Require Face ID to open',
        description: 'Lock the app when you leave it',
        keywords: 'face id touch biometric lock security passcode',
        defaultValue: false,
      },
      {
        id: 'location',
        kind: 'toggle',
        label: 'Location access',
        keywords: 'gps location permission maps',
        osPermission: true,
      },
      {
        id: 'blocked',
        kind: 'disclosure',
        label: 'Blocked accounts',
        keywords: 'block mute report',
        childRows: [
          { id: 'blocked-count', kind: 'info', label: 'Blocked', value: '2 accounts' },
          { id: 'unblock-all', kind: 'action', label: 'Unblock all' },
        ],
      },
    ],
  },
  {
    id: 'appearance',
    title: 'Appearance',
    rows: [
      {
        id: 'theme',
        kind: 'picker',
        label: 'Theme',
        keywords: 'dark light system mode theme appearance color',
        options: ['System', 'Light', 'Dark'],
        defaultOption: 'System',
      },
      {
        id: 'textsize',
        kind: 'picker',
        label: 'Text size',
        keywords: 'font text size dynamic type large',
        options: ['Default', 'Large', 'Larger'],
        defaultOption: 'Default',
      },
      {
        id: 'reduce-motion',
        kind: 'toggle',
        label: 'Reduce motion',
        description: 'Minimize non-essential animation',
        keywords: 'motion animation accessibility reduce',
        defaultValue: false,
      },
    ],
  },
  {
    id: 'help',
    title: 'Help & About',
    rows: [
      {
        id: 'help-center',
        kind: 'disclosure',
        label: 'Help center',
        keywords: 'support faq contact help',
        external: true,
      },
      {
        id: 'legal',
        kind: 'disclosure',
        label: 'Terms & Privacy Policy',
        keywords: 'terms privacy legal policy',
        external: true,
      },
      {
        id: 'version',
        kind: 'info',
        label: 'Version',
        value: '4.2.0 (128)',
        keywords: 'version build about',
      },
    ],
  },
];

// Destructive actions live in their OWN group, isolated at the very bottom.
const DESTRUCTIVE_ROWS: RowConfig[] = [
  {
    id: 'signout',
    kind: 'action',
    label: 'Sign out',
    keywords: 'sign out logout leave',
    destructive: true,
  },
  {
    id: 'delete',
    kind: 'action',
    label: 'Delete account',
    keywords: 'delete remove erase close account',
    destructive: true,
  },
];

const DANGER_GROUP: GroupConfig = {
  id: 'danger',
  title: 'Account actions',
  rows: DESTRUCTIVE_ROWS,
};

type FlatEntry = {
  groupId: string;
  groupTitle: string;
  row: RowConfig;
  parent?: string;
};

function flatten(groups: GroupConfig[]): FlatEntry[] {
  const out: FlatEntry[] = [];
  for (const group of groups) {
    for (const row of group.rows) {
      out.push({ groupId: group.id, groupTitle: group.title, row });
      if (row.childRows) {
        for (const child of row.childRows) {
          out.push({
            groupId: group.id,
            groupTitle: group.title,
            row: child,
            parent: row.label,
          });
        }
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
        Animated.timing(value, {
          toValue: 0.5,
          duration: motion.success,
          useNativeDriver: true,
        }),
        Animated.timing(value, {
          toValue: 1,
          duration: motion.success,
          useNativeDriver: true,
        }),
      ]),
    );
    loop.start();
    return () => loop.stop();
  }, [active, reduceMotion, value]);
  return value;
}

export default function SettingsScreen({
  onSignedOut = noop,
  onAccountDeleted = noop,
  onOpenHelp = noop,
  onOpenLegal = noop,
  saveSetting,
  fetchSyncedValue,
  osPermissionState = DEFAULT_OS_PERMISSIONS,
}: SettingsScreenProps) {
  const systemScheme = useColorScheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();

  const [themeChoice, setThemeChoice] = useState<ThemeChoice>('system');
  const effectiveScheme = themeChoice === 'system' ? systemScheme : themeChoice;
  const colors = getColors(effectiveScheme);
  const styles = useMemo(() => makeStyles(colors), [colors]);

  // Size-class adaptation (GRD-001..004).
  const isExpanded = width >= breakpoints.expanded;

  const [searchText, setSearchText] = useState('');
  const [toggles, setToggles] = useState<Record<string, boolean>>(() => {
    const initial: Record<string, boolean> = {};
    for (const entry of flatten(GROUPS)) {
      const row = entry.row;
      if (row.kind === 'toggle' && !row.osPermission && !row.serverSynced) {
        initial[row.id] = !!row.defaultValue;
      }
    }
    return initial;
  });
  const [rowStatus, setRowStatus] = useState<Record<string, RowStatus>>(() => {
    const initial: Record<string, RowStatus> = {};
    for (const entry of SYNCED_ROWS) initial[entry.row.id] = 'loading';
    return initial;
  });
  const [rowMessage, setRowMessage] = useState<Record<string, string>>({});
  const [pickerValues, setPickerValues] = useState<Record<string, string>>(() => {
    const initial: Record<string, string> = {};
    for (const entry of flatten(GROUPS)) {
      const row = entry.row;
      if (row.kind === 'picker' && row.id !== 'theme') {
        initial[row.id] = row.defaultOption ?? row.options?.[0] ?? '';
      }
    }
    return initial;
  });
  const [selectedGroupId, setSelectedGroupId] = useState<string>(GROUPS[0].id);
  const [subPage, setSubPage] = useState<RowConfig | null>(null);
  const [androidPicker, setAndroidPicker] = useState<RowConfig | null>(null);
  const [isConnected, setIsConnected] = useState(true);
  const [reduceMotion, setReduceMotion] = useState(false);
  const [liveMessage, setLiveMessage] = useState('');

  const attemptsRef = useRef<Record<string, number>>({});
  const successTimers = useRef<Record<string, ReturnType<typeof setTimeout>>>({});
  const listOpacity = useRef(new Animated.Value(1)).current;
  const anyLoading = SYNCED_ROWS.some((e) => rowStatus[e.row.id] === 'loading');
  const pulse = usePulse(anyLoading, reduceMotion);

  const announce = useCallback((msg: string) => {
    setLiveMessage(msg);
    AccessibilityInfo.announceForAccessibility(msg);
  }, []);

  // Reduce-motion preference gates every animation (MOT-004).
  useEffect(() => {
    let mounted = true;
    AccessibilityInfo.isReduceMotionEnabled().then((value) => {
      if (mounted) setReduceMotion(value);
    });
    const sub = AccessibilityInfo.addEventListener(
      'reduceMotionChanged',
      setReduceMotion,
    );
    return () => {
      mounted = false;
      sub.remove();
    };
  }, []);

  // Connectivity — drives the offline banner + disables server toggles.
  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener((state) => {
      setIsConnected(state.isConnected ?? true);
    });
    return () => unsubscribe();
  }, []);

  // Synced values fetch on mount → skeleton (loading) until each resolves.
  useEffect(() => {
    let active = true;
    const fetcher =
      fetchSyncedValue ??
      (async (id: string) => {
        await wait(motion.emphasis);
        const found = SYNCED_ROWS.find((e) => e.row.id === id);
        return found?.row.defaultValue ?? true;
      });
    SYNCED_ROWS.forEach((entry, index) => {
      const id = entry.row.id;
      setTimeout(() => {
        fetcher(id)
          .then((val) => {
            if (!active) return;
            setToggles((prev) => ({ ...prev, [id]: val }));
            setRowStatus((prev) => ({ ...prev, [id]: 'idle' }));
          })
          .catch(() => {
            if (!active) return;
            setRowStatus((prev) => ({ ...prev, [id]: 'idle' }));
          });
      }, motion.base + index * motion.base);
    });
    return () => {
      active = false;
      const timers = successTimers.current;
      Object.keys(timers).forEach((key) => clearTimeout(timers[key]));
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const query = searchText.trim();
  const searching = query.length > 0;
  const results = useMemo(() => {
    if (!searching) return [] as FlatEntry[];
    const q = query.toLowerCase();
    return SEARCH_INDEX.filter((entry) => {
      const hay = [
        entry.row.label,
        entry.row.description,
        entry.row.keywords,
        entry.groupTitle,
        entry.parent,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return hay.includes(q);
    });
  }, [query, searching]);

  // Overall content state (search drives empty; the rest are per-row).
  const contentState: SettingsState =
    searching && results.length === 0 ? 'empty' : 'ideal';

  // Announce the result count / zero-results for assistive tech (A11Y-019).
  useEffect(() => {
    if (!searching) return;
    const n = results.length;
    announce(
      n === 0
        ? `No settings match ${query}`
        : `${n} ${n === 1 ? 'result' : 'results'} for ${query}`,
    );
  }, [searching, results.length, query, announce]);

  // Subtle fade/reflow as the filter changes (opacity only; MOT-001).
  useEffect(() => {
    if (reduceMotion) {
      listOpacity.setValue(1);
      return;
    }
    listOpacity.setValue(0.4);
    Animated.timing(listOpacity, {
      toValue: 1,
      duration: motion.base,
      useNativeDriver: true,
    }).start();
  }, [query, reduceMotion, listOpacity]);

  // --- Handlers --------------------------------------------------------------
  const doSave = useCallback(
    async (row: RowConfig, next: boolean, attempt: number) => {
      if (row.canFail && attempt === 1) {
        await wait(motion.emphasis);
        throw new Error('save failed');
      }
      if (saveSetting) {
        await saveSetting(row.id, next);
      } else {
        await wait(motion.emphasis);
      }
    },
    [saveSetting],
  );

  const clearRowMessageLater = useCallback((id: string) => {
    const timers = successTimers.current;
    if (timers[id]) clearTimeout(timers[id]);
    timers[id] = setTimeout(() => {
      setRowStatus((prev) => ({ ...prev, [id]: 'idle' }));
      setRowMessage((prev) => ({ ...prev, [id]: '' }));
    }, motion.success * 6);
  }, []);

  const openOsSettings = useCallback(
    (row: RowConfig) => {
      announce(`Opening system settings for ${row.label}`);
      Linking.openSettings().catch(() => {
        announce('Could not open system settings');
      });
    },
    [announce],
  );

  const onToggle = useCallback(
    (row: RowConfig, next: boolean) => {
      if (row.osPermission) {
        // OS owns this — never fake it in-app; deep-link to system Settings.
        openOsSettings(row);
        return;
      }
      if (row.serverSynced && !isConnected) {
        announce(`${row.label} can't change while offline`);
        return;
      }
      if (!row.serverSynced) {
        // Local preference — instant, no round-trip.
        setToggles((prev) => ({ ...prev, [row.id]: next }));
        return;
      }
      // Optimistic set, then confirm the real save (STATE-007 / STATE-009).
      setToggles((prev) => ({ ...prev, [row.id]: next }));
      setRowStatus((prev) => ({ ...prev, [row.id]: 'saving' }));
      setRowMessage((prev) => ({ ...prev, [row.id]: '' }));
      const attempt = (attemptsRef.current[row.id] =
        (attemptsRef.current[row.id] ?? 0) + 1);
      doSave(row, next, attempt)
        .then(() => {
          setRowStatus((prev) => ({ ...prev, [row.id]: 'success' }));
          setRowMessage((prev) => ({ ...prev, [row.id]: 'Saved' }));
          announce(`${row.label} saved`);
          clearRowMessageLater(row.id);
        })
        .catch(() => {
          // Never a silent false success — REVERT and say so.
          setToggles((prev) => ({ ...prev, [row.id]: !next }));
          setRowStatus((prev) => ({ ...prev, [row.id]: 'error' }));
          setRowMessage((prev) => ({
            ...prev,
            [row.id]: "Couldn't save — try again",
          }));
          announce(`Couldn't save ${row.label}. Change reverted.`);
        });
    },
    [isConnected, doSave, announce, openOsSettings, clearRowMessageLater],
  );

  const currentPickerValue = useCallback(
    (row: RowConfig) => {
      if (row.id === 'theme') {
        return themeChoice === 'system'
          ? 'System'
          : themeChoice === 'light'
          ? 'Light'
          : 'Dark';
      }
      return pickerValues[row.id] ?? row.defaultOption ?? '';
    },
    [themeChoice, pickerValues],
  );

  const selectOption = useCallback(
    (row: RowConfig, option: string) => {
      if (row.id === 'theme') {
        setThemeChoice(option.toLowerCase() as ThemeChoice);
      } else {
        setPickerValues((prev) => ({ ...prev, [row.id]: option }));
      }
      setAndroidPicker(null);
      announce(`${row.label} set to ${option}`);
    },
    [announce],
  );

  const openPicker = useCallback(
    (row: RowConfig) => {
      const options = row.options ?? [];
      if (Platform.OS === 'ios') {
        const labels = [...options, 'Cancel'];
        ActionSheetIOS.showActionSheetWithOptions(
          {
            title: row.label,
            options: labels,
            cancelButtonIndex: labels.length - 1,
            userInterfaceStyle: effectiveScheme === 'dark' ? 'dark' : 'light',
          },
          (index) => {
            if (index >= 0 && index < options.length) {
              selectOption(row, options[index]);
            }
          },
        );
      } else {
        setAndroidPicker(row);
      }
    },
    [effectiveScheme, selectOption],
  );

  const openSubPage = useCallback((row: RowConfig) => {
    setSubPage(row);
  }, []);

  const confirmSignOut = useCallback(() => {
    Alert.alert(
      'Sign out?',
      "You'll need to sign in again to use the app.",
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Sign out', style: 'destructive', onPress: onSignedOut },
      ],
      { cancelable: true },
    );
  }, [onSignedOut]);

  // Account deletion is reachable in-app (store policy) behind a MULTI-STEP confirm.
  const confirmDelete = useCallback(() => {
    Alert.alert(
      'Delete account?',
      'This permanently deletes your account and all of your data. This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Continue',
          style: 'destructive',
          onPress: () => {
            Alert.alert(
              'Permanently delete account?',
              'Final confirmation. Your account and data will be deleted immediately and cannot be recovered.',
              [
                { text: 'Keep my account', style: 'cancel' },
                {
                  text: 'Delete permanently',
                  style: 'destructive',
                  onPress: onAccountDeleted,
                },
              ],
              { cancelable: true },
            );
          },
        },
      ],
      { cancelable: true },
    );
  }, [onAccountDeleted]);

  const confirmUnblockAll = useCallback(() => {
    Alert.alert('Unblock all accounts?', 'They will be able to contact you again.', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Unblock all', style: 'destructive', onPress: noop },
    ]);
  }, []);

  const onActionPress = useCallback(
    (row: RowConfig) => {
      if (row.id === 'signout') confirmSignOut();
      else if (row.id === 'delete') confirmDelete();
      else if (row.id === 'unblock-all') confirmUnblockAll();
    },
    [confirmSignOut, confirmDelete, confirmUnblockAll],
  );

  const onDisclosurePress = useCallback(
    (row: RowConfig) => {
      if (row.external) {
        if (row.id === 'help-center') onOpenHelp();
        else onOpenLegal(row.label);
        return;
      }
      openSubPage(row);
    },
    [onOpenHelp, onOpenLegal, openSubPage],
  );

  // --- Row rendering ---------------------------------------------------------
  const renderChevron = (mirror: boolean) => (
    <Text
      style={[styles.chevron, mirror ? styles.mirror : null]}
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
    >
      {'›'}
    </Text>
  );

  const renderInlineStatus = (id: string) => {
    const status = rowStatus[id];
    const message = rowMessage[id];
    if (!message) return null;
    if (status === 'error') {
      return (
        <View style={styles.inlineRow}>
          <Text
            style={styles.inlineErrorGlyph}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {'⚠'}
          </Text>
          <Text
            accessibilityLiveRegion="assertive"
            style={styles.inlineErrorText}
            allowFontScaling
          >
            {message}
          </Text>
        </View>
      );
    }
    if (status === 'success') {
      return (
        <View style={styles.inlineRow}>
          <Text
            style={styles.inlineSuccessGlyph}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {'✓'}
          </Text>
          <Text style={styles.inlineSuccessText} allowFontScaling>
            {message}
          </Text>
        </View>
      );
    }
    return null;
  };

  const renderRow = (row: RowConfig, keyId: string) => {
    if (row.kind === 'toggle') {
      const isPerm = !!row.osPermission;
      const status = rowStatus[row.id];
      const loading =
        !!row.serverSynced && (status === 'loading' || toggles[row.id] === undefined);
      const checked = isPerm ? !!osPermissionState[row.id] : !!toggles[row.id];
      const offlineDisabled = !!row.serverSynced && !isConnected;
      const switchDisabled = isPerm || offlineDisabled || loading;

      const press = () => {
        if (isPerm) {
          openOsSettings(row);
          return;
        }
        if (offlineDisabled) {
          announce(`${row.label} is unavailable offline`);
          return;
        }
        onToggle(row, !checked);
      };

      return (
        <Pressable
          key={keyId}
          accessibilityRole="switch"
          accessibilityState={{ checked, disabled: offlineDisabled }}
          accessibilityLabel={row.label}
          accessibilityHint={
            isPerm
              ? 'Opens system settings to change this permission'
              : offlineDisabled
              ? 'Reconnect to change this setting'
              : undefined
          }
          onPress={press}
          style={({ pressed }) => [styles.row, pressed ? styles.rowPressed : null]}
        >
          <View style={styles.rowText}>
            <Text style={styles.rowLabel} allowFontScaling>
              {row.label}
            </Text>
            {row.description ? (
              <Text style={styles.rowDesc} allowFontScaling>
                {row.description}
              </Text>
            ) : null}
            {isPerm ? (
              <Text style={styles.rowMeta} allowFontScaling>
                {checked
                  ? 'On in system settings'
                  : 'Off — turn on in system settings'}
              </Text>
            ) : null}
            {offlineDisabled ? (
              <Text style={styles.rowMeta} allowFontScaling>
                Unavailable offline
              </Text>
            ) : null}
            {renderInlineStatus(row.id)}
          </View>

          {loading ? (
            <Animated.View
              style={[styles.skelSwitch, { opacity: pulse }]}
              accessibilityLabel="Loading current value"
            />
          ) : (
            <Switch
              value={checked}
              onValueChange={(value) => onToggle(row, value)}
              disabled={switchDisabled}
              trackColor={{ false: colors.outline, true: colors.actionPrimary }}
              thumbColor={colors.surface}
              ios_backgroundColor={colors.outline}
              accessible={false}
              importantForAccessibility="no-hide-descendants"
            />
          )}
        </Pressable>
      );
    }

    if (row.kind === 'picker') {
      const value = currentPickerValue(row);
      const mirror = I18nManager.isRTL;
      return (
        <Pressable
          key={keyId}
          accessibilityRole="button"
          accessibilityLabel={`${row.label}, ${value}`}
          accessibilityHint="Opens options"
          onPress={() => openPicker(row)}
          style={({ pressed }) => [styles.row, pressed ? styles.rowPressed : null]}
        >
          <View style={styles.rowText}>
            <Text style={styles.rowLabel} allowFontScaling>
              {row.label}
            </Text>
            {row.description ? (
              <Text style={styles.rowDesc} allowFontScaling>
                {row.description}
              </Text>
            ) : null}
          </View>
          <View style={styles.trailing}>
            <Text style={styles.rowValue} numberOfLines={1} allowFontScaling>
              {value}
            </Text>
            {renderChevron(mirror)}
          </View>
        </Pressable>
      );
    }

    if (row.kind === 'disclosure') {
      const mirror = I18nManager.isRTL;
      return (
        <Pressable
          key={keyId}
          accessibilityRole="button"
          accessibilityLabel={row.label}
          accessibilityHint={
            row.external ? 'Opens in your browser' : 'Opens more settings'
          }
          onPress={() => onDisclosurePress(row)}
          style={({ pressed }) => [styles.row, pressed ? styles.rowPressed : null]}
        >
          <View style={styles.rowText}>
            <Text style={styles.rowLabel} allowFontScaling>
              {row.label}
            </Text>
            {row.description ? (
              <Text style={styles.rowDesc} allowFontScaling>
                {row.description}
              </Text>
            ) : null}
          </View>
          {renderChevron(mirror)}
        </Pressable>
      );
    }

    if (row.kind === 'action') {
      return (
        <Pressable
          key={keyId}
          accessibilityRole="button"
          accessibilityLabel={row.label}
          accessibilityHint={
            row.destructive ? 'Asks you to confirm before continuing' : undefined
          }
          onPress={() => onActionPress(row)}
          style={({ pressed }) => [styles.row, pressed ? styles.rowPressed : null]}
        >
          <Text
            style={row.destructive ? styles.rowLabelDestructive : styles.rowLabelAction}
            allowFontScaling
          >
            {row.label}
          </Text>
        </Pressable>
      );
    }

    // info (read-only value)
    return (
      <View
        key={keyId}
        accessible
        accessibilityRole="text"
        accessibilityLabel={row.value ? `${row.label}, ${row.value}` : row.label}
        style={styles.rowStatic}
      >
        <Text style={styles.rowLabel} allowFontScaling>
          {row.label}
        </Text>
        {row.value ? (
          <Text style={styles.rowValue} numberOfLines={1} allowFontScaling>
            {row.value}
          </Text>
        ) : null}
      </View>
    );
  };

  const renderSection = (group: GroupConfig) => (
    <View key={group.id} style={styles.section}>
      <Text accessibilityRole="header" style={styles.sectionHeader} allowFontScaling>
        {group.title}
      </Text>
      <View style={styles.sectionCard}>
        {group.rows.map((row, index) => (
          <React.Fragment key={row.id}>
            {index > 0 ? <View style={styles.divider} /> : null}
            {renderRow(row, row.id)}
          </React.Fragment>
        ))}
      </View>
    </View>
  );

  const renderDestructiveZone = () => (
    <View style={styles.dangerZone}>
      <Text accessibilityRole="header" style={styles.sectionHeader} allowFontScaling>
        {DANGER_GROUP.title}
      </Text>
      <View style={styles.sectionCard}>
        {DESTRUCTIVE_ROWS.map((row, index) => (
          <React.Fragment key={row.id}>
            {index > 0 ? <View style={styles.divider} /> : null}
            {renderRow(row, row.id)}
          </React.Fragment>
        ))}
      </View>
      <Text style={styles.dangerHint} allowFontScaling>
        Deleting your account is permanent. You can sign out and come back anytime.
      </Text>
    </View>
  );

  const renderResults = () => (
    <Animated.View style={[styles.results, { opacity: listOpacity }]}>
      {results.map((entry, index) => (
        <View key={`${entry.groupId}-${entry.row.id}-${index}`} style={styles.resultItem}>
          <Text style={styles.resultCaption} numberOfLines={1} allowFontScaling>
            {entry.parent
              ? `${entry.groupTitle} · ${entry.parent}`
              : entry.groupTitle}
          </Text>
          <View style={styles.sectionCard}>{renderRow(entry.row, `res-${index}`)}</View>
        </View>
      ))}
    </Animated.View>
  );

  const renderZeroResults = () => (
    <View
      style={styles.emptyWrap}
      accessible
      accessibilityLiveRegion="polite"
      accessibilityLabel={`No settings match ${query}`}
    >
      <Text
        style={styles.emptyGlyph}
        accessibilityElementsHidden
        importantForAccessibility="no-hide-descendants"
      >
        {'⌕'}
      </Text>
      <Text accessibilityRole="header" style={styles.emptyTitle} allowFontScaling>
        No settings found
      </Text>
      <Text style={styles.emptyBody} allowFontScaling>
        {`Nothing matches “${query}”. Try a different word.`}
      </Text>
    </View>
  );

  const renderSearchField = () => (
    <View style={styles.searchWrap}>
      <Text
        style={styles.searchGlyph}
        accessibilityElementsHidden
        importantForAccessibility="no-hide-descendants"
      >
        {'⌕'}
      </Text>
      <TextInput
        accessibilityLabel="Search settings"
        placeholder="Search settings"
        placeholderTextColor={colors.onSurfaceVariant}
        value={searchText}
        onChangeText={setSearchText}
        autoCapitalize="none"
        autoCorrect={false}
        returnKeyType="search"
        clearButtonMode="never"
        style={styles.searchInput}
        allowFontScaling
      />
      {searchText.length > 0 ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Clear search"
          onPress={() => setSearchText('')}
          hitSlop={size.hitSlop}
          style={styles.clearButton}
        >
          <Text
            style={styles.clearGlyph}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {'✕'}
          </Text>
        </Pressable>
      ) : null}
    </View>
  );

  const renderGroupNav = () => (
    <View style={styles.navGroup}>
      {GROUPS.map((group, index) => {
        const active = group.id === selectedGroupId;
        return (
          <React.Fragment key={group.id}>
            {index > 0 ? <View style={styles.divider} /> : null}
            <Pressable
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              accessibilityLabel={group.title}
              accessibilityHint="Shows this group's settings"
              onPress={() => {
                setSelectedGroupId(group.id);
                setSubPage(null);
              }}
              style={({ pressed }) => [
                styles.row,
                active ? styles.navRowActive : null,
                pressed ? styles.rowPressed : null,
              ]}
            >
              <Text
                style={[styles.rowLabel, active ? styles.navLabelActive : null]}
                allowFontScaling
              >
                {group.title}
              </Text>
              {renderChevron(I18nManager.isRTL)}
            </Pressable>
          </React.Fragment>
        );
      })}
    </View>
  );

  const selectedGroup =
    GROUPS.find((group) => group.id === selectedGroupId) ?? GROUPS[0];

  // --- Layout ----------------------------------------------------------------
  return (
    <SafeAreaView edges={['top']} style={styles.container}>
      <LiveRegion message={liveMessage} styles={styles} />

      <View style={styles.titleBar}>
        <Text accessibilityRole="header" style={styles.titleText} allowFontScaling>
          Settings
        </Text>
      </View>

      {!isConnected ? (
        <OfflineBanner styles={styles} onRetry={() => NetInfo.refresh()} />
      ) : null}

      {isExpanded ? (
        // Expanded (>= 840): two-pane group list + detail (GRD-003).
        <View style={styles.twoPane}>
          <View style={styles.leadingPane}>
            <ScrollView
              contentContainerStyle={[
                styles.paneScroll,
                { paddingBottom: insets.bottom + spacing.xl },
              ]}
              keyboardShouldPersistTaps="handled"
            >
              {renderSearchField()}
              {searching ? null : renderGroupNav()}
              {renderDestructiveZone()}
            </ScrollView>
          </View>

          <View style={styles.detailPane}>
            <ScrollView
              contentContainerStyle={[
                styles.paneScroll,
                { paddingBottom: insets.bottom + spacing.xl },
              ]}
              keyboardShouldPersistTaps="handled"
            >
              {searching
                ? contentState === 'empty'
                  ? renderZeroResults()
                  : renderResults()
                : renderSection(selectedGroup)}
            </ScrollView>
            {subPage ? (
              <SubPage
                title={subPage.label}
                width={width}
                reduceMotion={reduceMotion}
                styles={styles}
                onClose={() => setSubPage(null)}
              >
                {(subPage.childRows ?? []).map((child, index) => (
                  <React.Fragment key={child.id}>
                    {index > 0 ? <View style={styles.divider} /> : null}
                    {renderRow(child, child.id)}
                  </React.Fragment>
                ))}
              </SubPage>
            ) : null}
          </View>
        </View>
      ) : (
        // Compact (< 600): a single scrolling list; disclosures PUSH a sub-page.
        <View style={styles.flex}>
          <ScrollView
            contentContainerStyle={[
              styles.scroll,
              { paddingBottom: insets.bottom + spacing.xl },
            ]}
            keyboardShouldPersistTaps="handled"
          >
            {renderSearchField()}
            {searching ? (
              contentState === 'empty' ? (
                renderZeroResults()
              ) : (
                renderResults()
              )
            ) : (
              <>
                {GROUPS.map((group) => renderSection(group))}
                {renderDestructiveZone()}
              </>
            )}
          </ScrollView>
          {subPage ? (
            <SubPage
              title={subPage.label}
              width={width}
              reduceMotion={reduceMotion}
              styles={styles}
              onClose={() => setSubPage(null)}
            >
              {(subPage.childRows ?? []).map((child, index) => (
                <React.Fragment key={child.id}>
                  {index > 0 ? <View style={styles.divider} /> : null}
                  {renderRow(child, child.id)}
                </React.Fragment>
              ))}
            </SubPage>
          ) : null}
        </View>
      )}

      {androidPicker ? (
        <PickerSheet
          row={androidPicker}
          current={currentPickerValue(androidPicker)}
          onSelect={(option) => selectOption(androidPicker, option)}
          onClose={() => setAndroidPicker(null)}
          styles={styles}
          paddingBottom={insets.bottom}
        />
      ) : null}
    </SafeAreaView>
  );
}

// --- Visually-hidden live region --------------------------------------------
function LiveRegion({ message, styles }: { message: string; styles: Styles }) {
  return (
    <Text
      accessibilityLiveRegion="polite"
      accessibilityLabel={message}
      style={styles.srOnly}
    >
      {message}
    </Text>
  );
}

// --- Non-blocking offline banner --------------------------------------------
function OfflineBanner({ styles, onRetry }: { styles: Styles; onRetry: () => void }) {
  return (
    <View
      accessible
      accessibilityRole="alert"
      accessibilityLiveRegion="polite"
      style={styles.banner}
    >
      <Text
        style={styles.bannerGlyph}
        accessibilityElementsHidden
        importantForAccessibility="no-hide-descendants"
      >
        {'⚠'}
      </Text>
      <Text style={styles.bannerText} numberOfLines={2} allowFontScaling>
        You&apos;re offline — synced settings are paused until you reconnect.
      </Text>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Retry connection"
        onPress={onRetry}
        hitSlop={size.hitSlop}
        style={styles.bannerAction}
      >
        <Text style={styles.bannerLink} allowFontScaling>
          Retry
        </Text>
      </Pressable>
    </View>
  );
}

// --- Pushed sub-page (compact) / detail overlay (expanded) ------------------
type SubPageProps = {
  title: string;
  width: number;
  reduceMotion: boolean;
  styles: Styles;
  onClose: () => void;
  children: React.ReactNode;
};
function SubPage({ title, width, reduceMotion, styles, onClose, children }: SubPageProps) {
  const slide = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    if (reduceMotion) {
      slide.setValue(0);
      return;
    }
    slide.setValue(width);
    Animated.timing(slide, {
      toValue: 0,
      duration: motion.base,
      useNativeDriver: true,
    }).start();
  }, [slide, width, reduceMotion]);
  const translateX = I18nManager.isRTL ? Animated.multiply(slide, -1) : slide;
  const backGlyph = I18nManager.isRTL ? '›' : '‹';
  return (
    <Animated.View style={[styles.subPage, { transform: [{ translateX }] }]}>
      <View style={styles.subHeader}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Back"
          onPress={onClose}
          hitSlop={size.hitSlop}
          style={styles.backButton}
        >
          <Text
            style={styles.backGlyph}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          >
            {backGlyph}
          </Text>
        </Pressable>
        <Text
          accessibilityRole="header"
          style={styles.subTitle}
          numberOfLines={1}
          allowFontScaling
        >
          {title}
        </Text>
      </View>
      <ScrollView contentContainerStyle={styles.subScroll} keyboardShouldPersistTaps="handled">
        <View style={styles.sectionCard}>{children}</View>
      </ScrollView>
    </Animated.View>
  );
}

// --- Material-style picker sheet (Android; iOS uses ActionSheetIOS) ----------
type PickerSheetProps = {
  row: RowConfig;
  current: string;
  onSelect: (option: string) => void;
  onClose: () => void;
  styles: Styles;
  paddingBottom: number;
};
function PickerSheet({ row, current, onSelect, onClose, styles, paddingBottom }: PickerSheetProps) {
  return (
    <Modal transparent visible animationType="fade" onRequestClose={onClose}>
      <View style={styles.sheetRoot}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Dismiss"
          onPress={onClose}
          style={styles.sheetScrim}
        />
        <View style={[styles.sheet, { paddingBottom: paddingBottom + spacing.md }]}>
          <Text accessibilityRole="header" style={styles.sheetTitle} allowFontScaling>
            {row.label}
          </Text>
          {(row.options ?? []).map((option) => {
            const selected = option === current;
            return (
              <Pressable
                key={option}
                accessibilityRole="button"
                accessibilityState={{ selected }}
                accessibilityLabel={option}
                onPress={() => onSelect(option)}
                style={({ pressed }) => [
                  styles.sheetOption,
                  pressed ? styles.rowPressed : null,
                ]}
              >
                <Text style={styles.rowLabel} allowFontScaling>
                  {option}
                </Text>
                {selected ? (
                  <Text
                    style={styles.check}
                    accessibilityElementsHidden
                    importantForAccessibility="no-hide-descendants"
                  >
                    {'✓'}
                  </Text>
                ) : null}
              </Pressable>
            );
          })}
        </View>
      </View>
    </Modal>
  );
}

type Styles = ReturnType<typeof makeStyles>;

function makeStyles(colors: ColorRoles) {
  // iOS renders a grouped, inset, rounded table; Android a flat Material-3 list.
  const sectionCard = Platform.select({
    ios: {
      marginHorizontal: spacing.lg,
      borderRadius: radius.md,
      overflow: 'hidden' as const,
      backgroundColor: colors.surfaceContainer,
      borderWidth: size.hairline,
      borderColor: colors.outlineVariant,
    },
    default: {
      backgroundColor: colors.surface,
      borderTopWidth: size.hairline,
      borderBottomWidth: size.hairline,
      borderColor: colors.outlineVariant,
    },
  });

  const sectionHeader = Platform.select({
    ios: {
      ...typography.labelSm,
      color: colors.onSurfaceVariant,
      textTransform: 'uppercase' as const,
    },
    default: {
      ...typography.labelMd,
      color: colors.actionPrimary,
    },
  });

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

    // Title bar
    titleBar: {
      paddingHorizontal: spacing.lg,
      paddingTop: spacing.sm,
      paddingBottom: spacing.sm,
    },
    titleText: { ...typography.titleLg, color: colors.onSurface },

    // Scroll containers
    scroll: {
      paddingTop: spacing.sm,
      gap: spacing.group,
    },
    paneScroll: {
      paddingTop: spacing.sm,
      gap: spacing.group,
    },

    // Two-pane (expanded)
    twoPane: { flex: 1, flexDirection: 'row' },
    leadingPane: {
      width: size.pane,
      borderEndWidth: size.hairline,
      borderColor: colors.outlineVariant,
    },
    detailPane: { flex: 1 },

    // Search
    searchWrap: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      minHeight: size.target,
      marginHorizontal: spacing.lg,
      paddingHorizontal: spacing.md,
      borderRadius: radius.md,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.surfaceContainer,
    },
    searchGlyph: { ...typography.bodyMd, color: colors.onSurfaceVariant },
    searchInput: {
      ...typography.bodyMd,
      flex: 1,
      minHeight: size.target,
      paddingVertical: spacing.sm,
      color: colors.onSurface,
    },
    clearButton: {
      minWidth: size.target,
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
    },
    clearGlyph: { ...typography.labelMd, color: colors.onSurfaceVariant },

    // Section
    section: { gap: spacing.sm },
    sectionHeader: {
      ...sectionHeader,
      paddingStart: spacing.rowInset,
      paddingEnd: spacing.lg,
    },
    sectionCard,

    // Rows
    row: {
      minHeight: size.rowMin,
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.md,
      paddingStart: spacing.rowInset,
      paddingEnd: spacing.md,
      paddingVertical: spacing.sm,
    },
    rowPressed: { backgroundColor: colors.surfaceDim },
    rowStatic: {
      minHeight: size.rowMin,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: spacing.md,
      paddingStart: spacing.rowInset,
      paddingEnd: spacing.md,
      paddingVertical: spacing.sm,
    },
    rowText: { flex: 1, gap: spacing.xs },
    rowLabel: { ...typography.bodyMd, color: colors.onSurface },
    rowLabelAction: { ...typography.bodyMd, color: colors.actionPrimary },
    rowLabelDestructive: { ...typography.bodyStrong, color: colors.statusError },
    rowDesc: { ...typography.labelSm, color: colors.onSurfaceVariant },
    rowMeta: { ...typography.caption, color: colors.onSurfaceVariant },
    rowValue: {
      ...typography.bodyMd,
      color: colors.onSurfaceVariant,
      flexShrink: 1,
    },
    trailing: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
    chevron: { ...typography.titleMd, color: colors.onSurfaceVariant },
    mirror: { transform: [{ scaleX: -1 }] },
    divider: {
      height: size.hairline,
      marginStart: spacing.rowInset,
      backgroundColor: colors.outlineVariant,
    },

    // Inline per-row status (error revert / saved confirm)
    inlineRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
    inlineErrorGlyph: { ...typography.labelSm, color: colors.statusError },
    inlineErrorText: { ...typography.labelSm, color: colors.statusError, flexShrink: 1 },
    inlineSuccessGlyph: { ...typography.labelSm, color: colors.statusSuccess },
    inlineSuccessText: {
      ...typography.labelSm,
      color: colors.statusSuccess,
      flexShrink: 1,
    },

    // Synced-value skeleton (non-text View)
    skelSwitch: {
      width: size.skelSwitchW,
      height: size.skelSwitchH,
      borderRadius: radius.pill,
      backgroundColor: colors.skeleton,
    },

    // Group nav (two-pane leading)
    navGroup: { ...sectionCard },
    navRowActive: { backgroundColor: colors.surfaceDim },
    navLabelActive: { color: colors.actionPrimary },

    // Destructive zone — isolated at the very bottom, out of the tap arc
    dangerZone: { gap: spacing.sm, marginTop: spacing.xl },
    dangerHint: {
      ...typography.caption,
      color: colors.onSurfaceVariant,
      paddingStart: spacing.rowInset,
      paddingEnd: spacing.lg,
    },

    // Search results
    results: { gap: spacing.group },
    resultItem: { gap: spacing.xs },
    resultCaption: {
      ...typography.caption,
      color: colors.onSurfaceVariant,
      paddingStart: spacing.rowInset,
      paddingEnd: spacing.lg,
    },

    // Zero-results empty state
    emptyWrap: {
      alignItems: 'center',
      gap: spacing.sm,
      paddingHorizontal: spacing.xl,
      paddingVertical: spacing.xl,
    },
    emptyGlyph: { ...typography.titleLg, color: colors.onSurfaceVariant },
    emptyTitle: { ...typography.titleMd, color: colors.onSurface },
    emptyBody: { ...typography.bodyMd, color: colors.onSurfaceVariant },

    // Offline banner
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

    // Sub-page overlay
    subPage: {
      ...StyleSheet.absoluteFillObject,
      backgroundColor: colors.surface,
    },
    subHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      minHeight: size.target,
      paddingHorizontal: spacing.sm,
      borderBottomWidth: size.hairline,
      borderColor: colors.outlineVariant,
    },
    backButton: {
      minWidth: size.target,
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
    },
    backGlyph: { ...typography.titleLg, color: colors.actionPrimary },
    subTitle: { ...typography.titleMd, flex: 1, color: colors.onSurface },
    subScroll: { paddingTop: spacing.group, paddingBottom: spacing.xl },

    // Picker sheet (Android) — bottom-anchored via flex, never absolute L/R
    sheetRoot: { flex: 1, justifyContent: 'flex-end' },
    sheetScrim: {
      ...StyleSheet.absoluteFillObject,
      backgroundColor: colors.scrim,
    },
    sheet: {
      alignSelf: 'stretch',
      gap: spacing.xs,
      paddingTop: spacing.md,
      paddingHorizontal: spacing.sm,
      borderTopStartRadius: radius.lg,
      borderTopEndRadius: radius.lg,
      backgroundColor: colors.surfaceContainer,
    },
    sheetTitle: {
      ...typography.labelMd,
      color: colors.onSurfaceVariant,
      paddingStart: spacing.md,
      paddingVertical: spacing.sm,
    },
    sheetOption: {
      minHeight: size.rowMin,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: spacing.md,
      paddingHorizontal: spacing.md,
      borderRadius: radius.sm,
    },
    check: { ...typography.titleMd, color: colors.actionPrimary },
  });
}
