# Snippet — Virtualized list (refresh + skeleton + a11y rows)

`ListView.separated` builds only visible rows; pull-to-refresh; ≥48dp targets; semantic rows. See `LST-*`, `PERF-*`, `OFF-*`, `A11Y-*`.

```dart
import 'package:flutter/material.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key, required this.items, required this.onRefresh, required this.onOpen});

  final List<Txn> items;
  final Future<void> Function() onRefresh;
  final void Function(Txn) onOpen;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator( // pull-to-refresh — OFF-*
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final t = items[i];
          return MergeSemantics( // fuse title+subtitle+amount into one focus stop
            child: ListTile(
              minVerticalPadding: 12, // keeps row ≥48dp — A11Y-*
              leading: CircleAvatar(child: Text(t.title.characters.first)),
              title: Text(t.title),
              subtitle: Text(t.date),
              trailing: Text(
                t.amount,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: t.isCredit
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              onTap: () => onOpen(t),
            ),
          );
        },
      ),
    );
  }
}

class Txn {
  const Txn({required this.title, required this.date, required this.amount, required this.isCredit});
  final String title, date, amount;
  final bool isCredit;
}
```

Huge datasets / cohesive headers → `CustomScrollView` + slivers:
```dart
CustomScrollView(slivers: [
  const SliverAppBar.large(title: Text('Activity')),
  SliverList.separated(
    itemCount: items.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (context, i) => TxnRow(items[i]),
  ),
]);
```
