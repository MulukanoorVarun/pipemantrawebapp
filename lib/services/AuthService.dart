import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _accessTokenKey = "access_token";
  static const String _refreshTokenKey = "refresh_token";
  static const String _tokenExpiryKey = "token_expiry";
  static const String _role = "role";
  static const String _userId = "user_id";
  static const String _userName = "user_name";
  static const String _email = "email";
  static const String _mobile = "mobile";
  static const String _coins = "_coins";
  static const String _collegeID = "_collegeID";
  static const String _collegeName = "_collegeName";

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Check if the user is a guest (no token or empty token)
  static Future<bool> get isGuest async {
    final token = await getAccessToken();
    return token == null || token.isEmpty;
  }

  /// Get stored access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get role
  static Future<String?> getRole() async {
    return await _storage.read(key: _role);
  }

  /// Get USer_id
  static Future<String?> getUSerId() async {
    return await _storage.read(key: _userId);
  }

  static Future<String?> getCollegeID() async {
    return await _storage.read(key: _collegeID);
  }

  static Future<String?> getCollegeName() async {
    return await _storage.read(key: _collegeName);
  }

  /// get Name
  static Future<String?> getName() async {
    return await _storage.read(key: _userName);
  }

  static Future<String?> getEmail() async {
    return await _storage.read(key: _email);
  }

  static Future<String?> getMobile() async {
    return await _storage.read(key: _mobile);
  }

  static Future<void> saveCoins(int coins) async {
    await _storage.write(key: _coins, value: coins.toString());
  }

  static Future<void> saveRole(String role) async {
    await _storage.write(key: _role, value: role.toString());
  }

  static Future<void> saveCollegeID(int CollegeID) async {
    await _storage.write(key: _collegeID, value: CollegeID.toString());
  }

  static Future<void> saveCollegeName(String CollegeName) async {
    await _storage.write(key: _collegeName, value: CollegeName.toString());
  }

  static Future<String?> getCoins() async {
    return await _storage.read(key: _coins);
  }

  /// Get stored refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Check if token is expired
  static Future<bool> isTokenExpired() async {
    final expiryTimestamp = await _storage.read(key: _tokenExpiryKey);
    if (expiryTimestamp == null) {
      debugPrint('No expiry timestamp found, considering token expired');
      return true;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final isExpired = now >= (int.tryParse(expiryTimestamp) ?? 0);
    debugPrint(
      'Token expiry check: now=$now, expiry=$expiryTimestamp, isExpired=$isExpired',
    );
    return isExpired;
  }

  /// Save tokens and expiry time
  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    int expiresIn,
    String role,
    int userid,
    String userName,
    String email,
    int mobile,
  ) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _role, value: role);
    await _storage.write(key: _tokenExpiryKey, value: expiresIn.toString());
    await _storage.write(key: _userName, value: userName.toString());
    await _storage.write(key: _userId, value: userid.toString());
    await _storage.write(key: _email, value: email.toString());
    await _storage.write(key: _mobile, value: mobile.toString());
  }

  /// Refresh token
  // static Future<bool> refreshToken() async {
  //   final refreshToken = await getRefreshToken();
  //   if (refreshToken == null) {
  //     debugPrint('❌ No refresh token available');
  //     return false;
  //   }
  //   try {
  //     // Call your RemoteDataSourceImpl or API to refresh the token
  //     final response = await _remote.refreshTokenApi({"refresh": refreshToken});
  //     if (response != null && response.success == true && response.data != null) {
  //       final tokenData = response.data!;
  //       final newAccessToken = tokenData.access;
  //       final newRefreshToken = tokenData.refresh;
  //       final expiryTime = tokenData.expiryTime;
  //       final role = tokenData.role;
  //
  //       if (newAccessToken == null || newRefreshToken == null || expiryTime == null) {
  //         debugPrint("❌ Missing token data in response: ${response.toJson()}");
  //         return false;
  //       }
  //
  //       // Save the tokens with expiryTime
  //       await saveTokens(
  //         newAccessToken,
  //         newRefreshToken,
  //         expiryTime,
  //         role,
  //       );
  //       debugPrint("✅ Token refreshed and saved successfully");
  //       return true;
  //     } else {
  //       debugPrint("❌ Refresh token request failed: ${response?.message ?? 'No message'}");
  //       return false;
  //     }
  //   } catch (e) {
  //     debugPrint("❌ Token refresh failed: $e");
  //     return false;
  //   }
  // }

  /// Logout and clear tokens, redirect to sign-in screen
  static Future<void> logout() async {
    await _storage.deleteAll(); // clear all tokens
    debugPrint('Tokens cleared, user logged out');

    final context = navigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go('/onboarding');
    } else {
      debugPrint('Context is null, scheduling GoRouter navigation after frame');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final postFrameContext = navigatorKey.currentContext;
        if (postFrameContext != null) {
          GoRouter.of(postFrameContext).go('/onboarding');
        } else {
          debugPrint('Still no context available after frame');
          // Optional: consider forcing rebuild or restarting app
        }
      });
    }
  }
}
