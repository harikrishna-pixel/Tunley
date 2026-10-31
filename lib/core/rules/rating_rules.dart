class RatingRequest {
  const RatingRequest({
    required this.ringtonesSaved,
    required this.successfulConversions,
    required this.timesAsked,
    required this.lastAskedAt,
    required this.now,
    required this.errorThisSession,
    required this.paywallThisSession,
    required this.afterRingtones,
    required this.afterConversions,
    required this.maxTimes,
    required this.minDaysBetween,
  });

  final int ringtonesSaved;
  final int successfulConversions;
  final int timesAsked;
  final DateTime? lastAskedAt;
  final DateTime now;
  final bool errorThisSession;
  final bool paywallThisSession;
  final int afterRingtones;
  final int afterConversions;
  final int maxTimes;
  final int minDaysBetween;
}

abstract final class RatingRules {
  static bool shouldAsk(RatingRequest request) {
    if (request.errorThisSession || request.paywallThisSession) {
      return false;
    }
    if (request.timesAsked >= request.maxTimes) {
      return false;
    }
    final due =
        request.ringtonesSaved >= request.afterRingtones ||
        request.successfulConversions >= request.afterConversions;
    if (!due) {
      return false;
    }
    final last = request.lastAskedAt;
    if (last != null &&
        request.now.isBefore(
          last.add(Duration(days: request.minDaysBetween)),
        )) {
      return false;
    }
    return true;
  }
}
