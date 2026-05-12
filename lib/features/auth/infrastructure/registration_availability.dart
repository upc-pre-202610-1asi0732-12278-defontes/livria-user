import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../common/utils/constants.dart';

/// Result of GET `/userclients/availability` (no user list is returned).
class RegistrationAvailability {
  const RegistrationAvailability({this.emailAvailable, this.usernameAvailable});

  final bool? emailAvailable;
  final bool? usernameAvailable;
}

/// Calls the backend availability endpoint. At least one of [email] or [username] must be non-empty after trim.
///
/// Throws on network failure or non-200 HTTP status (except caller may handle messages).
Future<RegistrationAvailability> getRegistrationAvailability({
  String? email,
  String? username,
}) async {
  final e = email?.trim();
  final u = username?.trim();
  if ((e == null || e.isEmpty) && (u == null || u.isEmpty)) {
    throw ArgumentError('Provide email and/or username');
  }

  final params = <String, String>{};
  if (e != null && e.isNotEmpty) params['email'] = e;
  if (u != null && u.isNotEmpty) params['username'] = u;

  final uri = Uri.parse('${Constants.apiBaseUrl}/userclients/availability').replace(queryParameters: params);
  final response = await http.get(uri, headers: {'Accept': 'application/json'});

  if (response.statusCode == 400) {
    throw Exception('Invalid availability request.');
  }
  if (response.statusCode != 200) {
    throw Exception('Could not verify availability (HTTP ${response.statusCode}).');
  }

  final map = jsonDecode(response.body) as Map<String, dynamic>;
  return RegistrationAvailability(
    emailAvailable: map['emailAvailable'] as bool?,
    usernameAvailable: map['usernameAvailable'] as bool?,
  );
}
