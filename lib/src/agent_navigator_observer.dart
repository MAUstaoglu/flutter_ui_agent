import 'package:flutter/material.dart';
import 'agent_service.dart';

/// A NavigatorObserver that tracks route changes and updates the AgentService
/// with the current page/route information.
class AgentNavigatorObserver extends NavigatorObserver {
  final AgentService agentService;

  AgentNavigatorObserver(this.agentService);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateCurrentPage(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _updateCurrentPage(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateCurrentPage(newRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    // Don't update current page on remove - we're just cleaning up the stack
    // The actual navigation is handled by didPush/didPop
  }

  void _updateCurrentPage(Route<dynamic> route) {
    final routeName = route.settings.name;

    if (routeName != null && routeName.isNotEmpty) {
      // Use the route name if available
      String pageName = routeName.replaceAll('/', '').toLowerCase();

      // Handle root route
      if (pageName.isEmpty && routeName == '/') {
        pageName = 'home';
      }

      if (pageName.isNotEmpty) {
        // Schedule the update after the current frame to avoid build-time errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          agentService.setCurrentPage(pageName); // This logs via _logNavigation
        });
        return;
      }
    } else {
      // Debug: Log when route name is missing
      debugPrint('⚠️ Navigator: Route has no name - ${route.runtimeType}');
    }

    // If no route name is available, page tracking won't work
    // Developers should use named routes (RouteSettings with name parameter)
  }
}
