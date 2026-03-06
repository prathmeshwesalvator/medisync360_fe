import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/notification/data/model/notification_model.dart';
import 'package:medisync_app/features/notification/data/repository/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repo;

  NotificationCubit(this._repo) : super(NotificationInitial());

  Future<void> loadNotifications() async {
    emit(NotificationLoading());
    try {
      final result = await _repo.getNotifications();
      emit(NotificationLoaded(
        result['notifications'] as List<NotificationModel>,
        result['unread'] as int,
      ));
    } catch (e) {
      emit(NotificationError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> markRead({int? id}) async {
    try {
      await _repo.markRead(id: id);
      await loadNotifications();
    } catch (_) {}
  }
}