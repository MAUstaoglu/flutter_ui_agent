import 'dart:async';
import 'package:flutter/widgets.dart';
import 'llm.dart';

/// Logging levels for the agent service
enum AgentLogLevel {
  /// No logging output
  none,

  /// Only errors and critical issues
  error,

  /// Warnings and errors
  warning,

  /// Basic info: actions executed, page changes
  info,

  /// Verbose: includes function calls, parameters, timing
  verbose,

  /// Debug: all internal operations and data
  debug,
}

/// Configuration for the agent service
class AgentConfig {
  final bool enableRetry;
  final int maxRetries;
  final bool enableHistory;
  final int maxHistoryLength;
  final bool enableAnalytics;
  final Function(String actionId, Duration executionTime)? onActionExecuted;
  final bool fallbackToMock;
  final bool debugMode;

  /// Logging configuration
  final AgentLogLevel logLevel;
  final bool useEmojis;
  final String logPrefix;

  /// Static system prompt override. If provided, the builder is ignored.
  final String? systemPrompt;

  /// Builder that can dynamically generate the system prompt at runtime.
  final SystemPromptBuilder? systemPromptBuilder;

  /// Retry backoff strategy: exponential (1s, 2s, 4s...) or linear (1s, 2s, 3s...)
  final RetryBackoffStrategy retryBackoffStrategy;

  /// Base delay for retry attempts (in milliseconds)
  final int retryBaseDelayMs;

  /// Delay between repeated action executions (in milliseconds)
  /// Set to 0 to use frame-based pacing instead
  final int actionRepeatDelayMs;

  /// Simulated delay for mock mode (in milliseconds)
  final int mockDelayMs;

  const AgentConfig({
    this.enableRetry = true,
    this.maxRetries = 3,
    this.enableHistory = true,
    this.maxHistoryLength = 10,
    this.enableAnalytics = false,
    this.onActionExecuted,
    this.fallbackToMock = false,
    this.debugMode = false,
    this.logLevel = AgentLogLevel.info,
    this.useEmojis = true,
    this.logPrefix = '[FlutterUIAgent]',
    this.systemPrompt,
    this.systemPromptBuilder,
    this.retryBackoffStrategy = RetryBackoffStrategy.exponential,
    this.retryBaseDelayMs = 1000,
    this.actionRepeatDelayMs = 0, // Use frame-based by default
    this.mockDelayMs = 1000,
  });
}

/// Strategy for calculating retry delays
enum RetryBackoffStrategy {
  /// Exponential backoff: delay doubles each time (1s, 2s, 4s, 8s...)
  exponential,

  /// Linear backoff: delay increases by base amount (1s, 2s, 3s, 4s...)
  linear,

  /// Fixed backoff: same delay each time
  fixed,
}

/// Represents a message in conversation history
class ConversationMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ConversationMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

/// Supported parameter types for agent actions
enum AgentParameterType {
  string,
  number,
  integer,
  boolean,
}

extension _AgentParameterTypeX on AgentParameterType {
  String get jsonType => switch (this) {
        AgentParameterType.string => 'string',
        AgentParameterType.number => 'number',
        AgentParameterType.integer => 'integer',
        AgentParameterType.boolean => 'boolean',
      };

  String get displayName => switch (this) {
        AgentParameterType.string => 'text',
        AgentParameterType.number => 'number',
        AgentParameterType.integer => 'whole number',
        AgentParameterType.boolean => 'true/false',
      };
}

/// Metadata describing a parameter that an agent action accepts
class AgentActionParameter {
  final String name;
  final AgentParameterType type;
  final String description;
  final bool isRequired;
  final bool nullable;
  final List<String> enumValues;
  final num? min;
  final num? max;
  final Object? defaultValue;

  const AgentActionParameter({
    required this.name,
    required this.type,
    this.description = '',
    this.isRequired = true,
    this.nullable = false,
    this.enumValues = const [],
    this.min,
    this.max,
    this.defaultValue,
  });

  const AgentActionParameter.string({
    required String name,
    String description = '',
    bool isRequired = true,
    bool nullable = false,
    List<String> enumValues = const [],
    Object? defaultValue,
  }) : this(
          name: name,
          type: AgentParameterType.string,
          description: description,
          isRequired: isRequired,
          nullable: nullable,
          enumValues: enumValues,
          defaultValue: defaultValue,
        );

  const AgentActionParameter.number({
    required String name,
    String description = '',
    bool isRequired = true,
    bool nullable = false,
    num? min,
    num? max,
    Object? defaultValue,
  }) : this(
          name: name,
          type: AgentParameterType.number,
          description: description,
          isRequired: isRequired,
          nullable: nullable,
          min: min,
          max: max,
          defaultValue: defaultValue,
        );

  const AgentActionParameter.integer({
    required String name,
    String description = '',
    bool isRequired = true,
    bool nullable = false,
    int? min,
    int? max,
    Object? defaultValue,
  }) : this(
          name: name,
          type: AgentParameterType.integer,
          description: description,
          isRequired: isRequired,
          nullable: nullable,
          min: min,
          max: max,
          defaultValue: defaultValue,
        );

  const AgentActionParameter.boolean({
    required String name,
    String description = '',
    bool isRequired = true,
    bool nullable = false,
    Object? defaultValue,
  }) : this(
          name: name,
          type: AgentParameterType.boolean,
          description: description,
          isRequired: isRequired,
          nullable: nullable,
          defaultValue: defaultValue,
        );

  Map<String, dynamic> toJsonSchema() {
    final schema = <String, dynamic>{
      'type': type.jsonType,
      'description':
          description.isNotEmpty ? description : 'The $name parameter',
    };
    if (nullable) schema['nullable'] = true;
    if (enumValues.isNotEmpty) schema['enum'] = enumValues;
    if (min != null) schema['minimum'] = min;
    if (max != null) schema['maximum'] = max;
    if (defaultValue != null) schema['default'] = defaultValue;
    return schema;
  }

  String promptHint() {
    final buffer = StringBuffer(name);
    buffer.write(' (${type.displayName}');
    if (enumValues.isNotEmpty) {
      buffer.write(': ${enumValues.join(", ")}');
    }
    if (min != null || max != null) {
      buffer.write(' range');
      if (min != null) buffer.write(' ≥ $min');
      if (max != null) buffer.write(' ≤ $max');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

/// Represents an action that the agent can execute
class AgentAction {
  final String actionId;
  final String description;
  final VoidCallback? onExecute;
  final Function(Map<String, dynamic>)? onExecuteWithParams;
  final Future<void> Function()? onExecuteAsync;
  final Future<void> Function(Map<String, dynamic>)? onExecuteWithParamsAsync;
  final List<AgentActionParameter> parameters;
  final bool allowRepeats;
  final bool isNavigation;

  AgentAction({
    required this.actionId,
    required this.description,
    this.onExecute,
    this.onExecuteWithParams,
    this.onExecuteAsync,
    this.onExecuteWithParamsAsync,
    List<AgentActionParameter>? parameters,
    this.allowRepeats = false,
    this.isNavigation = false,
  })  : assert(
          onExecute != null ||
              onExecuteWithParams != null ||
              onExecuteAsync != null ||
              onExecuteWithParamsAsync != null,
          'At least one execute callback must be provided',
        ),
        parameters = List.unmodifiable(parameters ?? const []);

  /// Returns a provider-agnostic function declaration map.
  Map<String, dynamic> toFunctionDeclaration() {
    final props = <String, dynamic>{};

    if (allowRepeats) {
      props['count'] = {
        'type': 'integer',
        'description': 'Number of times to execute (default 1)',
        'minimum': 1,
      };
    }

    if (isNavigation) {
      props['continue_after'] = {
        'type': 'boolean',
        'description':
            'Set to true if the user\'s request implies additional actions after this navigation completes.',
      };
    }

    final requiredParams = <String>[];
    for (final param in parameters) {
      props[param.name] = param.toJsonSchema();
      if (param.isRequired && !param.nullable) {
        requiredParams.add(param.name);
      }
    }

    return {
      'name': actionId,
      'description': description,
      'parameters': {
        'type': 'object',
        'properties': props,
        'required': requiredParams,
      },
    };
  }

  Map<String, dynamic> toToolDefinition() {
    return {
      'type': 'function',
      'function': toFunctionDeclaration(),
    };
  }
}

/// Signature for building a custom system prompt.
typedef SystemPromptBuilder = String Function(SystemPromptContext context);

/// Context that is passed to the system prompt builder.
class SystemPromptContext {
  final String currentPage;
  final List<AgentAction> actions;
  final AgentConfig config;
  final bool hasLlmProvider;

  const SystemPromptContext({
    required this.currentPage,
    required this.actions,
    required this.config,
    required this.hasLlmProvider,
  });
}

/// The central service that manages all agent actions and LLM communication
class AgentService extends ChangeNotifier {
  final Map<String, AgentAction> _actions = {};
  bool _isProcessing = false;
  bool _isCancelled = false;
  LlmProvider? _llmProvider;
  AgentConfig _config = const AgentConfig();
  final List<ConversationMessage> _conversationHistory = [];
  int _apiCallCount = 0;
  int _failureCount = 0;
  String _currentPage = 'home';
  int _actionCount = 0;

  final _actionRegistrationController = StreamController<void>.broadcast();
  bool _shouldContinueAfterNavigation = false;

  List<AgentAction> get actions => _actions.values.toList();
  bool get isProcessing => _isProcessing;
  bool get isGeminiEnabled => _llmProvider != null;
  String get currentPage => _currentPage;

  /// Cancel the current request
  void cancelCurrentRequest() {
    if (_isProcessing) {
      _isCancelled = true;
      _isProcessing = false;
      _logWarning('Request cancelled by user');
      notifyListeners();
    }
  }

  // Logging helper methods
  void _log(String message, AgentLogLevel level, {String? emoji}) {
    if (_config.logLevel == AgentLogLevel.none) return;

    // Check if this log level should be printed
    final shouldLog = _config.logLevel.index >= level.index;
    if (!shouldLog) return;

    final emojiPrefix = _config.useEmojis && emoji != null ? '$emoji ' : '';
    final prefix = _config.logPrefix.isNotEmpty ? '${_config.logPrefix} ' : '';
    debugPrint('$prefix$emojiPrefix$message');
  }

  void _logError(String message) =>
      _log(message, AgentLogLevel.error, emoji: '❌');
  void _logWarning(String message) =>
      _log(message, AgentLogLevel.warning, emoji: '⚠️');
  void _logInfo(String message) =>
      _log(message, AgentLogLevel.info, emoji: 'ℹ️');
  void _logVerbose(String message) =>
      _log(message, AgentLogLevel.verbose, emoji: '🔍');
  void _logDebug(String message) =>
      _log(message, AgentLogLevel.debug, emoji: '🐛');
  void _logSuccess(String message) =>
      _log(message, AgentLogLevel.info, emoji: '✅');
  void _logAction(String message) =>
      _log(message, AgentLogLevel.info, emoji: '🎯');
  void _logNavigation(String message) =>
      _log(message, AgentLogLevel.info, emoji: '📍');

  void setCurrentPage(String page) {
    _currentPage = page;
    _logNavigation('Current page: $_currentPage');
    notifyListeners();
  }

  List<ConversationMessage> get conversationHistory =>
      _config.enableHistory ? List.unmodifiable(_conversationHistory) : [];

  Map<String, int> get statistics => {
        'apiCalls': _apiCallCount,
        'failures': _failureCount,
        'successRate': _apiCallCount > 0
            ? ((_apiCallCount - _failureCount) * 100 / _apiCallCount).round()
            : 100,
      };

  void setLlmProvider(LlmProvider provider, {AgentConfig? config}) {
    _llmProvider = provider;
    _config = config ?? _config;
    _logSuccess('LLM provider configured');
    notifyListeners();
  }

  // Add methods to update config at runtime
  AgentConfig get config => _config;

  void updateConfig(AgentConfig newConfig) {
    _config = newConfig;
    _logInfo('Configuration updated');
    notifyListeners();
  }

  /// Calculate retry delay based on configured strategy
  Duration _calculateRetryDelay(int attemptNumber) {
    final baseMs = _config.retryBaseDelayMs;
    final delayMs = switch (_config.retryBackoffStrategy) {
      RetryBackoffStrategy.exponential => baseMs * (1 << (attemptNumber - 1)),
      RetryBackoffStrategy.linear => baseMs * attemptNumber,
      RetryBackoffStrategy.fixed => baseMs,
    };
    return Duration(milliseconds: delayMs);
  }

  /// Wait for next frame to ensure UI responsiveness
  Future<void> _waitForNextFrame() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future.timeout(
      const Duration(milliseconds: 100),
      onTimeout: () {}, // Fallback if no frame occurs
    );
  }

  void setLogLevel(AgentLogLevel level) {
    _config = AgentConfig(
      enableRetry: _config.enableRetry,
      maxRetries: _config.maxRetries,
      enableHistory: _config.enableHistory,
      maxHistoryLength: _config.maxHistoryLength,
      enableAnalytics: _config.enableAnalytics,
      onActionExecuted: _config.onActionExecuted,
      fallbackToMock: _config.fallbackToMock,
      debugMode: _config.debugMode,
      logLevel: level,
      useEmojis: _config.useEmojis,
      logPrefix: _config.logPrefix,
    );
    _logInfo('Log level set to: ${level.name}');
    notifyListeners();
  }

  void setUseEmojis(bool useEmojis) {
    _config = AgentConfig(
      enableRetry: _config.enableRetry,
      maxRetries: _config.maxRetries,
      enableHistory: _config.enableHistory,
      maxHistoryLength: _config.maxHistoryLength,
      enableAnalytics: _config.enableAnalytics,
      onActionExecuted: _config.onActionExecuted,
      fallbackToMock: _config.fallbackToMock,
      debugMode: _config.debugMode,
      logLevel: _config.logLevel,
      useEmojis: useEmojis,
      logPrefix: _config.logPrefix,
    );
    _logInfo('Emojis ${useEmojis ? "enabled" : "disabled"}');
    notifyListeners();
  }

  void setDebugMode(bool debugMode) {
    _config = AgentConfig(
      enableRetry: _config.enableRetry,
      maxRetries: _config.maxRetries,
      enableHistory: _config.enableHistory,
      maxHistoryLength: _config.maxHistoryLength,
      enableAnalytics: _config.enableAnalytics,
      onActionExecuted: _config.onActionExecuted,
      fallbackToMock: _config.fallbackToMock,
      debugMode: debugMode,
      logLevel: _config.logLevel,
      useEmojis: _config.useEmojis,
      logPrefix: _config.logPrefix,
    );
    _logInfo('Debug mode ${debugMode ? "enabled" : "disabled"}');
    notifyListeners();
  }

  void disableAI() {
    _llmProvider = null;
    _logWarning('AI provider disabled');
    notifyListeners();
  }

  String _getSystemPrompt() {
    if (_config.systemPrompt != null) {
      return _config.systemPrompt!;
    }

    final context = SystemPromptContext(
      currentPage: _currentPage,
      actions: actions,
      config: _config,
      hasLlmProvider: _llmProvider != null,
    );

    final builder = _config.systemPromptBuilder;
    if (builder != null) {
      return builder(context);
    }

    return _buildDefaultSystemPrompt(context);
  }

  String _buildDefaultSystemPrompt(SystemPromptContext context) {
    final buffer = StringBuffer();
    buffer.writeln(
        'You are an intelligent UI agent embedded in a Flutter application. Work by calling the registered functions (tools) to satisfy the user.');
    buffer.writeln();
    buffer.writeln('GUIDELINES:');
    buffer.writeln(
        '1. Only call functions from the provided tool list - never invent new actions.');
    buffer.writeln(
        '2. Extract parameter values from the user request when a function requires arguments.');
    buffer.writeln(
        '3. For multi-step requests on the SAME page (e.g., "do X 3 times then Y once"), call ALL required functions in sequence.');
    buffer.writeln(
        '4. CRITICAL: Only call functions that exist in the "Available actions" list below.');
    buffer.writeln(
        '   If an action is not listed, do NOT call it - it will be available after navigation.');
    buffer.writeln(
        '5. For navigation requests: Call ONLY the FIRST navigation action, then stop.');
    buffer.writeln(
        '   After navigation, you will receive the same request with new available actions.');
    buffer.writeln(
        '6. IMPORTANT: Navigation actions have a "continue_after" parameter:');
    buffer.writeln(
        '   - Set continue_after=true if the user wants actions after navigation');
    buffer.writeln(
        '   - Set continue_after=false (or omit) for navigation-only requests');
    buffer.writeln(
        '   - Example: nav_settings(continue_after=true) for "go to settings and enable wifi"');
    buffer.writeln(
        '7. When re-processing after navigation: Call all remaining actions for the original request.');
    buffer.writeln(
        '8. Prefer calling functions over plain text. If no function matches, explain briefly.');
    buffer.writeln();
    buffer.writeln('CURRENT CONTEXT:');
    buffer.writeln('Current page: ${context.currentPage}');
    buffer.writeln('LLM provider configured: ${context.hasLlmProvider}');
    buffer.writeln();
    if (context.actions.isNotEmpty) {
      buffer.writeln('Available actions:');
      for (final action in context.actions) {
        buffer.writeln('- ${action.actionId}: ${action.description}');
        if (action.parameters.isNotEmpty) {
          for (final param in action.parameters) {
            final hint = param.promptHint();
            buffer.writeln('  • $hint');
          }
        }
      }
      buffer.writeln();
    }
    buffer.writeln(
        'When you call a function, respond using the provided tool/function call schema.');
    buffer.writeln(
        'If no function applies, respond with a brief textual message.');
    return buffer.toString();
  }

  void registerAction(AgentAction action) {
    final wasPresent = _actions.containsKey(action.actionId);
    _actions[action.actionId] = action;
    if (!wasPresent) {
      _actionCount++;
      _logDebug(
          'Registered action: ${action.actionId} - ${action.description}');
      // Notify listeners that a new action was registered
      _actionRegistrationController.add(null);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  void unregisterAction(String actionId) {
    if (_actions.remove(actionId) != null) {
      _logDebug('Unregistered action: $actionId');
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  Future<String> processQuery(String query) async {
    if (_isProcessing) {
      return 'Agent is already processing a request. Please wait...';
    }
    _isProcessing = true;
    _isCancelled = false; // Reset cancellation flag
    notifyListeners();
    try {
      return await _processQueryInternal(query);
    } finally {
      _isProcessing = false;
      _isCancelled = false; // Reset after processing
      notifyListeners();
    }
  }

  Future<String> _processQueryInternal(String query) async {
    // Check if cancelled
    if (_isCancelled) {
      return 'Request was cancelled';
    }

    if (_config.enableHistory) {
      _addToHistory('user', query);
    }
    try {
      String response;
      if (_llmProvider != null && _actions.isNotEmpty) {
        response = await _processWithRetry(query);
      } else {
        response = await _processWithMock(query);
      }

      // Check if cancelled before adding to history
      if (_isCancelled) {
        return 'Request was cancelled';
      }

      if (_config.enableHistory) {
        _addToHistory('assistant', response);
      }
      return response;
    } catch (e) {
      _failureCount++;
      _logError('Failed to process query - $e');
      if (_config.fallbackToMock && _llmProvider != null) {
        _logWarning('Falling back to mock mode after error');
        return await _processWithMock(query);
      }
      return 'Sorry, I encountered an error: ${e.toString()}. Please try again.';
    }
  }

  Future<String> processQueryWithNavigation(String query) async {
    if (_isProcessing) {
      return 'Agent is already processing a request. Please wait...';
    }
    _isProcessing = true;
    _isCancelled = false; // Reset cancellation flag
    _shouldContinueAfterNavigation = false; // Reset continuation flag
    notifyListeners();
    try {
      // Check if cancelled
      if (_isCancelled) {
        return 'Request was cancelled';
      }

      final pageBeforeFirst = _currentPage;
      _logVerbose('Starting query on page: $pageBeforeFirst');
      final firstResult = await _processQueryInternal(query);

      // Check if cancelled after first processing
      if (_isCancelled) {
        return 'Request was cancelled';
      }

      final pageAfterFirst = _currentPage;
      _logVerbose('After first processing, page: $pageAfterFirst');
      if (pageAfterFirst != pageBeforeFirst) {
        _logSuccess(
            'Navigation detected from $pageBeforeFirst to $pageAfterFirst!');

        // Check if the LLM signaled to continue
        if (!_shouldContinueAfterNavigation) {
          _logInfo(
              'Navigation completed. LLM did not request continuation. Stopping.');
          return firstResult;
        }

        _logInfo('LLM requested continuation after navigation.');
        _logInfo('Waiting for new page actions to register...');
        notifyListeners();

        // Wait for new actions to be registered or timeout after 2 seconds
        final initialActionCount = _actionCount;
        try {
          await _actionRegistrationController.stream
              .firstWhere((_) => _actionCount > initialActionCount)
              .timeout(
            const Duration(milliseconds: 2000),
            onTimeout: () {
              _logWarning('Timeout waiting for actions to register');
              return null;
            },
          );
          _logDebug('New actions registered (count: $_actionCount)');
        } catch (e) {
          _logWarning('Error waiting for actions: $e');
        }

        // Check the current page after actions registered
        final pageBeforeWait = _currentPage;
        _logDebug('Page after actions registered: $pageBeforeWait');

        // Check if page changed during registration (e.g., multi-hop navigation)
        final pageAfterWait = _currentPage;
        if (pageAfterWait != pageBeforeWait) {
          _logInfo(
              '📍 Additional navigation detected: $pageBeforeWait → $pageAfterWait');
          _logInfo('Skipping second LLM request - already on target page');
          return firstResult;
        }

        // Check if cancelled during wait
        if (_isCancelled) {
          return 'Request was cancelled';
        }

        _logDebug(
            'Actions available after wait: ${_actions.keys.length} total');
        _logDebug('Action IDs: ${_actions.keys.join(", ")}');
        _logVerbose('Re-processing query with new actions available: "$query"');
        _logInfo('⏳ Sending second LLM request after navigation...');
        notifyListeners();
        final secondResult = await _processQueryInternal(query);
        _logInfo('✅ Second LLM request completed');

        // Check if cancelled after second processing
        if (_isCancelled) {
          return 'Request was cancelled';
        }

        _logDebug('Second result: $secondResult');
        if (!secondResult.toLowerCase().contains('what would you like') &&
            !secondResult.toLowerCase().contains('what do you want') &&
            !secondResult.toLowerCase().contains('i can help you')) {
          return '$firstResult\n\nThen: $secondResult';
        }
      }
      return firstResult;
    } finally {
      _isProcessing = false;
      _isCancelled = false; // Reset after processing
      notifyListeners();
    }
  }

  void _addToHistory(String role, String content) {
    _conversationHistory.add(ConversationMessage(
        role: role, content: content, timestamp: DateTime.now()));
    if (_conversationHistory.length > _config.maxHistoryLength) {
      _conversationHistory.removeAt(0);
    }
  }

  void clearHistory() {
    _conversationHistory.clear();
    _logInfo('Conversation history cleared');
  }

  Future<String> _processWithRetry(String query) async {
    int attempts = 0;
    Exception? lastError;
    while (attempts < _config.maxRetries) {
      // Check if cancelled before each retry attempt
      if (_isCancelled) {
        _logInfo('Retry loop cancelled by user');
        return 'Request was cancelled';
      }

      try {
        _apiCallCount++;
        _logVerbose(
            'Sending API call (attempt ${attempts + 1}/${_config.maxRetries})...');
        final response = await _processWithLlmProvider(query);
        _logVerbose('API call succeeded on attempt ${attempts + 1}');
        return response;
      } catch (e) {
        attempts++;
        lastError = e is Exception ? e : Exception(e.toString());
        _logWarning(
            'API call failed (attempt $attempts/${_config.maxRetries}) - $e');
        if (attempts < _config.maxRetries) {
          final retryDelay = _calculateRetryDelay(attempts);
          _logInfo(
              'Retrying in ${retryDelay.inMilliseconds}ms using ${_config.retryBackoffStrategy.name} backoff...');
          await Future.delayed(retryDelay);
        }
      }
    }
    _logError('All retry attempts failed after ${_config.maxRetries} tries');
    throw lastError ?? Exception('Failed after ${_config.maxRetries} attempts');
  }

  Future<String> _processWithLlmProvider(String query) async {
    if (_llmProvider == null) return 'LLM provider is not configured';
    try {
      final availableActions = _actions.values
          .map((a) => '- ${a.actionId}: ${a.description}')
          .join('\n');

      String contextText = '';
      if (_config.enableHistory && _conversationHistory.length > 1) {
        final recentHistory = _conversationHistory
            .skip(_conversationHistory.length > 5
                ? _conversationHistory.length - 5
                : 0)
            .where((m) => m.role == 'user')
            .map((m) => '- "${m.content}"')
            .join('\n');
        if (recentHistory.isNotEmpty) {
          contextText =
              '\n\nRecent conversation context:\n$recentHistory\n\nUse this context to better understand the current request.\n';
        }
      }

      final userMessage =
          '''User request: "$query"\n$contextText\nCurrent Page: $_currentPage\nAvailable actions:\n$availableActions\n''';

      // Log the user query
      debugPrint('💬 User: "$query"');

      final llmResponse = await _llmProvider!.send(
        systemPrompt: _getSystemPrompt(),
        userMessage: userMessage,
        tools: getToolDefinitions(),
        history: _conversationHistory,
      );

      // Log the AI response
      if (llmResponse.functionCalls.isNotEmpty) {
        final functionNames =
            llmResponse.functionCalls.map((fc) => fc.name).join(', ');
        debugPrint('🎯 AI Actions: $functionNames');
      } else if (llmResponse.text != null) {
        debugPrint('🤖 AI: ${llmResponse.text}');
      }

      if (llmResponse.functionCalls.isEmpty) {
        return llmResponse.text ??
            'I couldn\'t determine which action to take.';
      }

      final results = <String>[];
      for (final functionCall in llmResponse.functionCalls) {
        final actionId = functionCall.name;
        final args = functionCall.args;
        final params = Map<String, dynamic>.from(args)
          ..remove('count')
          ..remove('continue_after');

        // Check if this function call signals continuation
        if (functionCall.continueAfterNavigation) {
          _shouldContinueAfterNavigation = true;
          _logDebug(
              'Function $actionId signaled continuation after navigation.');
        }

        final action = _actions[actionId];
        if (action != null) {
          final countParam = (args['count'] as num?)?.toInt();
          final count = action.allowRepeats && countParam != null
              ? countParam.clamp(1, 50)
              : 1;
          _logAction(
              'LLM called function: $actionId (count: $count) with params: $params');
          final validationError = _validateParameters(action, params);
          if (validationError != null) {
            _logWarning(
                'Parameter validation failed for $actionId - $validationError');
            results.add('Invalid parameters for $actionId: $validationError');
            continue;
          }
          final startTime = DateTime.now();
          try {
            for (int i = 0; i < count; i++) {
              // Check async callbacks first
              if (action.onExecuteWithParamsAsync != null) {
                await action.onExecuteWithParamsAsync!(params);
              } else if (action.onExecuteAsync != null) {
                await action.onExecuteAsync!();
              } else if (action.onExecuteWithParams != null) {
                action.onExecuteWithParams!(params);
              } else if (action.onExecute != null) {
                action.onExecute!();
              }
              // Pace repeated actions to keep UI responsive
              if (count > 1 && i < count - 1) {
                if (_config.actionRepeatDelayMs > 0) {
                  await Future.delayed(
                      Duration(milliseconds: _config.actionRepeatDelayMs));
                } else {
                  // Use frame-based pacing for smoother UI updates
                  await _waitForNextFrame();
                }
              }
            }
            if (_config.enableAnalytics && _config.onActionExecuted != null) {
              _config.onActionExecuted!(
                  actionId, DateTime.now().difference(startTime));
            }

            // Page tracking is now handled by AgentNavigatorObserver
            // No need for hard-coded page updates here

            final countText = count > 1 ? ' $count times' : '';
            final paramsText = params.isNotEmpty
                ? ' (${params.entries.map((e) => '${e.key}: ${e.value}').join(', ')})'
                : '';
            results.add('${action.description}$countText$paramsText');
            _logSuccess('AI action completed: $actionId$countText');
          } catch (e) {
            final errorMsg = e.toString();
            // Detect if action was called on wrong page (widget unmounted error)
            if (errorMsg.contains('unmounted') ||
                errorMsg.contains('defunct')) {
              _logError(
                  'AI action failed: $actionId - Action not available on current page ($_currentPage)');
              results.add(
                  'Error: $actionId is not available on the $_currentPage page. Navigation may be required first.');
            } else {
              _logError('AI action failed: $actionId - Error: $e');
              results.add('Error executing $actionId: $e');
            }
          }
        } else {
          _logWarning('Function "$actionId" not found in registered actions');
          results.add('Function "$actionId" not found');
        }
      }

      return 'Executed: ${results.join(', ')}';
    } catch (e) {
      _logError('LLM provider error - $e');
      return 'AI error: $e';
    }
  }

  String? _validateParameters(AgentAction action, Map<String, dynamic> params) {
    if (action.parameters.isEmpty) return null;
    final errors = <String>[];
    final expected = {for (final param in action.parameters) param.name: param};

    for (final param in action.parameters) {
      final value = params[param.name];
      if (value == null) {
        if (param.isRequired && !param.nullable) {
          errors.add('Missing required parameter "${param.name}"');
        }
        continue;
      }

      final typeError = _validateParameterType(param, value);
      if (typeError != null) {
        errors.add(typeError);
        continue;
      }

      if (param.enumValues.isNotEmpty) {
        if (value is! String || !param.enumValues.contains(value)) {
          errors.add(
              '"${param.name}" must be one of: ${param.enumValues.join(', ')}');
        }
      }

      if ((param.type == AgentParameterType.number ||
              param.type == AgentParameterType.integer) &&
          value is num) {
        if (param.min != null && value < param.min!) {
          errors.add('"${param.name}" must be ≥ ${param.min}');
        }
        if (param.max != null && value > param.max!) {
          errors.add('"${param.name}" must be ≤ ${param.max}');
        }
      }
    }

    final unknownParams =
        params.keys.where((key) => !expected.containsKey(key));
    if (unknownParams.isNotEmpty) {
      errors.add('Unknown parameters: ${unknownParams.join(', ')}');
    }

    if (errors.isEmpty) return null;
    return errors.join('. ');
  }

  String? _validateParameterType(AgentActionParameter param, Object value) {
    switch (param.type) {
      case AgentParameterType.string:
        if (value is String) return null;
        break;
      case AgentParameterType.number:
        if (value is num) return null;
        break;
      case AgentParameterType.integer:
        if (value is int) return null;
        if (value is num && value % 1 == 0) return null;
        break;
      case AgentParameterType.boolean:
        if (value is bool) return null;
        break;
    }
    return 'Parameter "${param.name}" must be ${param.type.displayName}';
  }

  Future<String> _processWithMock(String query) async {
    // Simulate LLM latency with configurable delay
    if (_config.mockDelayMs > 0) {
      await Future.delayed(Duration(milliseconds: _config.mockDelayMs));
    }
    final lowerQuery = query.toLowerCase();
    for (final action in _actions.values) {
      final lowerDescription = action.description.toLowerCase();
      if (lowerQuery.contains(action.actionId.toLowerCase()) ||
          lowerDescription
              .split(' ')
              .any((word) => word.length > 3 && lowerQuery.contains(word))) {
        _logInfo('AI executing action (mock): ${action.actionId}');
        if (action.onExecuteWithParams != null) {
          action.onExecuteWithParams!({});
        } else if (action.onExecute != null) {
          action.onExecute!();
        }
        _logSuccess('AI action completed (mock): ${action.actionId}');
        return 'Executed: ${action.description}';
      }
    }
    _logError('No matching action found for query: "$query"');
    _logDebug('Available actions: ${_actions.keys.join(', ')}');
    return 'I couldn\'t find a matching action for: "$query".\nAvailable actions:\n${_actions.values.map((a) => '- ${a.description}').join('\n')}';
  }

  List<Map<String, dynamic>> getToolDefinitions() =>
      _actions.values.map((a) => a.toToolDefinition()).toList();

  @override
  void dispose() {
    _actions.clear();
    _actionRegistrationController.close();
    super.dispose();
  }
}
