import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

// ── JS interop bindings (functions defined in web/index.html) ──────────────

@JS('mediInitGoogleSignIn')
external void _jsInitGoogleSignIn(String clientId, String scope);

@JS('mediRequestGoogleToken')
external void _jsRequestGoogleToken(JSFunction callback);

@JS('mediShowDrivePicker')
external void _jsShowDrivePicker(
    String accessToken, String apiKey, JSFunction callback);

// ── DriveService ────────────────────────────────────────────────────────────

class DrivePickResult {
  final String fileId;
  final String fileName;
  DrivePickResult({required this.fileId, required this.fileName});
}

class DriveService {
  DriveService._();
  static final DriveService instance = DriveService._();

  String? _accessToken;
  DateTime? _tokenExpiry;
  bool _initialized = false;

  bool get isSignedIn =>
      _accessToken != null &&
      _tokenExpiry != null &&
      DateTime.now().isBefore(_tokenExpiry!);

  void _ensureInitialized() {
    if (_initialized) return;
    _jsInitGoogleSignIn(
        AppConstants.googleClientId, AppConstants.googleDriveScope);
    _initialized = true;
  }

  /// Requests a fresh access token. Shows a Google sign-in popup the first
  /// time; subsequent calls within the token lifetime are silent.
  Future<void> signIn() async {
    _ensureInitialized();
    final completer = Completer<void>();
    final jsCallback = (JSAny? tokenVal, JSAny? errorVal) {
      final token = (tokenVal as JSString?)?.toDart ?? '';
      final error = (errorVal as JSString?)?.toDart ?? '';
      if (error.isNotEmpty && error != 'undefined') {
        completer.completeError('Google sign-in failed: $error');
      } else if (token.isEmpty) {
        completer.completeError('Google sign-in was cancelled.');
      } else {
        _accessToken = token;
        // GIS tokens are valid for 1 hour; use 55 min to be safe.
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
        completer.complete();
      }
    }.toJS;
    _jsRequestGoogleToken(jsCallback);
    return completer.future;
  }

  /// Ensures a valid token exists, signing in if needed.
  Future<void> _ensureToken() async {
    if (!isSignedIn) await signIn();
  }

  /// Opens Google Picker and returns the chosen file's metadata.
  /// Returns null if the user cancelled.
  Future<DrivePickResult?> pickFile() async {
    await _ensureToken();
    final completer = Completer<DrivePickResult?>();
    final jsCallback = (JSAny? idVal, JSAny? nameVal, JSAny? errorVal) {
      final id = (idVal as JSString?)?.toDart ?? '';
      final name = (nameVal as JSString?)?.toDart ?? '';
      final error = (errorVal as JSString?)?.toDart ?? '';
      if (error == 'cancelled' || id.isEmpty) {
        completer.complete(null);
      } else {
        completer.complete(DrivePickResult(fileId: id, fileName: name));
      }
    }.toJS;
    _jsShowDrivePicker(_accessToken!, AppConstants.googleApiKey, jsCallback);
    return completer.future;
  }

  /// Downloads the file bytes from Drive.
  Future<Uint8List> downloadFile(String fileId) async {
    await _ensureToken();
    final uri = Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $_accessToken',
    });
    if (response.statusCode != 200) {
      throw Exception(
          'Drive download failed (${response.statusCode}): ${response.body}');
    }
    return response.bodyBytes;
  }

  /// Overwrites the file in Drive with new bytes. The filename is preserved.
  Future<void> saveFile(String fileId, Uint8List bytes) async {
    await _ensureToken();
    const mime =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    final uri = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media');
    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': mime,
      },
      body: bytes,
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Drive save failed (${response.statusCode}): ${response.body}');
    }
  }
}
