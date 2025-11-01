import 'package:flutter/material.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';
import 'app/config/app_config.dart';
import 'app/core/theme/theme_provider.dart';
import 'app/core/widgets/agent_chat_overlay.dart';
import 'app/features/home/home_page.dart';
import 'app/features/pokedex/pokedex_page.dart';
import 'app/features/profile/profile_page.dart';
import 'app/features/shopping/shopping_page.dart';
import 'app/features/settings/settings_page.dart';
import 'app/services/llm/gemini_provider.dart';
import 'app/services/llm/huggingface_provider.dart';

void main() {
  // Create agent service
  final agentService = AgentService();

  // Create theme provider
  final themeProvider = ThemeProvider();

  // Configure LLM provider based on config
  _configureLlmProvider(agentService);

  runApp(
    ThemeProviderWidget(
      themeProvider: themeProvider,
      child: AgentHost(
        agentService: agentService,
        waitForActions: true,
        actionRegistrationDelay: const Duration(milliseconds: 300),
        onAgentMessage: (message) {
          debugPrint('📢 $message');
        },
        child: const MyApp(),
      ),
    ),
  );
}

/// Configure LLM provider based on app configuration
void _configureLlmProvider(AgentService agentService) {
  // Default agent config for most providers
  const defaultConfig = AgentConfig(
    // Logging configuration
    logLevel: AgentLogLevel.info,
    useEmojis: true,
    logPrefix: '[FlutterUIAgent]',

    // Agent behavior
    enableRetry: true,
    maxRetries: 3,
    enableHistory: true,
    maxHistoryLength: 10,
    enableAnalytics: true,
    onActionExecuted: _onActionExecuted,
    fallbackToMock: false,
    debugMode: true,
  );

  // Gemini-specific config (history disabled to avoid format issues)
  const geminiConfig = AgentConfig(
    logLevel: AgentLogLevel.info,
    useEmojis: true,
    logPrefix: '[FlutterUIAgent]',
    enableRetry: true,
    maxRetries: 3,
    enableHistory: false, // Disabled for Gemini
    maxHistoryLength: 10,
    enableAnalytics: true,
    onActionExecuted: _onActionExecuted,
    fallbackToMock: false,
    debugMode: true,
  );

  switch (AppConfig.llmProvider) {
    case 'gemini':
      if (AppConfig.geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE') {
        final provider = GeminiLlmProvider();
        provider.configure(
          apiKey: AppConfig.geminiApiKey,
          modelName: AppConfig.geminiModel,
        );
        agentService.setLlmProvider(provider, config: geminiConfig);
        debugPrint('🤖 Gemini AI enabled');
        debugPrint('📊 Model: ${AppConfig.geminiModel}');
      } else {
        _showMockMessage();
      }
      break;

    case 'huggingface':
      if (AppConfig.huggingfaceApiKey != 'YOUR_HUGGINGFACE_API_KEY_HERE') {
        final provider = HuggingFaceProvider();
        provider.configure(
          apiKey: AppConfig.huggingfaceApiKey,
          modelName: AppConfig.huggingfaceModel,
        );
        agentService.setLlmProvider(provider, config: defaultConfig);
        debugPrint('🤖 HuggingFace enabled');
        debugPrint('📊 Model: ${AppConfig.huggingfaceModel}');
        debugPrint(
            '⏰ Note: First request may take 20-30 seconds (model loading)');
      } else {
        _showMockMessage();
      }
      break;

    default:
      _showMockMessage();
  }
}

/// Show message when using mock mode
void _showMockMessage() {
  debugPrint('� Using mock keyword matching');
  debugPrint(
      '💡 To use AI: Set llmProvider in app_config.dart and add API key');
}

// Analytics callback
void _onActionExecuted(String actionId, Duration executionTime) {
  debugPrint(
      '📊 Analytics: $actionId executed in ${executionTime.inMilliseconds}ms');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the AgentService from AgentHost (the one created in main())
    final themeProvider = ThemeProviderWidget.of(context, listen: true);

    return MaterialApp(
      title: 'Flutter UI Agent Demo',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AgentChatOverlay(child: HomeNavigator()),
    );
  }
}

class HomeNavigator extends StatelessWidget {
  const HomeNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final agentService = AgentServiceProvider.of(context);

    return Navigator(
      key: GlobalKey<NavigatorState>(),
      initialRoute: '/',
      observers: [
        AgentNavigatorObserver(agentService),
      ],
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/profile':
            page = const ProfilePage();
            break;
          case '/pokedex':
            page = const PokedexPage();
            break;
          case '/shopping':
            page = const ShoppingPage();
            break;
          case '/settings':
            page = const SettingsPage();
            break;
          case '/':
          default:
            page = const HomePage();
        }
        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }
}
