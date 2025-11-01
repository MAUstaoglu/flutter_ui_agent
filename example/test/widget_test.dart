// This is a basic test for the AgentService.
//
// Tests the core functionality of action registration and execution.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AgentService registers and unregisters actions', () {
    // Create agent service for the test
    final agentService = AgentService();

    // Register a test action
    final action = AgentAction(
      actionId: 'test_increment',
      description: 'Increment test counter',
      onExecute: () {},
    );

    agentService.registerAction(action);

    // Verify action was registered
    expect(agentService.actions.length, 1);
    expect(agentService.actions.first.actionId, 'test_increment');

    // Unregister action
    agentService.unregisterAction('test_increment');

    // Verify action was removed
    expect(agentService.actions.length, 0);

    // Clean up
    agentService.dispose();
  });

  test('AgentService converts actions to tool definitions', () {
    final agentService = AgentService();

    agentService.registerAction(AgentAction(
      actionId: 'test_action',
      description: 'Test action description',
      onExecute: () {},
    ));

    final tools = agentService.getToolDefinitions();

    expect(tools.length, 1);
    expect(tools.first['type'], 'function');
    expect(tools.first['function']['name'], 'test_action');
    expect(tools.first['function']['description'], 'Test action description');

    agentService.dispose();
  });
}
