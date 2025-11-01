import 'package:flutter/material.dart';
import 'agent_service.dart';

/// A pure Flutter InheritedWidget that provides AgentService to the widget tree
/// This replaces the Provider package dependency
class AgentServiceProvider extends InheritedNotifier<AgentService> {
  const AgentServiceProvider({
    super.key,
    required AgentService agentService,
    required super.child,
  }) : super(notifier: agentService);

  /// Access the AgentService from anywhere in the widget tree
  /// Set listen to true to rebuild when the service notifies listeners
  static AgentService of(BuildContext context, {bool listen = false}) {
    if (listen) {
      final provider =
          context.dependOnInheritedWidgetOfExactType<AgentServiceProvider>();
      assert(provider != null, 'AgentServiceProvider not found in context');
      return provider!.notifier!;
    } else {
      final provider =
          context.getInheritedWidgetOfExactType<AgentServiceProvider>();
      assert(provider != null, 'AgentServiceProvider not found in context');
      return provider!.notifier!;
    }
  }

  /// Helper to check if AgentServiceProvider exists in the tree
  static AgentService? maybeOf(BuildContext context, {bool listen = false}) {
    if (listen) {
      final provider =
          context.dependOnInheritedWidgetOfExactType<AgentServiceProvider>();
      return provider?.notifier;
    } else {
      final provider =
          context.getInheritedWidgetOfExactType<AgentServiceProvider>();
      return provider?.notifier;
    }
  }
}
