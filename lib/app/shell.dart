import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/design_system.dart';
import '../features/errors/error_screen.dart';
import '../l10n/app_localizations.dart';
import 'adaptive.dart';
import 'batch.dart';
import 'launch_offers.dart';
import 'state.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static bool _launchChecked = false;

  @override
  void initState() {
    super.initState();
    if (_launchChecked) return;
    _launchChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) runLaunchOffers(context, ref);
    });
  }

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  Widget build(BuildContext context) {
    ref.listen(jobProvider, (previous, next) {
      if (next == null || !next.backgrounded) return;
      if (previous?.status != JobStatus.running) return;
      final l10n = AppLocalizations.of(context);
      switch (next.status) {
        case JobStatus.running:
          return;
        case JobStatus.succeeded:
          final item = next.item;
          TunelyToast.show(
            context,
            message: l10n.jobReady(next.draft.outputFormat.label),

            actionLabel: item == null ? null : l10n.open,
            onAction: item == null
                ? null
                : () => GoRouter.of(context).push('/item', extra: item),
          );
        case JobStatus.failed:
          final error = next.error;
          if (error == null || error.name == 'cancelled') return;
          TunelyToast.show(
            context,
            message: l10n.jobFailedToast,
            tone: ToastTone.error,
            actionLabel: l10n.details,
            onAction: () =>
                GoRouter.of(context).push('/error', extra: ErrorArgs(error)),
          );
      }
    });

    ref.listen(batchProvider, (previous, next) {
      if (next == null || !next.backgrounded || next.stopped) return;
      if (!(previous?.running ?? false) || !next.finished) return;
      final l10n = AppLocalizations.of(context);
      TunelyToast.show(
        context,
        message: l10n.batchFinishedToast(next.done),
        tone: next.failed > 0 ? ToastTone.warning : ToastTone.success,
        actionLabel: l10n.batchView,
        onAction: () => GoRouter.of(context).push('/batch/done'),
      );
    });

    void go(int index) => navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );

    if (!AdaptiveLayout.isWide(MediaQuery.sizeOf(context))) {
      return Scaffold(
        backgroundColor: context.colors.bg,
        body: SafeArea(bottom: false, child: navigationShell),
        bottomNavigationBar: AppTabBar(
          index: navigationShell.currentIndex,
          onTap: go,
        ),
      );
    }

    final edge = AdaptiveLayout.navEdge(
      MediaQuery.paddingOf(context),
      Directionality.of(context),
    );
    final onRight = edge == NavEdge.right;
    final rail = AppTabBar(
      index: navigationShell.currentIndex,
      onTap: go,
      vertical: true,
      railOnRight: onRight,
    );
    final content = Expanded(
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: !onRight,
        removeRight: onRight,
        child: SafeArea(child: navigationShell),
      ),
    );
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: onRight ? [content, rail] : [rail, content],
      ),
    );
  }
}

class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({super.key, required this.title, this.footer});

  final String title;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.screen),
      children: [
        Text(title, style: context.appText.largeTitle),
        if (footer != null) ...[const SizedBox(height: AppSpace.s16), footer!],
      ],
    );
  }
}
