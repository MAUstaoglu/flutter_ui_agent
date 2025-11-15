import 'package:flutter/material.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';
import '../../core/theme/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final agentService = AgentServiceProvider.of(context, listen: true);
    final themeProvider = ThemeProviderWidget.of(context, listen: true);
    final isAiEnabled = agentService.isGeminiEnabled;
    final config = agentService.config;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
        leading: AiActionWidget(
          actionId: 'go_back',
          description:
              'Go back to the previous page, return home, navigate back',
          onExecuteAsync: () async {
            Navigator.pop(context);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: ListView(
        children: [
          // Theme Settings Section
          _buildSectionHeader('Theme Settings'),
          // ignore: deprecated_member_use
          AiActionWidget(
            actionId: 'set_theme_light',
            description: 'Set app theme to light mode',
            onExecute: () {
              themeProvider.setLightTheme();
              debugPrint('✨ Theme set to light mode');
            },
            child: ListTile(
              title: const Text('Light Theme'),
              subtitle: const Text('Use light color scheme'),
              // ignore: deprecated_member_use
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                // ignore: deprecated_member_use
                groupValue: themeProvider.themeMode,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setLightTheme();
                    debugPrint('✨ Theme set to light mode');
                  }
                },
              ),
              trailing: const Icon(Icons.light_mode),
              onTap: () {
                themeProvider.setLightTheme();
                debugPrint('✨ Theme set to light mode');
              },
            ),
          ),
          // ignore: deprecated_member_use
          AiActionWidget(
            actionId: 'set_theme_dark',
            description: 'Set app theme to dark mode',
            onExecute: () {
              themeProvider.setDarkTheme();
              debugPrint('✨ Theme set to dark mode');
            },
            child: ListTile(
              title: const Text('Dark Theme'),
              subtitle: const Text('Use dark color scheme'),
              // ignore: deprecated_member_use
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                // ignore: deprecated_member_use
                groupValue: themeProvider.themeMode,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setDarkTheme();
                    debugPrint('✨ Theme set to dark mode');
                  }
                },
              ),
              trailing: const Icon(Icons.dark_mode),
              onTap: () {
                themeProvider.setDarkTheme();
                debugPrint('✨ Theme set to dark mode');
              },
            ),
          ),
          // ignore: deprecated_member_use
          AiActionWidget(
            actionId: 'set_theme_system',
            description: 'Set app theme to system default, follow system theme',
            onExecute: () {
              themeProvider.setSystemTheme();
              debugPrint('✨ Theme set to system default');
            },
            child: ListTile(
              title: const Text('System Default'),
              subtitle: const Text('Follow system theme'),
              // ignore: deprecated_member_use
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                // ignore: deprecated_member_use
                groupValue: themeProvider.themeMode,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setSystemTheme();
                    debugPrint('✨ Theme set to system default');
                  }
                },
              ),
              trailing: const Icon(Icons.brightness_auto),
              onTap: () {
                themeProvider.setSystemTheme();
                debugPrint('✨ Theme set to system default');
              },
            ),
          ),
          const Divider(height: 32),

          // AI Assistant Settings Section
          _buildSectionHeader('AI Assistant'),
          ListTile(
            leading: Icon(
              isAiEnabled ? Icons.check_circle : Icons.cancel,
              color: isAiEnabled ? Colors.green : Colors.red,
            ),
            title: const Text('AI Status'),
            subtitle: Text(
              isAiEnabled
                  ? 'AI Provider Connected'
                  : 'AI Provider Not Configured',
            ),
            trailing: Chip(
              label: Text(
                isAiEnabled ? 'ENABLED' : 'DISABLED',
                style: TextStyle(
                  color: isAiEnabled ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          AiActionWidget(
            actionId: 'toggle_ai',
            description: 'Enable or disable AI assistant, toggle AI',
            onExecute: () {
              if (isAiEnabled) {
                agentService.disableAI();
              }
              debugPrint(
                  '🤖 AI ${isAiEnabled ? "disabled" : "already disabled"}');
            },
            child: SwitchListTile(
              title: const Text('Enable AI Assistant'),
              subtitle: const Text('Allow AI to control the app'),
              secondary: const Icon(Icons.smart_toy),
              value: isAiEnabled,
              onChanged: (_) {
                if (!isAiEnabled) {
                  // Cannot enable AI once disabled
                } else {
                  agentService.disableAI();
                  debugPrint('🤖 AI disabled');
                }
              },
            ),
          ),
          const Divider(height: 32),

          // Logging Settings Section
          _buildSectionHeader('Logging & Debugging'),
          AiActionWidget(
            actionId: 'set_log_level',
            description: 'Change logging level for AI agent',
            parameters: const [
              AgentActionParameter.string(
                name: 'level',
                description:
                    'Log level: none, error, warning, info, verbose, debug',
                enumValues: [
                  'none',
                  'error',
                  'warning',
                  'info',
                  'verbose',
                  'debug',
                ],
              ),
            ],
            onExecuteWithParams: (params) {
              final levelStr = params['level'] as String?;
              if (levelStr != null) {
                final level = _parseLogLevel(levelStr);
                agentService.setLogLevel(level);
                debugPrint('📊 Log level set to: ${level.name}');
              }
            },
            child: const SizedBox.shrink(), // Hidden action for AI
          ),
          ListTile(
            leading: const Icon(Icons.filter_list),
            title: const Text('Log Level'),
            subtitle: Text('Current: ${config.logLevel.name}'),
            trailing: DropdownButton<AgentLogLevel>(
              value: config.logLevel,
              items: AgentLogLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  agentService.setLogLevel(value);
                  debugPrint('📊 Log level set to: ${value.name}');
                }
              },
            ),
          ),
          AiActionWidget(
            actionId: 'toggle_emojis',
            description: 'Enable or disable emojis in logs',
            onExecute: () {
              agentService.setUseEmojis(!config.useEmojis);
              debugPrint(
                  '😀 Emojis ${!config.useEmojis ? "enabled" : "disabled"}');
            },
            child: SwitchListTile(
              title: const Text('Use Emojis in Logs'),
              subtitle: const Text('Add emojis to log messages'),
              secondary: const Icon(Icons.emoji_emotions),
              value: config.useEmojis,
              onChanged: (value) {
                agentService.setUseEmojis(value);
                debugPrint('😀 Emojis ${value ? "enabled" : "disabled"}');
              },
            ),
          ),
          AiActionWidget(
            actionId: 'toggle_debug_mode',
            description: 'Enable or disable debug mode',
            onExecute: () {
              agentService.setDebugMode(!config.debugMode);
              debugPrint(
                  '🐛 Debug mode ${!config.debugMode ? "enabled" : "disabled"}');
            },
            child: SwitchListTile(
              title: const Text('Debug Mode'),
              subtitle: const Text('Show detailed debug information'),
              secondary: const Icon(Icons.bug_report),
              value: config.debugMode,
              onChanged: (value) {
                agentService.setDebugMode(value);
                debugPrint('🐛 Debug mode ${value ? "enabled" : "disabled"}');
              },
            ),
          ),
          const Divider(height: 32),

          // Statistics Section
          _buildSectionHeader('Statistics'),
          _buildStatisticsTile(agentService),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                agentService.clearHistory();
                debugPrint('🗑️ Conversation history cleared');
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Conversation History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatisticsTile(AgentService agentService) {
    final stats = agentService.statistics;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('API Calls', stats['apiCalls']!.toString()),
                _buildStatItem('Failures', stats['failures']!.toString()),
                _buildStatItem('Success Rate', '${stats['successRate']}%'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Current Page', agentService.currentPage),
                _buildStatItem(
                    'Actions', agentService.actions.length.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  AgentLogLevel _parseLogLevel(String levelStr) {
    switch (levelStr.toLowerCase()) {
      case 'none':
        return AgentLogLevel.none;
      case 'error':
        return AgentLogLevel.error;
      case 'warning':
        return AgentLogLevel.warning;
      case 'info':
        return AgentLogLevel.info;
      case 'verbose':
        return AgentLogLevel.verbose;
      case 'debug':
        return AgentLogLevel.debug;
      default:
        return AgentLogLevel.info;
    }
  }
}
