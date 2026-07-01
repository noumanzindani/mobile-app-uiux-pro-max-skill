/**
 * LoginScreen.tsx — accessible, paste-friendly Ionic login for the Login example.
 *
 * Idiomatic Ionic 8 + Capacitor: Ionic components + the `mode` engine for native
 * feel on both OSes, styled entirely through CSS classes / `var(--...)` tokens in
 * login.css (no raw #hex / px in this file). Models every one of the 7 states as a
 * discriminated union: idle, empty, loading, error, offline, success,
 * permissionDenied. Auth + biometrics are injectable props so the file stands alone.
 */
import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  IonContent, IonPage, IonInput, IonButton, IonSpinner, IonIcon,
  IonModal, IonHeader, IonToolbar, IonTitle, IonButtons, useIonToast,
} from '@ionic/react';
import {
  warningOutline, cloudOfflineOutline, alertCircleOutline, logoGoogle, logoApple,
} from 'ionicons/icons';
import { Network } from '@capacitor/network';
import './login.css';

type LoginStatus =
  | { kind: 'idle' }
  | { kind: 'empty' }
  | { kind: 'loading' }
  | { kind: 'error'; message: string }
  | { kind: 'offline' }
  | { kind: 'success' }
  | { kind: 'permissionDenied'; reason: string };

type Props = {
  onAuthenticated?: () => void;
  onForgotPassword?: () => void;
  onSignUp?: () => void;
  onContinueAsGuest?: () => void;
  onAppleSignIn?: () => void;
  onGoogleSignIn?: () => void;
  authenticate?: (email: string, password: string) => Promise<void>;
  enrollBiometric?: () => Promise<boolean>;
  openSettings?: () => void;
};

const GENERIC_ERROR = 'Email or password is incorrect';
const noop = () => {};
const defaultAuth = async () => {};
const defaultEnroll = async () => true;

export default function LoginScreen({
  onAuthenticated = noop,
  onForgotPassword = noop,
  onSignUp = noop,
  onContinueAsGuest = noop,
  onAppleSignIn = noop,
  onGoogleSignIn = noop,
  authenticate = defaultAuth,
  enrollBiometric = defaultEnroll,
  openSettings = noop,
}: Props) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [status, setStatus] = useState<LoginStatus>({ kind: 'idle' });
  const [online, setOnline] = useState(true);
  const errorRef = useRef<HTMLDivElement>(null);
  const [present] = useIonToast();

  // Connectivity drives the offline banner + disables Sign in (OFF-*).
  useEffect(() => {
    Network.getStatus().then((s) => setOnline(s.connected));
    let handle: { remove: () => void } | undefined;
    Network.addListener('networkStatusChange', (s) => setOnline(s.connected)).then((h) => {
      handle = h;
    });
    return () => { handle?.remove(); };
  }, []);

  // Move focus to the error + announce it via the alert role (A11Y-*).
  useEffect(() => {
    if (status.kind === 'error') errorRef.current?.focus();
  }, [status]);

  const isBusy = status.kind === 'loading';
  const hasInput = email.trim().length > 0 && password.length > 0;
  const signInDisabled = isBusy || !online || !hasInput;

  const handleSignIn = useCallback(async () => {
    if (isBusy) return;                    // block double-submit (BTN-*)
    if (!online) { setStatus({ kind: 'offline' }); return; }
    if (!hasInput) { setStatus({ kind: 'empty' }); return; }
    setStatus({ kind: 'loading' });
    try {
      await authenticate(email, password);
      setStatus({ kind: 'success' });
      present({ message: 'Signed in', duration: 2000 });
    } catch {
      setStatus({ kind: 'error', message: GENERIC_ERROR }); // generic — never leaks which field (AUTH-*)
    }
  }, [authenticate, email, password, online, hasInput, isBusy, present]);

  const handleEnableBiometric = useCallback(async () => {
    try {
      (await enrollBiometric())
        ? onAuthenticated()
        : setStatus({ kind: 'permissionDenied', reason: 'Biometric sign-in isn’t set up on this device yet.' });
    } catch {
      setStatus({ kind: 'permissionDenied', reason: 'Biometric sign-in is unavailable on this device.' });
    }
  }, [enrollBiometric, onAuthenticated]);

  return (
    <IonPage>
      <IonContent>
        <div className="login-scroll">
          {!online && (
            <div className="login-banner" role="status" aria-live="polite">
              <IonIcon icon={cloudOfflineOutline} aria-hidden="true" />
              <span className="spacer">You’re offline — check your connection.</span>
              <IonButton fill="clear" size="small" onClick={() => Network.getStatus().then((s) => setOnline(s.connected))}>
                Retry
              </IonButton>
            </div>
          )}

          <header className="login-header">
            <h1 className="login-title">Welcome back</h1>
            <p className="login-subtitle">Sign in to continue where you left off.</p>
          </header>

          <div className="login-fields">
            <div className="login-field">
              <label className="login-label" htmlFor="email">Email</label>
              <IonInput
                id="email" className="login-input" type="email" inputmode="email"
                autocomplete="email" placeholder="you@example.com" aria-label="Email"
                value={email} onIonInput={(e) => setEmail(e.detail.value ?? '')} disabled={isBusy}
              />
            </div>
            <div className="login-field">
              <label className="login-label" htmlFor="password">Password</label>
              <IonInput
                id="password" className="login-input" type="password"
                autocomplete="current-password" placeholder="Your password" aria-label="Password"
                clearOnEdit={false} value={password}
                onIonInput={(e) => setPassword(e.detail.value ?? '')} disabled={isBusy}
              />
            </div>

            {status.kind === 'empty' && (
              <p className="login-hint" role="status" aria-live="polite">
                Enter your email and password to continue.
              </p>
            )}

            <IonButton fill="clear" size="small" className="login-forgot" onClick={onForgotPassword}>
              Forgot password?
            </IonButton>
          </div>
        </div>
      </IonContent>

      {/* Sticky footer — primary action + SSO ride above the keyboard, clear the inset. */}
      <footer className="login-footer">
        {status.kind === 'error' && (
          <div className="login-error" role="alert" tabIndex={-1} ref={errorRef}>
            <IonIcon icon={alertCircleOutline} aria-hidden="true" />
            <span>{status.message}</span>
          </div>
        )}

        <IonButton
          expand="block" onClick={handleSignIn} disabled={signInDisabled}
          aria-label={isBusy ? 'Signing in' : 'Sign in'}
        >
          {isBusy ? <IonSpinner name="crescent" aria-hidden="true" /> : 'Sign in'}
        </IonButton>

        <IonButton expand="block" fill="outline" onClick={onAppleSignIn} aria-label="Sign in with Apple">
          <IonIcon slot="start" icon={logoApple} aria-hidden="true" /> Sign in with Apple
        </IonButton>
        <IonButton expand="block" fill="outline" onClick={onGoogleSignIn} aria-label="Sign in with Google">
          <IonIcon slot="start" icon={logoGoogle} aria-hidden="true" /> Sign in with Google
        </IonButton>

        <div className="login-links">
          <IonButton fill="clear" size="small" onClick={onSignUp}>New here? Create account</IonButton>
          <IonButton fill="clear" size="small" onClick={onContinueAsGuest}>Continue as guest</IonButton>
        </div>
      </footer>

      {/* Success → opt-in biometric enrollment with a password fallback. */}
      <IonModal isOpen={status.kind === 'success'} onDidDismiss={onAuthenticated}>
        <IonHeader><IonToolbar><IonTitle>You’re signed in</IonTitle>
          <IonButtons slot="end"><IonButton onClick={onAuthenticated}>Done</IonButton></IonButtons>
        </IonToolbar></IonHeader>
        <IonContent><div className="login-card">
          <p>Use Face ID or your fingerprint next time? You can always sign in with your password instead.</p>
          <IonButton expand="block" onClick={handleEnableBiometric}>Use biometrics</IonButton>
          <IonButton expand="block" fill="clear" onClick={onAuthenticated}>Not now, use my password</IonButton>
        </div></IonContent>
      </IonModal>

      {/* Permission-denied → never dead-end: explain + Settings + password. */}
      <IonModal isOpen={status.kind === 'permissionDenied'} onDidDismiss={onAuthenticated}>
        <IonHeader><IonToolbar><IonTitle>Biometrics unavailable</IonTitle>
          <IonButtons slot="end"><IonButton onClick={onAuthenticated}>Close</IonButton></IonButtons>
        </IonToolbar></IonHeader>
        <IonContent><div className="login-card">
          <div className="login-error"><IonIcon icon={warningOutline} aria-hidden="true" />
            <span>{status.kind === 'permissionDenied' ? status.reason : ''}</span></div>
          <IonButton expand="block" onClick={openSettings}>Open Settings</IonButton>
          <IonButton expand="block" fill="clear" onClick={onAuthenticated}>Continue with password</IonButton>
        </div></IonContent>
      </IonModal>
    </IonPage>
  );
}
