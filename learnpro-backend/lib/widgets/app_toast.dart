import 'package:flutter/material.dart';
import 'google_fonts_shim.dart';

enum ToastType { success, error, info, badge }

void showAppToast(BuildContext context, String message, {ToastType type = ToastType.success}) {
  IconData icon;
  Color iconColor;
  switch (type) {
    case ToastType.success:
      icon = Icons.check_circle;
      iconColor = const Color(0xFF34D399);
      break;
    case ToastType.error:
      icon = Icons.cancel;
      iconColor = const Color(0xFFF87171);
      break;
    case ToastType.info:
      icon = Icons.lightbulb;
      iconColor = const Color(0xFFFBBF24);
      break;
    case ToastType.badge:
      icon = Icons.military_tech;
      iconColor = const Color(0xFFC084FC);
      break;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF0F172A),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      content: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: GoogleFonts.prompt(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}

// --------------------------------------------------
// SALARY UNLOCK OVERLAY (real functional replacement of #salary-overlay)
