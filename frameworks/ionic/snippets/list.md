# Snippet — List (items, virtualization, swipe + tap alternative)

`ion-list`/`ion-item`; virtualize long lists (no `ion-virtual-scroll` since v6); every swipe action has a visible alternative. See `components.md`, `LST-*`, `PERF-*`, `GES-*`.

```tsx
import { IonList, IonItem, IonLabel, IonThumbnail, IonIcon,
         IonItemSliding, IonItemOptions, IonItemOption } from '@ionic/react';

// tappable row — whole item is one target
<IonList>
  {items.map(it => (
    <IonItem key={it.id} button detail onClick={() => open(it)}>
      <IonThumbnail slot="start"><img src={it.avatar} alt="" /></IonThumbnail>
      <IonLabel><h2>{it.title}</h2><p>{it.subtitle}</p></IonLabel>
    </IonItem>
  ))}
</IonList>
```

```tsx
// swipe action WITH a non-gesture alternative (GES-*): also reachable via the detail menu
<IonItemSliding>
  <IonItem button detail onClick={() => open(it)}>
    <IonLabel>{it.title}</IonLabel>
  </IonItem>
  <IonItemOptions side="end">
    <IonItemOption color="danger" onClick={() => remove(it)} aria-label={`Delete ${it.title}`}>
      <IonIcon slot="icon-only" icon={trash} />
    </IonItemOption>
  </IonItemOptions>
</IonItemSliding>
```

```tsx
// virtualize thousands of rows with a framework library (LST-*/PERF-*)
import { useVirtualizer } from '@tanstack/react-virtual';
// parentRef scroll container → render only visible IonItems; keeps the WebView at 60fps.
```
- Long lists MUST virtualize — a `.map()` over thousands of `IonItem`s stalls the WebView (`PERF-*`).
- Pull-to-refresh: add `<IonRefresher slot="fixed"><IonRefresherContent /></IonRefresher>` (`FEED-*`).
