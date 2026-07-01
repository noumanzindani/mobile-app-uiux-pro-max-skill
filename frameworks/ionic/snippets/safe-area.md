# Snippet — Safe area (viewport-fit + insets)

`ion-content` applies safe-area padding automatically — but only if the viewport opts in. Custom fixed elements read the inset variables. See `components.md`, `A11Y-*`, `BSH-*`.

```html
<!-- index.html — WITHOUT this, every inset is 0 -->
<meta name="viewport" content="viewport-fit=cover, width=device-width, initial-scale=1.0" />
```

```tsx
// content gets top/bottom safe-area padding for free
<IonPage>
  <IonHeader><IonToolbar><IonTitle>Home</IonTitle></IonToolbar></IonHeader>
  <IonContent className="ion-padding">{/* … */}</IonContent>
</IonPage>
```

```css
/* custom floating CTA / sticky footer — add the inset, never hardcode 34px (A11Y-*) */
.floating-cta {
  position: fixed;
  left: var(--app-space-md);
  right: var(--app-space-md);
  bottom: calc(var(--app-space-md) + var(--ion-safe-area-bottom));
}

/* raw CSS env() works too (identical values Ionic populates) */
.custom-header { padding-top: calc(var(--app-space-sm) + env(safe-area-inset-top)); }
```
- Ionic exposes `--ion-safe-area-top | -bottom | -left | -right`; these mirror `env(safe-area-inset-*)`.
- RTL: pair with logical `left/right` only via `padding-inline` / `--ion-safe-area-left|right` — physical offsets break mirroring (`L10N-*`).
