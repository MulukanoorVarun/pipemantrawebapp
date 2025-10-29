import 'package:flutter/cupertino.dart';

import 'package:flutter/foundation.dart';

class DeepLinkMapper {
  /// Maps an incoming URI to an internal go_router *location* string.
  /// Supports:
  /// https://mentivisor.com/profile/42        -> /profile?id=42
  /// https://mentivisor.com/community_post/51 -> /community_post?id=51
  /// https://mentivisor.com/study_zone/35     -> /study_zone?id=35
  /// https://mentivisor.com/ecc/51            -> /ecc?id=51
  ///
  /// Also accepts query-style: /profile?id=42, etc.
  static String? toLocation(Uri? uri) {
    if (uri == null) {
      debugPrint('DeepLinkMapper: received null uri');
      return null;
    }

    debugPrint('DeepLinkMapper: parsing -> $uri');

    // Allow internal (no-scheme) and explicit https. Reject foreign https hosts.
    if (uri.hasScheme) {
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'https') {
        final host = uri.host.toLowerCase();
        final isOurDomain = _isAllowedHost(host);
        debugPrint('DeepLinkMapper: https host=$host ours=$isOurDomain');
        if (!isOurDomain) {
          debugPrint('DeepLinkMapper: foreign https host, ignore');
          return null;
        }
      } else {
        // If you also support a custom scheme, whitelist it here.
        // e.g. if (scheme != 'mentivisor') return null;
        debugPrint('DeepLinkMapper: non-https scheme "$scheme" allowed');
      }
    }

    final segs = uri.pathSegments
        .where((s) => s.isNotEmpty)
        .map((s) => s.toLowerCase())
        .toList();
    debugPrint('DeepLinkMapper: segs=$segs query=${uri.queryParameters}');

    if (segs.isEmpty) {
      debugPrint('DeepLinkMapper: no path segments, ignore');
      return null;
    }

    // Recognized first segment -> internal path
    const allowedFirstSegments = {
      'profile': '/profile',
      'community_post': '/community_post',
      'study_zone': '/study_zone',
      'ecc': '/ecc',
    };

    final first = segs.first;
    final internalPath = allowedFirstSegments[first];
    if (internalPath == null) {
      debugPrint('DeepLinkMapper: no match for first segment "$first", ignore');
      return null;
    }

    // Read ID from /segment/:id or ?id=:id (accept also alt names just in case)
    final idFromPath = segs.length >= 2 ? segs[1] : null;
    final idFromQuery = uri.queryParameters['id'] ??
        uri.queryParameters['postId'] ??
        uri.queryParameters['userId'] ??
        uri.queryParameters['topicId'] ??
        uri.queryParameters['eventId'];

    final id = (idFromPath?.isNotEmpty == true) ? idFromPath : idFromQuery;

    if (id == null || id.isEmpty) {
      debugPrint('DeepLinkMapper: id missing for "$first", ignore');
      return null;
    }

    // Build location safely (properly encoded)
    final loc = Uri(path: internalPath, queryParameters: {'id': id}).toString();
    debugPrint('DeepLinkMapper: mapped -> $loc');
    return loc;
  }

  static bool _isAllowedHost(String host) {
    // Add/remove hosts as needed
    const allowed = {
      'mentivisor.com',
      'www.mentivisor.com',
    };
    return allowed.contains(host);
  }
}
