import 'nudge_exception.dart';

Future<void> checkMissionDeliveryFixedForToday({
  required DateTime localDate,
  required bool hasExistingDelivery,
}) async {
  if (localDate.year <= 0) {
    throw const NudgeException(NudgeErrorCode.invalidArgument);
  }

  if (!hasExistingDelivery) {
    return;
  }
}
