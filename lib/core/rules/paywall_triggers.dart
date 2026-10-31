import 'personalization.dart';

enum PaywallTrigger { p1, p2, p3, p4, p5, p6, p7, p8 }

class PaywallContext {
  const PaywallContext({
    required this.trigger,
    required this.isPro,
    required this.busy,
    required this.afterError,
    required this.duringOnboardingQuestions,
    required this.unrequestedThisSession,
    required this.maxUnrequestedPerSession,
    required this.previousWasPaywall,
    required this.closingP1,
    required this.frequency,
    required this.p1AlreadyShown,
    required this.conversionsToday,
    required this.p4ShownToday,
    required this.sessionsSinceP4,
    required this.lifetimeFiles,
    required this.heavyUserFiles,
    required this.p5AlreadyShown,
    required this.exitOfferEverShown,
    required this.inTrial,
    required this.trialDay2,
    required this.p7AlreadyShown,
    required this.lapsedAt,
    required this.lastWinBackAt,
    required this.now,
    required this.winBackAfterDays,
    required this.winBackCooldownDays,
  });

  final PaywallTrigger trigger;
  final bool isPro;
  final bool busy;
  final bool afterError;
  final bool duringOnboardingQuestions;
  final int unrequestedThisSession;
  final int maxUnrequestedPerSession;
  final bool previousWasPaywall;
  final bool closingP1;
  final UsageFrequency frequency;
  final bool p1AlreadyShown;
  final int conversionsToday;
  final bool p4ShownToday;
  final int sessionsSinceP4;
  final int lifetimeFiles;
  final int heavyUserFiles;
  final bool p5AlreadyShown;
  final bool exitOfferEverShown;
  final bool inTrial;
  final bool trialDay2;
  final bool p7AlreadyShown;
  final DateTime? lapsedAt;
  final DateTime? lastWinBackAt;
  final DateTime now;
  final int winBackAfterDays;
  final int winBackCooldownDays;
}

abstract final class PaywallTriggers {
  static const _unrequested = {
    PaywallTrigger.p1,
    PaywallTrigger.p4,
    PaywallTrigger.p5,
    PaywallTrigger.p8,
  };

  static bool canShow(PaywallContext context) {
    if (context.busy ||
        context.afterError ||
        context.duringOnboardingQuestions) {
      return false;
    }
    if (context.isPro && context.trigger != PaywallTrigger.p7) {
      return false;
    }

    final exitOffer =
        context.trigger == PaywallTrigger.p6 &&
        context.closingP1 &&
        !context.exitOfferEverShown;
    if (context.previousWasPaywall && !exitOffer) {
      return false;
    }
    if (_unrequested.contains(context.trigger) &&
        context.unrequestedThisSession >= context.maxUnrequestedPerSession) {
      return false;
    }

    return switch (context.trigger) {
      PaywallTrigger.p1 => !context.p1AlreadyShown,
      PaywallTrigger.p2 || PaywallTrigger.p3 => true,
      PaywallTrigger.p4 => _canShowP4(context),
      PaywallTrigger.p5 =>
        context.lifetimeFiles >= context.heavyUserFiles &&
            !context.p5AlreadyShown,
      PaywallTrigger.p6 => exitOffer,
      PaywallTrigger.p7 =>
        context.inTrial && context.trialDay2 && !context.p7AlreadyShown,
      PaywallTrigger.p8 => _canShowP8(context),
    };
  }

  static bool _canShowP4(PaywallContext context) {
    if (context.conversionsToday < 3 || context.p4ShownToday) {
      return false;
    }
    if (context.frequency == UsageFrequency.onceInAWhile &&
        context.sessionsSinceP4 < 3) {
      return false;
    }
    return true;
  }

  static bool _canShowP8(PaywallContext context) {
    final lapsedAt = context.lapsedAt;
    if (lapsedAt == null) {
      return false;
    }
    final eligibleAt = lapsedAt.add(Duration(days: context.winBackAfterDays));
    if (context.now.isBefore(eligibleAt)) {
      return false;
    }
    final last = context.lastWinBackAt;
    if (last == null) {
      return true;
    }
    final againAt = last.add(Duration(days: context.winBackCooldownDays));
    return !context.now.isBefore(againAt);
  }
}
