import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';
import '../services/backend_api.dart';

class NotificationActionButton extends StatelessWidget {
  const NotificationActionButton({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: BackendApi.instance.getUnreadNotificationCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final colors = context.colors;
        final bg = backgroundColor ?? colors.surfaceElevated;
        final iconCol = iconColor ?? colors.iconPrimary;
        return Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_outlined, color: iconCol, size: 22),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: bg, width: 1.5),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.2,
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
