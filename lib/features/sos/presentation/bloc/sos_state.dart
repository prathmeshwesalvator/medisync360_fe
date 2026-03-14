part of 'sos_cubit.dart';

abstract class SosState { const SosState(); }

class SosInitial extends SosState { const SosInitial(); }
class SosLoading extends SosState { const SosLoading(); }

class SosTriggered extends SosState {
  final SosAlertModel sos;
  const SosTriggered(this.sos);
}

class SosDetailLoaded extends SosState {
  final SosAlertModel sos;
  const SosDetailLoaded(this.sos);
}

class SosCancelled extends SosState {
  final SosAlertModel sos;
  const SosCancelled(this.sos);
}

class SosHistoryLoaded extends SosState {
  final List<SosAlertModel> history;
  const SosHistoryLoaded(this.history);
}

class SosActiveAlertsLoaded extends SosState {
  final List<SosAlertModel> alerts;
  const SosActiveAlertsLoaded(this.alerts);
}

class SosActionSuccess extends SosState {
  final String message;
  final SosAlertModel sos;
  const SosActionSuccess({required this.message, required this.sos});
}

class SosError extends SosState {
  final String message;
  const SosError(this.message);
}