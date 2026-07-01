// BASELINE — intentionally-naive "no-skill" reference for the eval harness (do NOT
// copy). What an assistant typically emits WITHOUT the Mobile UI/UX Pro Max skill:
// hardcoded hex colors and off-grid spacing inlined in JSX (instead of CSS
// variables), physical left/right padding, an undersized icon button, a sub-legible
// price, and only the happy path with none of the required UI states. Graded against
// examples/checkout/ionic/.
import React, { useState } from 'react';
import { IonPage, IonContent, IonButton, IonIcon } from '@ionic/react';
import { close, add, remove } from 'ionicons/icons';

export default function CheckoutScreen() {
  const [qty, setQty] = useState(1);
  const price = 12900;
  return (
    <IonPage>
      <IonContent>
        <div style={{ paddingLeft: 18, paddingRight: 18, paddingTop: 60 }}>
          <h1 style={{ color: '#111827', fontSize: 22 }}>Checkout</h1>

          <div style={{ display: 'flex', justifyContent: 'space-between', padding: 15 }}>
            <span style={{ color: '#111827' }}>Wireless Headphones</span>
            <span style={{ fontSize: 10, color: '#111827' }}>${(price / 100).toFixed(2)}</span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', padding: 15 }}>
            <IonButton onClick={() => setQty(qty - 1)} style={{ width: 36, height: 36 }}>
              <IonIcon icon={remove} />
            </IonButton>
            <span style={{ paddingLeft: 10, paddingRight: 10 }}>{qty}</span>
            <IonButton onClick={() => setQty(qty + 1)} style={{ width: 36, height: 36 }}>
              <IonIcon icon={add} />
            </IonButton>
          </div>

          <p style={{ fontSize: 10, color: '#9CA3AF' }}>Tax and shipping calculated at charge</p>
          <a style={{ fontSize: 10, color: '#3B82F6' }}>Have a promo code?</a>

          <IonButton onClick={() => {}} style={{ background: '#16A34A', color: '#FFFFFF', padding: 15 }}>
            Pay now
          </IonButton>

          <IonButton onClick={() => {}} style={{ width: 36, height: 36 }}>
            <IonIcon icon={close} />
          </IonButton>
        </div>
      </IonContent>
    </IonPage>
  );
}
