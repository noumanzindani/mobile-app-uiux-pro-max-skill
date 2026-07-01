# Snippet — Button (tokens, targets, loading, icon-only)

`ion-button` reads named-color tokens and clears 44×44 by default. Disable + spin during async so it can't double-fire. See `components.md`, `BTN-*`, `A11Y-*`, `ICN-*`.

```tsx
import { IonButton, IonSpinner, IonIcon } from '@ionic/react';
import { close } from 'ionicons/icons';

// primary — one per view (BTN-*); full width
<IonButton expand="block" onClick={submit}>Continue</IonButton>

// async — disabled + spinner, label hidden (no double-charge for PAY-*)
<IonButton expand="block" disabled={busy} onClick={pay}>
  {busy ? <IonSpinner name="crescent" aria-hidden="true" /> : 'Pay now'}
</IonButton>

// destructive — explicit, secondary weight (DLG-*)
<IonButton fill="outline" color="danger" onClick={confirmDelete}>Delete</IonButton>

// icon-only — WRAP the icon in a button so the hit area is padded ≥44×44 (A11Y-*/ICN-*)
<IonButton fill="clear" aria-label="Close" onClick={dismiss}>
  <IonIcon slot="icon-only" icon={close} />
</IonButton>
```

```css
/* per-component token overrides — never raw px/hex */
ion-button.brand {
  --border-radius: var(--app-radius-pill);
  --padding-top: var(--app-space-sm);
  --padding-bottom: var(--app-space-sm);
}
```
- `expand="block"` for the primary CTA; `fill="clear"`/`"outline"` for lower-emphasis.
- Never a bare `<IonIcon onClick>` for actions — the glyph alone is < 44px (`A11Y-*`).
