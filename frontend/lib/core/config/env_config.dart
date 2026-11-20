import 'package:flutter/services.dart';

class EnvConfig {
  static final Map<String, String> _env = {};
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final content = await rootBundle.loadString('.env');
      parse(content);
    } catch (_) {
      // Fallback defaults if asset is not loaded (e.g., in unit tests)
      _env['ADMIN_USERNAME'] = 'admin';
      _env['ADMIN_PASSWORD'] = 'admin';
      _env['BASE_URL'] = 'http://127.0.0.1:8000';
    } finally {
      _isInitialized = true;
    }
  }

  static void parse(String content) {
    _env.clear();
    final lines = content.split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separatorIndex = line.indexOf('=');
      if (separatorIndex > 0) {
        final key = line.substring(0, separatorIndex).trim();
        var value = line.substring(separatorIndex + 1).trim();
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
        }
        _env[key] = value;
      }
    }
  }

  static String get adminUsername => _env['ADMIN_USERNAME'] ?? 'admin';
  static String get adminPassword => _env['ADMIN_PASSWORD'] ?? 'admin';

  static String get apiBaseUrl {
    var url = _env['BASE_URL'] ?? _env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String? get(String key) => _env[key];

  // Helper for tests to mock env values
  static void setMockValues(Map<String, String> values) {
    _env.clear();
    _env.addAll(values);
    _isInitialized = true;
  }
}

