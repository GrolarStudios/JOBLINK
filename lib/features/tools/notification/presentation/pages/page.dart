import 'package:flutter/material.dart';
import '../../../../../core/utils/text/app_global_variables.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _service = NotificationService();
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _service.getAllNotifications();

    _service.notificationStream.listen((notification) {
      setState(() {
        _notifications.insert(0, notification);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Globals.initialize(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,

      // ================= APP BAR PROFESIONAL =================
      appBar: AppBar(
        title: Text(
          Globals.notifications,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Limpiar",
            onPressed: () {
              _service.clearAll();
              setState(() {
                _notifications.clear();
              });
            },
          ),
        ],
      ),

      // ================= BODY =================
      body: _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: colorScheme.onBackground.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              Globals.notFoundNotifications,
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];

          return Card(
            color: colorScheme.surface,
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              title: Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                item.body,
                style: theme.textTheme.bodyMedium,
              ),
              trailing: Text(
                "${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withOpacity(0.6),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
