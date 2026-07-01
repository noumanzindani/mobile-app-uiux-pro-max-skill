# Snippet — Virtualized list (FlashList + refresh + empty + a11y)

`FlashList` recycles rows; pull-to-refresh; wired empty state; ≥44 targets; memoized row. See `LST-*`, `PERF-*`, `OFF-*`, `STATE-*`.

```tsx
import React, { memo, useCallback } from 'react';
import { View, Text, Pressable, RefreshControl, StyleSheet } from 'react-native';
import { FlashList } from '@shopify/flash-list';
import { useTheme } from '../theme/ThemeProvider';
import { EmptyView } from './EmptyView';

type Txn = { id: string; title: string; date: string; amount: string; isCredit: boolean };

const Row = memo(function Row({ item, onPress }: { item: Txn; onPress: (t: Txn) => void }) {
  const t = useTheme();
  return (
    <Pressable
      onPress={() => onPress(item)}
      accessibilityRole="button"
      accessibilityLabel={`${item.title}, ${item.amount}, ${item.date}`}  // one focus stop — A11Y-*
      style={styles.row} // minHeight 56 keeps target ≥44
    >
      <View style={[styles.avatar, { backgroundColor: t.colors.border }]}>
        <Text>{item.title[0]}</Text>
      </View>
      <View style={{ flex: 1, marginLeft: t.spacing.md }}>
        <Text style={{ color: t.colors.onSurface, fontSize: 16 }}>{item.title}</Text>
        <Text style={{ color: t.colors.muted, fontSize: 13 }}>{item.date}</Text>
      </View>
      <Text style={{ color: item.isCredit ? t.colors.success : t.colors.onSurface, fontWeight: '600' }}>{item.amount}</Text>
    </Pressable>
  );
});

export function TransactionList({ items, refreshing, onRefresh, onOpen, onCreate }: {
  items: Txn[]; refreshing: boolean; onRefresh: () => void; onOpen: (t: Txn) => void; onCreate: () => void;
}) {
  const t = useTheme();
  const renderItem = useCallback(({ item }: { item: Txn }) => <Row item={item} onPress={onOpen} />, [onOpen]);
  return (
    <FlashList
      data={items}
      keyExtractor={(it) => it.id}
      estimatedItemSize={64}
      renderItem={renderItem}
      ItemSeparatorComponent={() => <View style={{ height: 1, backgroundColor: t.colors.border }} />}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}  // OFF-*
      ListEmptyComponent={<EmptyView onCreate={onCreate} />}                             // STATE-*
    />
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', minHeight: 56, paddingHorizontal: 16, paddingVertical: 8 },
  avatar: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
});
```

`FlatList` drop-in: same props minus `estimatedItemSize`; add `getItemLayout` for fixed-height rows.
