import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';

class DateFormattingService {
  /// Initializes locale data for date formatting.
  /// This centralized service makes it easy to support dynamic locales in the future.
  static Future<void> initialize({String defaultLocale = 'id_ID'}) async {
    try {
      await initializeDateFormatting(defaultLocale, null);
    } catch (e) {
      debugPrint('Failed to initialize date formatting for locale $defaultLocale: $e');
    }
  }
}
