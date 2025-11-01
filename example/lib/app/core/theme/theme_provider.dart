import 'package:flutter/material.dart';

/// Provider for managing theme mode across the app
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void setLightTheme() => setThemeMode(ThemeMode.light);
  void setDarkTheme() => setThemeMode(ThemeMode.dark);
  void setSystemTheme() => setThemeMode(ThemeMode.system);
}

/// InheritedWidget to provide ThemeProvider down the tree
class ThemeProviderWidget extends InheritedNotifier<ThemeProvider> {
  const ThemeProviderWidget({
    super.key,
    required ThemeProvider themeProvider,
    required super.child,
  }) : super(notifier: themeProvider);

  static ThemeProvider of(BuildContext context, {bool listen = false}) {
    if (listen) {
      final provider =
          context.dependOnInheritedWidgetOfExactType<ThemeProviderWidget>();
      assert(provider != null, 'ThemeProviderWidget not found in context');
      return provider!.notifier!;
    } else {
      final provider =
          context.getInheritedWidgetOfExactType<ThemeProviderWidget>();
      assert(provider != null, 'ThemeProviderWidget not found in context');
      return provider!.notifier!;
    }
  }
}
