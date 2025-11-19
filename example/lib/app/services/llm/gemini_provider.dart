import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';

/// A Gemini-specific implementation of the LlmProvider interface.
/// This shows how to integrate the Gemini SDK with the flutter_ui_agent package.
class GeminiLlmProvider implements LlmProvider {
  GenerativeModel? _model;
  String? _modelName;
  String? _apiKey;

  @override
  Future<void> configure({required String apiKey, String? modelName}) async {
    _apiKey = apiKey;
    _modelName = modelName ?? 'gemini-2.5-flash';

    // We'll defer creating the model until send() is called, since tools
    // may be registered dynamically
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
          'Gemini provider not configured. Call configure() first.');
    }

    // Build Gemini function declarations from the generic tool definitions
    final functionDeclarations = tools.map((tool) {
      final funcMap = tool['function'] as Map<String, dynamic>;
      final name = funcMap['name'] as String;
      final description = funcMap['description'] as String;
      final params = funcMap['parameters'] as Map<String, dynamic>?;

      // Map the parameters to Gemini Schema
      final properties = <String, Schema>{};
      final required = <String>[];

      if (params != null) {
        final propsMap = params['properties'] as Map<String, dynamic>?;
        final requiredList = params['required'] as List?;

        if (propsMap != null) {
          propsMap.forEach((key, value) {
            final propMap = value as Map<String, dynamic>;
            final type = propMap['type'] as String?;
            final desc = propMap['description'] as String?;

            // Map string types to Gemini SchemaType
            SchemaType schemaType = SchemaType.string;
            if (type == 'integer' || type == 'number') {
              schemaType = SchemaType.integer;
            } else if (type == 'boolean') {
              schemaType = SchemaType.boolean;
            } else if (type == 'object') {
              schemaType = SchemaType.object;
            } else if (type == 'array') {
              schemaType = SchemaType.array;
            }

            properties[key] = Schema(
              schemaType,
              description: desc,
              nullable: propMap['nullable'] as bool? ?? false,
            );
          });
        }

        if (requiredList != null) {
          required.addAll(requiredList.cast<String>());
        }
      }

      return FunctionDeclaration(
        name,
        description,
        Schema(
          SchemaType.object,
          properties: properties,
          requiredProperties: required,
        ),
      );
    }).toList();

    // Create model with current tools
    _model = GenerativeModel(
      model: _modelName!,
      apiKey: _apiKey!,
      tools: [Tool(functionDeclarations: functionDeclarations)],
      systemInstruction: Content.system(systemPrompt),
    );

    // Note: Skipping conversation history for now to avoid format issues
    // Gemini SDK has strict requirements for history format
    // Start chat and send user message
    final chat = _model!.startChat();
    final response = await chat.sendMessage(Content.text(userMessage));

    // Check if there are function calls
    final functionCalls = response.functionCalls.toList();
    if (functionCalls.isEmpty) {
      // No function calls, just text response
      return LlmResponse(text: response.text);
    }

    // Map Gemini function calls to our generic format
    final mappedCalls = functionCalls.asMap().entries.map((entry) {
      final index = entry.key;
      final fc = entry.value;

      // Extract the continue_after parameter if present
      final continueAfter = fc.args['continue_after'] as bool? ?? false;

      return LlmFunctionCall(
        fc.name,
        fc.args,
        continueAfterNavigation: index == 0 && continueAfter,
      );
    }).toList();

    // Return without requesting follow-up to avoid chat history issues
    // The agent service will handle creating a user-friendly response
    return LlmResponse(
      text: null,
      functionCalls: mappedCalls,
    );
  }
}
