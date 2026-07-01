// GOLDEN GOOD FIXTURE — token-driven, all states, RTL-safe, scalable text.
// A repo-wide validator run must score this 100/100.
import 'package:flutter/material.dart';

enum ViewState { loading, empty, error, offline, ready }

class GoodScreen extends StatelessWidget {
  const GoodScreen({super.key, required this.state});
  final ViewState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.all(AppTokens.spacingMd),
          child: switch (state) {
            ViewState.loading => const LoadingSkeleton(),   // loading state
            ViewState.empty => const EmptyState(),          // empty state
            ViewState.error => const ErrorRetry(),          // error state + retry
            ViewState.offline => const OfflineBanner(),     // offline state
            ViewState.ready => const Content(),
          },
        ),
      ),
    );
  }
}
