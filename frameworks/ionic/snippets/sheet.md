# Snippet — Sheet modal (breakpoints = detents)

`ion-modal` with `breakpoints` + `initialBreakpoint` is Ionic's detented bottom sheet. It respects the bottom safe-area inset inside `ion-content`. See `components.md`, `BSH-*`, `A11Y-*`.

```tsx
import { IonModal, IonContent, IonHeader, IonToolbar, IonTitle, IonButtons, IonButton } from '@ionic/react';

<IonModal
  isOpen={open}
  breakpoints={[0, 0.25, 0.5, 1]}   // detents: closed → peek → half → full
  initialBreakpoint={0.5}
  onDidDismiss={close}
>
  <IonHeader>
    <IonToolbar>
      <IonTitle>Filters</IonTitle>
      <IonButtons slot="end">
        <IonButton onClick={close} aria-label="Close">Done</IonButton>
      </IonButtons>
    </IonToolbar>
  </IonHeader>
  <IonContent className="ion-padding">
    {/* sheet body — content sizes to breakpoint; bottom inset handled automatically */}
  </IonContent>
</IonModal>
```

```tsx
// card-style modal on larger screens (GRD-*): presentingElement gives the iOS card stack
<IonModal isOpen={open} presentingElement={pageRef.current!} onDidDismiss={close}>…</IonModal>
```
- Use `breakpoints`/`initialBreakpoint` as detents — don't hardcode a sheet height (`BSH-*`).
- `handle` (default true) shows the grab affordance; keep it for discoverability.
- A full-screen `ion-modal` is the routed-page alternative when the flow is long (`NAV-*`).
