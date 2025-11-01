/// Flutter UI Agent - A revolutionary package that enables AI agents to understand
/// and interact with your app's UI using natural language commands.
///
/// This package provides three core components:
/// - [AgentService]: The brain that manages actions and processes queries
/// - [AgentHost]: The integration point that wraps your MaterialApp
/// - [AiActionWidget]: A wrapper to make widgets actionable by the agent
/// - [AgentServiceProvider]: Pure Flutter state management for AgentService
/// - [AgentNavigatorObserver]: Automatic page tracking for navigation changes
library;

export 'src/agent_service.dart';
export 'src/ai_action_widget.dart';
export 'src/agent_host.dart';
export 'src/agent_service_provider.dart';
export 'src/agent_navigator_observer.dart';
export 'src/llm.dart';
