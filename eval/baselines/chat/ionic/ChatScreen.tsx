// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors and off-grid spacing inlined in JSX (instead of CSS
// variables), physical left/right padding, an undersized send button, sub-legible
// timestamps, and only the happy path with none of the required UI states. Graded
// against examples/chat/ionic/.
import React, { useState } from 'react';
import { IonPage, IonContent, IonInput, IonButton, IonIcon } from '@ionic/react';
import { send } from 'ionicons/icons';

export default function ChatScreen() {
  const [draft, setDraft] = useState('');
  const messages = ['Hey!', 'How are you?', 'On my way'];
  return (
    <IonPage>
      <IonContent>
        <div style={{ paddingLeft: 18, paddingRight: 18, paddingTop: 12 }}>
          {messages.map((m, i) => (
            <div key={i} style={{ background: '#2563EB', color: '#FFFFFF', padding: 10, marginTop: 8 }}>
              <span>{m}</span>
              <span style={{ fontSize: 10, color: '#6B7280' }}>12:04</span>
            </div>
          ))}
        </div>
        <div style={{ display: 'flex', padding: 15, background: '#F3F4F6' }}>
          <IonInput value={draft} onIonInput={(e) => setDraft(e.detail.value ?? '')} />
          <IonButton onClick={() => {}} style={{ width: 36, height: 36 }}>
            <IonIcon icon={send} />
          </IonButton>
        </div>
      </IonContent>
    </IonPage>
  );
}
