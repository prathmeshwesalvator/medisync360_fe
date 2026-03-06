import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/features/notification/presentation/bloc/notification_cubit.dart';
import 'package:medisync_app/features/notification/presentation/bloc/notification_state.dart';
import '../widgets/notification_tile.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.unread > 0) {
                return TextButton(
                  onPressed: () => context.read<NotificationCubit>().markRead(),
                  child: const Text('Mark all read',
                      style: TextStyle(fontSize: 13)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) return const LoadingWidget();

          if (state is NotificationError) {
            return EmptyStateWidget(
              icon: Icons.notifications_off_outlined,
              title: 'Could not load notifications',
              subtitle: state.message,
              buttonLabel: 'Retry',
              onButtonTap: () =>
                  context.read<NotificationCubit>().loadNotifications(),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.notifications_none_outlined,
                title: 'No notifications yet',
                subtitle: "You're all caught up!",
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<NotificationCubit>().loadNotifications(),
              child: ListView.builder(
                itemCount: state.notifications.length,
                itemBuilder: (_, i) {
                  final notif = state.notifications[i];
                  return NotificationTile(
                    notification: notif,
                    onTap: notif.isRead
                        ? null
                        : () => context
                            .read<NotificationCubit>()
                            .markRead(id: notif.id),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
