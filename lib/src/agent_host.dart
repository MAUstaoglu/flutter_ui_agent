import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'agent_service.dart';
import 'agent_service_provider.dart';

/// The main widget that hosts the agent and provides it to the widget tree
class AgentHost extends StatefulWidget {
  /// The child widget (typically MaterialApp)
  final Widget child;

  /// Optional custom agent service instance
  final AgentService? agentService;

  /// Whether to wait for initial actions to register before showing the UI
  /// This ensures the agent is fully initialized when the user first sees the app
  final bool waitForActions;

  /// Duration to wait for actions to register (default: 500ms)
  final Duration actionRegistrationDelay;

  /// Callback for when the agent has a message to display
  /// Use this to show notifications in your app
  final void Function(String message)? onAgentMessage;

  const AgentHost({
    super.key,
    required this.child,
    this.agentService,
    this.waitForActions = true,
    this.actionRegistrationDelay = const Duration(milliseconds: 500),
    this.onAgentMessage,
  });

  @override
  State<AgentHost> createState() => _AgentHostState();
}

class _AgentHostState extends State<AgentHost> {
  late AgentService _agentService;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _agentService = widget.agentService ?? AgentService();

    // Wait for actions to register if requested
    if (widget.waitForActions) {
      // Wait until after first frame is rendered (when actions are registered)
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
          // Action registration is logged by AgentService when registerAction() is called
        }
      });
    } else {
      _isReady = true;
    }
  }

  @override
  void dispose() {
    if (widget.agentService == null) {
      _agentService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AgentServiceProvider(
      agentService: _agentService,
      child: _AgentMessageCallback(
        onMessage: widget.onAgentMessage,
        child: _AgentReadyProvider(
          isReady: _isReady,
          child: widget.child,
        ),
      ),
    );
  }
}

/// InheritedWidget to provide the message callback down the tree
class _AgentMessageCallback extends InheritedWidget {
  final void Function(String message)? onMessage;

  const _AgentMessageCallback({
    required this.onMessage,
    required super.child,
  });

  @override
  bool updateShouldNotify(_AgentMessageCallback oldWidget) {
    return onMessage != oldWidget.onMessage;
  }
}

/// Internal widget to provide the ready state
class _AgentReadyProvider extends InheritedWidget {
  final bool isReady;

  const _AgentReadyProvider({
    required this.isReady,
    required super.child,
  });

  @override
  bool updateShouldNotify(_AgentReadyProvider oldWidget) {
    return isReady != oldWidget.isReady;
  }
}
