// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors and off-grid spacing inlined in JSX (instead of CSS
// variables), physical left/right padding, an undersized icon button, sub-legible
// text, and a destructive action sitting inline with the rest — only the happy
// path, none of the required UI states. Graded against examples/settings/ionic/.
import React, { useState } from 'react';
import { IonPage, IonContent, IonList, IonItem, IonLabel, IonToggle, IonButton, IonIcon } from '@ionic/react';
import { trash } from 'ionicons/icons';

export default function SettingsScreen() {
  const [notifications, setNotifications] = useState(true);
  const [darkTheme, setDarkTheme] = useState(false);
  return (
    <IonPage>
      <IonContent>
        <div style={{ paddingLeft: 18, paddingRight: 18, paddingTop: 50 }}>
          <h1 style={{ color: '#111827', fontSize: 22 }}>Settings</h1>
          <IonList>
            <IonItem>
              <IonLabel>Notifications</IonLabel>
              <IonToggle slot="end" checked={notifications} onIonChange={(e) => setNotifications(e.detail.checked)} />
            </IonItem>
            <IonItem>
              <IonLabel>Dark theme</IonLabel>
              <IonToggle slot="end" checked={darkTheme} onIonChange={(e) => setDarkTheme(e.detail.checked)} />
            </IonItem>
            <IonItem button onClick={() => {}} style={{ padding: 15 }}>
              <IonLabel style={{ color: '#DC2626' }}>Delete account</IonLabel>
              <IonButton onClick={() => {}} style={{ width: 36, height: 36 }}>
                <IonIcon icon={trash} />
              </IonButton>
            </IonItem>
          </IonList>
          <p style={{ fontSize: 10, color: '#6B7280' }}>Signed in as user@example.com</p>
        </div>
      </IonContent>
    </IonPage>
  );
}
