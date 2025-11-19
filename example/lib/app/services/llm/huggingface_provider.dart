import 'dart:convert';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';
import 'package:http/http.dart' as http;

/// A HuggingFace-specific implementation of the LlmProvider interface.
/// Uses HuggingFace Inference API with prompt-based function calling.
class HuggingFaceProvider implements LlmProvider {
  String? _apiKey;
  String? _modelName;

  @override
  Future<void> configure({required String apiKey, String? modelName}) async {
    _apiKey = apiKey;
    _modelName = modelName ?? 'mistralai/Mistral-7B-Instruct-v0.2';
    // Configured with model: $_modelName
  }

  @override
  Future<LlmResponse> send({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, dynamic>> tools,
    required List<ConversationMessage> history,
  }) async {
    if (_apiKey == null) {
      throw Exception(
          'HuggingFace provider not configured. Call configure() first.');
    }

    // Build conversation messages for the OpenAI-compatible endpoint
    final messages = <Map<String, dynamic>>[];

    // Include system prompt with available functions for extra context
    if (systemPrompt.isNotEmpty) {
      final functionsText = tools.map((tool) {
        final funcMap = tool['function'] as Map<String, dynamic>;
        final name = funcMap['name'];
        final desc = funcMap['description'];
        return '- $name: $desc';
      }).join('\n');

      final combinedPrompt = [
        systemPrompt.trim(),
        if (functionsText.isNotEmpty)
          'Available functions (for reference):\n$functionsText',
      ].join('\n\n');

      messages.add({
        'role': 'system',
        'content': combinedPrompt,
      });
    }

    // Add conversation history
    for (final message in history) {
      messages.add({
        'role': message.role == 'assistant' ? 'assistant' : 'user',
        'content': message.content,
      });
    }

    // Current user request
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    try {
      // Send request via the OpenAI-compatible endpoint (Inference Providers)
      final response = await http.post(
        Uri.parse('https://router.huggingface.co/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelName,
          'messages': messages,
          if (tools.isNotEmpty) 'tools': tools,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;

        if (choices == null || choices.isEmpty) {
          throw Exception(
              'No choices returned from HuggingFace Inference Providers');
        }

        final message = choices.first['message'] as Map<String, dynamic>?;
        if (message == null) {
          throw Exception('No message returned from HuggingFace response');
        }

        String extractContent(dynamic content) {
          if (content is String) {
            return content;
          }
          if (content is List) {
            return content
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    if (item['type'] == 'text') {
                      return item['text']?.toString() ?? '';
                    }
                    return item['text']?.toString() ?? item.values.join(' ');
                  }
                  return item.toString();
                })
                .where((part) => part.isNotEmpty)
                .join('\n');
          }
          return content?.toString() ?? '';
        }

        final text = extractContent(message['content']);
        final toolCallsRaw = message['tool_calls'] as List<dynamic>?;

        final functionCalls = <LlmFunctionCall>[];
        if (toolCallsRaw != null) {
          for (var i = 0; i < toolCallsRaw.length; i++) {
            final call = toolCallsRaw[i];
            if (call is Map<String, dynamic>) {
              final function = call['function'] as Map<String, dynamic>?;
              if (function == null) continue;

              final name = function['name'] as String?;
              if (name == null) continue;

              final rawArguments = function['arguments'];
              Map<String, dynamic> arguments = {};
              if (rawArguments is String) {
                try {
                  final decoded = jsonDecode(rawArguments);
                  if (decoded is Map<String, dynamic>) {
                    arguments = decoded;
                  }
                } catch (_) {
                  // Ignore parse errors, fall back to empty args
                }
              } else if (rawArguments is Map<String, dynamic>) {
                arguments = rawArguments;
              }

              // Extract the continue_after parameter if present
              final continueAfter =
                  arguments['continue_after'] as bool? ?? false;

              functionCalls.add(LlmFunctionCall(
                name,
                arguments,
                continueAfterNavigation: i == 0 && continueAfter,
              ));
            }
          }
        }

        return LlmResponse(
          text: text,
          functionCalls: functionCalls,
        );
      } else if (response.statusCode == 503) {
        throw Exception(
            'HuggingFace model is loading. This usually takes 20-30 seconds.\n'
            'Please wait a moment and try again.');
      } else if (response.statusCode == 404) {
        throw Exception(
            'HuggingFace model "$_modelName" not found or requires access.\n'
            'Please check the model name and your access permissions.');
      } else {
        final errorBody = response.body;
        throw Exception(
            'HuggingFace API error: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('HuggingFace request failed: $e');
    }
  }
}
