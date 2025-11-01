import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AgentService', () {
    test('should register and unregister actions', () {
      final service = AgentService();

      final action = AgentAction(
        actionId: 'test_action',
        description: 'A test action',
        onExecute: () {},
      );

      // Register action
      service.registerAction(action);
      expect(service.actions.length, 1);
      expect(service.actions.first.actionId, 'test_action');

      // Unregister action
      service.unregisterAction('test_action');
      expect(service.actions.length, 0);

      service.dispose();
    });

    test('should process query and execute matching action', () async {
      final service = AgentService();
      var executedAction = '';

      service.registerAction(AgentAction(
        actionId: 'increment',
        description: 'Increment the counter',
        onExecute: () {
          executedAction = 'increment';
        },
      ));

      final result = await service.processQuery('increment');

      expect(executedAction, 'increment');
      expect(result, contains('Increment the counter'));

      service.dispose();
    });

    test('should convert actions to tool definitions', () {
      final service = AgentService();

      service.registerAction(AgentAction(
        actionId: 'test_tool',
        description: 'Test tool description',
        onExecute: () {},
      ));

      final tools = service.getToolDefinitions();

      expect(tools.length, 1);
      expect(tools.first['type'], 'function');
      expect(tools.first['function']['name'], 'test_tool');
      expect(tools.first['function']['description'], 'Test tool description');

      service.dispose();
    });
  });
}
