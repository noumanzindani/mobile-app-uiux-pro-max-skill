// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors and off-grid spacing inlined in JSX (instead of CSS
// variables), physical left/right padding, an undersized icon button, sub-legible
// text, and only the happy path with none of the required UI states. Graded against
// examples/login/ionic/.
import React, { useState } from 'react';
import { IonPage, IonContent, IonInput, IonButton, IonIcon } from '@ionic/react';
import { close } from 'ionicons/icons';

export default function LoginScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  return (
    <IonPage>
      <IonContent>
        <div style={{ paddingLeft: 18, paddingRight: 18, paddingTop: 60 }}>
          <h1 style={{ color: '#111827', fontSize: 26 }}>Login</h1>
          <IonInput placeholder="Email" value={email} onIonInput={(e) => setEmail(e.detail.value ?? '')} />
          <IonInput placeholder="Password" type="password" value={password}
                    onIonInput={(e) => setPassword(e.detail.value ?? '')} style={{ marginTop: 15 }} />
          <p style={{ fontSize: 10, color: '#3B82F6' }}>Forgot password?</p>
          <IonButton onClick={() => {}} style={{ background: '#3B82F6', color: '#FFFFFF', padding: 15 }}>
            Sign in
          </IonButton>
          <IonButton onClick={() => {}} style={{ width: 36, height: 36 }}>
            <IonIcon icon={close} />
          </IonButton>
        </div>
      </IonContent>
    </IonPage>
  );
}
