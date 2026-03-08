import 'package:autocare_pro/data/repositories/garage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provide the current theme mode
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final repository = ref.read(garageRepositoryProvider);
    final settings = await repository.getSettings();
    state = _parseThemeMode(settings.themeMode);
  }

  Future<void> setTheme(String mode) async {
    state = _parseThemeMode(mode);
    final repository = ref.read(garageRepositoryProvider);

    // Persist the change
    try {
      final currentSettings = await repository.getSettings();
      final newSettings = currentSettings.copyWith(themeMode: mode);
      await repository.updateSettings(newSettings);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
