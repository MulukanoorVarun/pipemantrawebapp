import 'package:url_launcher/url_launcher.dart';

import 'AppLogger.dart';

class AppLauncher {
  static Future<void> call(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    await _launch(url);
  }

  static Future<void> sms(String phoneNumber) async {
    final Uri url = Uri(scheme: 'sms', path: phoneNumber);
    await _launch(url);
  }

  static Future<void> email(String email) async {
    final Uri url = Uri(scheme: 'mailto', path: email);
    await _launch(url);
  }

  static Future<void> openWebsite(String? url) async {
    if (url == null || url.trim().isEmpty) {
      AppLogger.info("URL is null or empty");
      return;
    }
    String finalUrl = url.trim();
    if (!finalUrl.startsWith(RegExp(r'https?://'))) {
      finalUrl = 'https://$finalUrl';
    }

    final Uri? uri = Uri.tryParse(finalUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppLogger.info("Cannot launch URL: $finalUrl");

    }
  }

  static Future<void> openMap(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await _launch(url);
  }

  static Future<void> openWhatsApp(String phoneNumber, {String message = ''}) async {
    final url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
    final whatsappScheme = Uri.parse("whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");

    // Prefer using the app scheme directly
    if (await canLaunchUrl(whatsappScheme)) {
      await launchUrl(whatsappScheme, mode: LaunchMode.externalApplication);
    } else {
      // fallback to web WhatsApp if app not installed
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'WhatsApp not installed or URL unsupported';
      }
    }
  }


  static Future<void> _launch(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
