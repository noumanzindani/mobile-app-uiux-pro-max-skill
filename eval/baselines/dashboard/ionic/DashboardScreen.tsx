// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors and off-grid spacing inlined in JSX (instead of CSS
// variables), physical left/right padding, an undersized icon button, sub-legible
// captions, a fixed 2-column grid (no size classes), and only the happy path with
// none of the required UI states. Graded against examples/dashboard/ionic/.
import React from 'react';
import { IonPage, IonContent, IonButton, IonIcon } from '@ionic/react';
import { ellipsisHorizontal } from 'ionicons/icons';

export default function DashboardScreen() {
  const tiles = ['Revenue', 'Orders', 'Visitors', 'Refunds'];
  return (
    <IonPage>
      <IonContent>
        <div style={{ paddingLeft: 18, paddingRight: 18, paddingTop: 50, background: '#F9FAFB' }}>
          <h1 style={{ color: '#111827', fontSize: 22 }}>Dashboard</h1>
          <div style={{ display: 'flex', flexWrap: 'wrap', marginTop: 14 }}>
            {tiles.map((t, i) => (
              <div key={i} style={{ width: '50%', padding: 10 }}>
                <div style={{ padding: 15, background: '#FFFFFF' }}>
                  <span style={{ color: '#111827' }}>{t}</span>
                  <p style={{ fontSize: 10, color: '#16A34A' }}>+12%</p>
                </div>
              </div>
            ))}
          </div>
          <IonButton style={{ background: '#3B82F6', color: '#FFFFFF', padding: 15 }}>
            View report
          </IonButton>
          <IonButton style={{ width: 36, height: 36 }}>
            <IonIcon icon={ellipsisHorizontal} />
          </IonButton>
        </div>
      </IonContent>
    </IonPage>
  );
}
