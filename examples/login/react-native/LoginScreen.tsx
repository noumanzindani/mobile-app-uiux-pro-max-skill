/**
 * LoginScreen.tsx — accessible, paste-friendly login for the skill's Login example.
 *
 * Implements the full spec: email + password fields with autofill / passkey /
 * paste support (WCAG 2.2 3.3.8), a labeled show/hide toggle, Forgot / Sign up /
 * Guest links, a full-width primary Sign in button kept above the keyboard, and
 * Apple / Google SSO. Models every one of the 7 states as a discriminated union
 * and drives all visuals from loginTokens.ts (no raw values in this file).
 *
 * NOTE: authentication + biometrics are mocked via injectable props so the file
 * compiles and runs standalone; wire the real calls at the call site.
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
  Linking,
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
  typography,
} from './loginTokens';

/**
 * The 7 UI states as a discriminated union. Members literally cover:
 * idle, empty, loading, error, offline, success, permissionDenied.
 */
type LoginStatus =
  | { kind: 'idle' }
  | { kind: 'empty' }
  | { kind: 'loading' }
  | { kind: 'error'; message: string }
  | { kind: 'offline' }
  | { kind: 'success' }
  | { kind: 'permissionDenied'; reason: string };

type LoginScreenProps = {
  onAuthenticated?: () => void;
  onForgotPassword?: () => void;
  onSignUp?: () => void;
  onContinueAsGuest?: () => void;
  onAppleSignIn?: () => void;
  onGoogleSignIn?: () => void;
  /** Mocked auth; reject to exercise the error state. */
  authenticate?: (email: string, password: string) => Promise<void>;
  /** Resolve false / reject to exercise the permission-denied state. */
  enrollBiometric?: () => Promise<boolean>;
};

const GENERIC_ERROR = 'Email or password is incorrect';

const noop = () => {};

const defaultAuthenticate = async (_email: string, _password: string) => {
  // Illustrative latency only — replace with a real network call.
  await new Promise((resolve) => setTimeout(resolve, motion.emphasis));
};

const defaultEnrollBiometric = async () => true;

export default function LoginScreen({
  onAuthenticated = noop,
  onForgotPassword = noop,
  onSignUp = noop,
  onContinueAsGuest = noop,
  onAppleSignIn = noop,
  onGoogleSignIn = noop,
  authenticate = defaultAuthenticate,
  enrollBiometric = defaultEnrollBiometric,
}: LoginScreenProps) {
  const scheme = useColorScheme();
  const colors = getColors(scheme);
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => makeStyles(colors), [colors]);

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [focusedField, setFocusedField] = useState<'email' | 'password' | null>(
    null,
  );
  const [status, setStatus] = useState<LoginStatus>({ kind: 'idle' });
  const [isConnected, setIsConnected] = useState(true);
  const [reduceMotion, setReduceMotion] = useState(false);

  const passwordRef = useRef<TextInput>(null);
  const errorRef = useRef<View>(null);
  const errorOpacity = useRef(new Animated.Value(0)).current;

  // Reduce-motion preference — gates every non-essential animation.
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

  // Connectivity — drives the offline banner + disables Sign in.
  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener((state) => {
      setIsConnected(state.isConnected ?? true);
    });
    return () => unsubscribe();
  }, []);

  useEffect(() => {
    if (!isConnected) {
      setStatus({ kind: 'offline' });
    } else {
      setStatus((prev) => (prev.kind === 'offline' ? { kind: 'idle' } : prev));
    }
  }, [isConnected]);

  // Error state: move focus to the message, announce it, and fade it in
  // (instant when reduce-motion is on). Input is never cleared (FRM-009).
  useEffect(() => {
    if (status.kind !== 'error') return;
    const node = errorRef.current ? findNodeHandle(errorRef.current) : null;
    if (node != null) AccessibilityInfo.setAccessibilityFocus(node);
    AccessibilityInfo.announceForAccessibility(status.message);
    if (reduceMotion) {
      errorOpacity.setValue(1);
    } else {
      errorOpacity.setValue(0);
      Animated.timing(errorOpacity, {
        toValue: 1,
        duration: motion.base,
        useNativeDriver: true,
      }).start();
    }
  }, [status, reduceMotion, errorOpacity]);

  const isBusy = status.kind === 'loading';
  const hasInput = email.trim().length > 0 && password.length > 0;
  const signInDisabled = isBusy || !isConnected || !hasInput;

  const handleSignIn = useCallback(async () => {
    if (status.kind === 'loading') return; // block double-submit (BTN-003)
    if (!isConnected) {
      setStatus({ kind: 'offline' });
      return;
    }
    if (email.trim().length === 0 || password.length === 0) {
      setStatus({ kind: 'empty' });
      AccessibilityInfo.announceForAccessibility('Enter your email and password');
      return;
    }
    setStatus({ kind: 'loading' });
    try {
      await authenticate(email, password);
      setStatus({ kind: 'success' });
      AccessibilityInfo.announceForAccessibility('Signed in');
    } catch {
      // Generic message — never reveals which field was wrong (AUTH-004).
      setStatus({ kind: 'error', message: GENERIC_ERROR });
    }
  }, [authenticate, email, password, isConnected, status.kind]);

  const handleEnableBiometric = useCallback(async () => {
    try {
      const ok = await enrollBiometric();
      if (ok) {
        onAuthenticated();
      } else {
        setStatus({
          kind: 'permissionDenied',
          reason: 'Biometric sign-in isn’t set up on this device yet.',
        });
      }
    } catch {
      setStatus({
        kind: 'permissionDenied',
        reason: 'Biometric sign-in is unavailable on this device.',
      });
    }
  }, [enrollBiometric, onAuthenticated]);

  const retryConnection = useCallback(() => {
    NetInfo.refresh();
  }, []);

  const showOfflineBanner = !isConnected;
  const showEmptyHint = status.kind === 'empty';

  return (
    <SafeAreaView edges={['top']} style={styles.container}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView
          contentContainerStyle={styles.scroll}
          keyboardShouldPersistTaps="handled"
        >
          {showOfflineBanner ? (
            <View
              accessible
              accessibilityRole="alert"
              accessibilityLiveRegion="polite"
              style={styles.banner}
            >
              <Text
                style={styles.bannerIcon}
                accessibilityElementsHidden
                importantForAccessibility="no-hide-descendants"
              >
                {'⚠'}
              </Text>
              <Text style={styles.bannerText}>
                You&apos;re offline — check your connection.
              </Text>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel="Retry connection"
                onPress={retryConnection}
                hitSlop={size.hitSlop}
                style={styles.bannerAction}
              >
                <Text style={styles.link}>Retry</Text>
              </Pressable>
            </View>
          ) : null}

          <View style={styles.header}>
            <Text
              accessibilityRole="header"
              style={styles.title}
              maxFontSizeMultiplier={2}
            >
              Welcome back
            </Text>
            <Text style={styles.subtitle}>
              Sign in to continue where you left off.
            </Text>
          </View>

          <View style={styles.fields}>
            <View style={styles.field}>
              <Text nativeID="emailLabel" style={styles.fieldLabel}>
                Email
              </Text>
              <TextInput
                accessibilityLabel="Email"
                accessibilityLabelledBy="emailLabel"
                autoCapitalize="none"
                autoComplete="email"
                autoCorrect={false}
                blurOnSubmit={false}
                editable={!isBusy}
                importantForAutofill="yes"
                keyboardType="email-address"
                onChangeText={setEmail}
                onFocus={() => setFocusedField('email')}
                onBlur={() => setFocusedField(null)}
                onSubmitEditing={() => passwordRef.current?.focus()}
                placeholder="you@example.com"
                placeholderTextColor={colors.onSurfaceMuted}
                returnKeyType="next"
                textContentType="username"
                value={email}
                style={[
                  styles.input,
                  focusedField === 'email' ? styles.inputFocused : null,
                ]}
              />
            </View>

            <View style={styles.field}>
              <Text nativeID="passwordLabel" style={styles.fieldLabel}>
                Password
              </Text>
              <View
                style={[
                  styles.passwordRow,
                  focusedField === 'password' ? styles.inputFocused : null,
                ]}
              >
                <TextInput
                  ref={passwordRef}
                  accessibilityLabel="Password"
                  accessibilityLabelledBy="passwordLabel"
                  autoCapitalize="none"
                  autoComplete="current-password"
                  autoCorrect={false}
                  editable={!isBusy}
                  importantForAutofill="yes"
                  onChangeText={setPassword}
                  onFocus={() => setFocusedField('password')}
                  onBlur={() => setFocusedField(null)}
                  onSubmitEditing={handleSignIn}
                  placeholder="Your password"
                  placeholderTextColor={colors.onSurfaceMuted}
                  returnKeyType="go"
                  secureTextEntry={!showPassword}
                  textContentType="password"
                  value={password}
                  style={styles.passwordInput}
                />
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={
                    showPassword ? 'Hide password' : 'Show password'
                  }
                  accessibilityState={{ selected: showPassword }}
                  onPress={() => setShowPassword((prev) => !prev)}
                  hitSlop={size.hitSlop}
                  style={styles.toggle}
                >
                  <Text style={styles.toggleLabel}>
                    {showPassword ? 'Hide' : 'Show'}
                  </Text>
                </Pressable>
              </View>
            </View>

            {showEmptyHint ? (
              <Text
                accessibilityLiveRegion="polite"
                style={styles.hint}
              >
                Enter your email and password to continue.
              </Text>
            ) : null}

            <Pressable
              accessibilityRole="link"
              accessibilityLabel="Forgot password"
              onPress={onForgotPassword}
              hitSlop={size.hitSlop}
              style={styles.inlineLink}
            >
              <Text style={styles.link}>Forgot password?</Text>
            </Pressable>
          </View>
        </ScrollView>

        {/* Sticky footer — primary action + SSO ride above the keyboard and
            clear the home-indicator inset. */}
        <View
          style={[
            styles.footer,
            { paddingBottom: insets.bottom + spacing.sm },
          ]}
        >
          {status.kind === 'error' ? (
            <Animated.View
              ref={errorRef}
              accessible
              accessibilityRole="alert"
              accessibilityLiveRegion="assertive"
              accessibilityLabel={status.message}
              style={[styles.errorRow, { opacity: errorOpacity }]}
            >
              <Text
                style={styles.errorIcon}
                accessibilityElementsHidden
                importantForAccessibility="no-hide-descendants"
              >
                {'⚠'}
              </Text>
              <Text style={styles.errorText}>{status.message}</Text>
            </Animated.View>
          ) : null}

          <Pressable
            accessibilityRole="button"
            accessibilityLabel={isBusy ? 'Signing in' : 'Sign in'}
            accessibilityState={{ disabled: signInDisabled, busy: isBusy }}
            accessibilityHint={
              !isConnected ? 'Connect to the internet to sign in' : undefined
            }
            disabled={signInDisabled}
            onPress={handleSignIn}
            style={({ pressed }) => [
              styles.primaryButton,
              signInDisabled ? styles.primaryButtonDisabled : null,
              pressed && !signInDisabled ? styles.primaryButtonPressed : null,
            ]}
          >
            {isBusy ? (
              <ActivityIndicator color={colors.onActionPrimary} />
            ) : (
              <Text style={styles.primaryButtonLabel}>Sign in</Text>
            )}
          </Pressable>

          {Platform.OS === 'ios' ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Sign in with Apple"
              onPress={onAppleSignIn}
              style={({ pressed }) => [
                styles.ssoButton,
                pressed ? styles.ssoButtonPressed : null,
              ]}
            >
              <Text style={styles.ssoGlyph}>{''}</Text>
              <Text style={styles.ssoLabel}>Sign in with Apple</Text>
            </Pressable>
          ) : null}

          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Sign in with Google"
            onPress={onGoogleSignIn}
            style={({ pressed }) => [
              styles.ssoButton,
              pressed ? styles.ssoButtonPressed : null,
            ]}
          >
            <Text style={styles.ssoGlyph}>G</Text>
            <Text style={styles.ssoLabel}>Sign in with Google</Text>
          </Pressable>

          <View style={styles.footerLinks}>
            <Pressable
              accessibilityRole="link"
              accessibilityLabel="Create an account"
              onPress={onSignUp}
              hitSlop={size.hitSlop}
              style={styles.footerLink}
            >
              <Text style={styles.link}>New here? Create account</Text>
            </Pressable>
            <Pressable
              accessibilityRole="link"
              accessibilityLabel="Continue as guest"
              onPress={onContinueAsGuest}
              hitSlop={size.hitSlop}
              style={styles.footerLink}
            >
              <Text style={styles.linkMuted}>Continue as guest</Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>

      {/* Success -> opt-in biometric enrollment with a password fallback. */}
      {status.kind === 'success' ? (
        <View
          accessible
          accessibilityViewIsModal
          accessibilityLiveRegion="polite"
          style={styles.overlay}
        >
          <View style={styles.card}>
            <Text accessibilityRole="header" style={styles.cardTitle}>
              You&apos;re signed in
            </Text>
            <Text style={styles.cardBody}>
              Use Face ID or your fingerprint next time? You can always sign in
              with your password instead.
            </Text>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Enable biometric sign-in"
              onPress={handleEnableBiometric}
              style={({ pressed }) => [
                styles.primaryButton,
                pressed ? styles.primaryButtonPressed : null,
              ]}
            >
              <Text style={styles.primaryButtonLabel}>Use biometrics</Text>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Continue with password"
              onPress={onAuthenticated}
              hitSlop={size.hitSlop}
              style={styles.cardSecondary}
            >
              <Text style={styles.link}>Not now, use my password</Text>
            </Pressable>
          </View>
        </View>
      ) : null}

      {/* Permission-denied -> never dead-end: explain + Settings + password. */}
      {status.kind === 'permissionDenied' ? (
        <View
          accessible
          accessibilityViewIsModal
          accessibilityLiveRegion="assertive"
          style={styles.overlay}
        >
          <View style={styles.card}>
            <Text accessibilityRole="header" style={styles.cardTitle}>
              Biometrics unavailable
            </Text>
            <Text style={styles.cardBody}>{status.reason}</Text>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Open Settings"
              onPress={() => Linking.openSettings()}
              style={({ pressed }) => [
                styles.ssoButton,
                pressed ? styles.ssoButtonPressed : null,
              ]}
            >
              <Text style={styles.ssoLabel}>Open Settings</Text>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Continue with password"
              onPress={onAuthenticated}
              hitSlop={size.hitSlop}
              style={styles.cardSecondary}
            >
              <Text style={styles.link}>Continue with password</Text>
            </Pressable>
          </View>
        </View>
      ) : null}
    </SafeAreaView>
  );
}

function makeStyles(colors: ColorRoles) {
  const fieldSurface = {
    backgroundColor: colors.surfaceContainer,
    borderColor: colors.outline,
    borderWidth: size.hairline,
    borderRadius: radius.md,
  };
  return StyleSheet.create({
    flex: { flex: 1 },
    container: { flex: 1, backgroundColor: colors.surface },
    scroll: {
      flexGrow: 1,
      paddingHorizontal: spacing.lg,
      paddingTop: spacing.lg,
      gap: spacing.lg,
    },
    banner: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      paddingHorizontal: spacing.md,
      paddingVertical: spacing.sm,
      borderRadius: radius.md,
      backgroundColor: colors.surfaceDim,
    },
    bannerIcon: { ...typography.bodyMd, color: colors.onSurface },
    bannerText: { ...typography.labelMd, flex: 1, color: colors.onSurface },
    bannerAction: {
      minHeight: size.target,
      justifyContent: 'center',
      paddingHorizontal: spacing.sm,
    },
    header: { gap: spacing.xs },
    title: { ...typography.titleLg, color: colors.onSurface },
    subtitle: { ...typography.bodyMd, color: colors.onSurfaceMuted },
    fields: { gap: spacing.md },
    field: { gap: spacing.xs },
    fieldLabel: { ...typography.labelMd, color: colors.onSurface },
    input: {
      ...typography.bodyMd,
      ...fieldSurface,
      minHeight: size.target,
      paddingHorizontal: spacing.md,
      paddingVertical: spacing.sm,
      color: colors.onSurface,
      writingDirection: I18nManager.isRTL ? 'rtl' : 'ltr',
    },
    inputFocused: {
      borderColor: colors.actionFocus,
      borderWidth: size.focusRing,
    },
    passwordRow: {
      ...fieldSurface,
      flexDirection: 'row',
      alignItems: 'center',
      minHeight: size.target,
      paddingStart: spacing.md,
    },
    passwordInput: {
      ...typography.bodyMd,
      flex: 1,
      paddingVertical: spacing.sm,
      color: colors.onSurface,
      writingDirection: I18nManager.isRTL ? 'rtl' : 'ltr',
    },
    toggle: {
      minWidth: size.target,
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
      paddingHorizontal: spacing.sm,
    },
    toggleLabel: { ...typography.labelMd, color: colors.actionPrimary },
    hint: { ...typography.labelSm, color: colors.onSurfaceMuted },
    inlineLink: {
      minHeight: size.target,
      justifyContent: 'center',
      alignSelf: 'flex-start',
    },
    link: { ...typography.labelMd, color: colors.actionPrimary },
    linkMuted: { ...typography.labelMd, color: colors.onSurfaceMuted },
    footer: {
      paddingHorizontal: spacing.lg,
      paddingTop: spacing.md,
      gap: spacing.sm,
      borderTopWidth: size.hairline,
      borderTopColor: colors.outline,
      backgroundColor: colors.surface,
    },
    errorRow: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: spacing.sm,
      paddingVertical: spacing.xs,
    },
    errorIcon: { ...typography.bodyMd, color: colors.statusError },
    errorText: { ...typography.labelMd, flex: 1, color: colors.statusError },
    primaryButton: {
      minHeight: size.target,
      borderRadius: radius.md,
      backgroundColor: colors.actionPrimary,
      alignItems: 'center',
      justifyContent: 'center',
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.md,
    },
    primaryButtonPressed: { backgroundColor: colors.actionPrimaryPressed },
    primaryButtonDisabled: { backgroundColor: colors.outline },
    primaryButtonLabel: { ...typography.labelMd, color: colors.onActionPrimary },
    ssoButton: {
      minHeight: size.target,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      gap: spacing.sm,
      borderRadius: radius.md,
      borderWidth: size.hairline,
      borderColor: colors.outline,
      backgroundColor: colors.ssoSurface,
      paddingHorizontal: spacing.lg,
      paddingVertical: spacing.sm,
    },
    ssoButtonPressed: { backgroundColor: colors.surfaceDim },
    ssoGlyph: { ...typography.titleMd, color: colors.onSsoSurface },
    ssoLabel: { ...typography.labelMd, color: colors.onSsoSurface },
    footerLinks: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      justifyContent: 'space-between',
      gap: spacing.sm,
    },
    footerLink: {
      minHeight: size.target,
      justifyContent: 'center',
    },
    overlay: {
      ...StyleSheet.absoluteFillObject,
      alignItems: 'center',
      justifyContent: 'center',
      padding: spacing.lg,
      backgroundColor: colors.scrim,
    },
    card: {
      alignSelf: 'stretch',
      gap: spacing.md,
      padding: spacing.lg,
      borderRadius: radius.lg,
      backgroundColor: colors.surface,
    },
    cardTitle: { ...typography.titleMd, color: colors.onSurface },
    cardBody: { ...typography.bodyMd, color: colors.onSurfaceMuted },
    cardSecondary: {
      minHeight: size.target,
      alignItems: 'center',
      justifyContent: 'center',
    },
  });
}
