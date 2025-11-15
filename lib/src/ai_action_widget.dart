import 'package:flutter/material.dart';
import 'agent_service.dart';
import 'agent_service_provider.dart';

/// A wrapper widget that registers a UI element as an actionable item for the agent
class AiActionWidget extends StatefulWidget {
  /// Unique identifier for this action
  final String actionId;

  /// Human-readable description sent to the LLM
  final String description;

  /// The callback to execute when the agent triggers this action (simple)
  final VoidCallback? onExecute;

  /// The callback to execute when the agent triggers this action (simple async)
  final Future<void> Function()? onExecuteAsync;

  /// The callback to execute with parameters (advanced)
  /// Use this for actions that need dynamic values
  final Function(Map<String, dynamic>)? onExecuteWithParams;

  /// The callback to execute with parameters (advanced async)
  /// Use this for async actions that need dynamic values
  final Future<void> Function(Map<String, dynamic>)? onExecuteWithParamsAsync;

  /// Optional: Define parameters that this action accepts
  /// Use [AgentActionParameter] helpers to document enums, ranges, etc.
  final List<AgentActionParameter> parameters;

  /// Whether the agent can ask to run this action multiple times via the
  /// optional `count` argument (defaults to false).
  final bool allowRepeats;

  /// The child widget to wrap
  final Widget child;

  /// Whether to register the action immediately in didChangeDependencies
  /// If false, registration is deferred to after the first frame
  /// Set to true for actions that need to be available before the first render
  final bool immediateRegistration;

  const AiActionWidget({
    super.key,
    required this.actionId,
    required this.description,
    this.onExecute,
    this.onExecuteAsync,
    this.onExecuteWithParams,
    this.onExecuteWithParamsAsync,
    this.parameters = const [],
    required this.child,
    this.immediateRegistration = false,
    this.allowRepeats = false,
  }) : assert(
          onExecute != null ||
              onExecuteAsync != null ||
              onExecuteWithParams != null ||
              onExecuteWithParamsAsync != null,
          'At least one execute callback must be provided',
        );

  @override
  State<AiActionWidget> createState() => _AiActionWidgetState();
}

class _AiActionWidgetState extends State<AiActionWidget> {
  AgentService? _agentService;
  bool _isRegistered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the agent service
    final newAgentService = AgentServiceProvider.of(context, listen: false);

    // If agent service changed, re-register
    if (_agentService != newAgentService) {
      _agentService = newAgentService;
      _isRegistered = false;
    }

    if (widget.immediateRegistration) {
      // Register immediately (synchronously)
      _registerAction();
    } else {
      // Defer registration to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isRegistered) {
          _registerAction();
        }
      });
    }
  }

  void _registerAction() {
    if (_isRegistered) return;

    final action = AgentAction(
      actionId: widget.actionId,
      description: widget.description,
      onExecute: widget.onExecute,
      onExecuteAsync: widget.onExecuteAsync,
      onExecuteWithParams: widget.onExecuteWithParams,
      onExecuteWithParamsAsync: widget.onExecuteWithParamsAsync,
      parameters: widget.parameters,
      allowRepeats: widget.allowRepeats,
    );
    _agentService?.registerAction(action);
    _isRegistered = true;
  }

  @override
  void didUpdateWidget(AiActionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Always re-register to ensure the action is current
    // This handles cases where callbacks change
    _isRegistered = false;
    _registerAction();
  }

  @override
  void dispose() {
    // Don't unregister actions with immediate registration
    // They should persist across rebuilds
    if (_isRegistered && !widget.immediateRegistration) {
      _agentService?.unregisterAction(widget.actionId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simply return the child - this is a transparent wrapper
    return widget.child;
  }
}
