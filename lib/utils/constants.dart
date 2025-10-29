import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/AuthService.dart';
import 'color_constants.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void showAnimatedTopSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  final animationController = AnimationController(
    vsync: Navigator.of(context),
    duration: Duration(milliseconds: 300),
  );
  final animation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeOut,
  );

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, -50 + 50 * animation.value), // slide down
                child: child,
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primarycolor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
            ),
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: "segeo",
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  animationController.forward();

  Future.delayed(Duration(seconds: 2), () {
    animationController.reverse().then((_) {
      overlayEntry.remove();
      animationController.dispose();
    });
  });
}

class InputDecorationUtils {
  static InputDecoration inputDecoration(
    String label, [
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIconWidget,
  ]) {
    return InputDecoration(
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIconWidget,
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontFamily: 'segeo',
        fontSize: 14,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'segeo',
        fontSize: 16,
        color: Colors.grey,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primarycolor, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primarycolor, width: 0.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 0.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

String capitalize(String value) {
  if (value.isEmpty) return "";
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

class DateHelper {
  static String formatDateTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return "";
    try {
      final dateTime = DateTime.parse(rawTime);
      return DateFormat('dd MMM yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      return rawTime;
    }
  }

  static String timeAgo(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return "";
    try {
      final dateTime = DateTime.parse(rawTime);
      final Duration diff = DateTime.now().difference(dateTime);

      if (diff.inSeconds < 60) {
        return "just now";
      } else if (diff.inMinutes < 60) {
        return "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24) {
        return "${diff.inHours}h ago";
      } else if (diff.inDays == 1) {
        return "yesterday";
      } else if (diff.inDays < 7) {
        return "${diff.inDays}d ago";
      } else {
        return DateFormat('dd MMM yyyy').format(dateTime);
      }
    } catch (e) {
      return rawTime;
    }
  }
}

class AppState {
  static final ValueNotifier<int> coinsNotifier = ValueNotifier<int>(0);

  static void updateCoins(int newCoins) {
    coinsNotifier.value = newCoins;
    AuthService.saveCoins(newCoins);
  }

  static Future<void> loadCoins() async {
    final storedCoins = await AuthService.getCoins();
    coinsNotifier.value = int.tryParse(storedCoins ?? "0") ?? 0;
  }
}

class AppStateMentorCostPerMinuteCoins {
  static final ValueNotifier<int> mentorCoinsNotifier = ValueNotifier<int>(0);

  static void fetchCoins(int newCoins) {
    mentorCoinsNotifier.value = newCoins;
  }
}

String formatDate(String? rawDate) {
  if (rawDate == null || rawDate.isEmpty) return "";
  try {
    final date = DateTime.parse(rawDate);
    return DateFormat('dd MMM yyyy').format(date);
  } catch (e) {
    return rawDate;
  }
}

String formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String formatTimeRange(String? rawTime) {
  if (rawTime == null || rawTime.isEmpty) return "";

  try {
    // Split by dash
    final parts = rawTime.split(RegExp(r'[-–]'));
    if (parts.length == 2) {
      final start = _parseAndFormatTime(parts[0].trim());
      final end = _parseAndFormatTime(parts[1].trim());
      return "$start – $end";
    } else {
      return _parseAndFormatTime(rawTime.trim());
    }
  } catch (e) {
    return rawTime;
  }
}

String _parseAndFormatTime(String raw) {
  try {
    // Try parsing strict HH:mm:ss
    if (RegExp(r'^\d{2}:\d{2}(:\d{2})?$').hasMatch(raw)) {
      final parsed = DateFormat("HH:mm").parse(raw, true).toLocal();
      return DateFormat("hh:mm a").format(parsed);
    }

    // Try parsing already with AM/PM
    return DateFormat("hh:mm a").format(DateFormat("h:mm a").parse(raw));
  } catch (_) {
    return raw; // fallback to raw string
  }
}
