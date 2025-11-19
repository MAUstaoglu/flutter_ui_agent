// A small abstraction layer so the package doesn't depend on any specific
// LLM SDK. Consumers can provide a concrete implementation that uses
// Gemini, OpenAI, HuggingFace, or any other provider.

import 'agent_service.dart' show ConversationMessage;

/// Represents a function call returned by the LLM
class LlmFunctionCall {
  final String name;
  final Map<String, dynamic> args;
  final bool continueAfterNavigation;

  LlmFunctionCall(
    this.name,
    this.args, {
    this.continueAfterNavigation = false,
  });
}

/// Lightweight response object returned by an LLM provider
class LlmResponse {
  final String? text;
  final List<LlmFunctionCall> functionCalls;

  LlmResponse({this.text, List<LlmFunctionCall>? functionCalls})
      : functionCalls = functionCalls ?? [];
}

/// Simple LLM provider interface. Implement this in your app and pass an
/// instance into `AgentService.setLlmProvider(...)`.
abstract class LlmProvider {
  /// Optional configuration step for providers that need API keys
  Future<void> configure({required String apiKey, String? modelName});

  /// Sends a message to the model.
  ///
  /// - [systemPrompt] is the system-level instruction.
  /// - [userMessage] is the composed user message (with context/actions).
  /// - [tools] is a list of tool/function definitions the provider can be
  ///   instructed about. Each element is a map representation (legacy).
  /// - [history] contains recent conversation messages (may be empty).
  Future<LlmResponse> send({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, dynamic>> tools,
    required List<ConversationMessage> history,
  });
}
