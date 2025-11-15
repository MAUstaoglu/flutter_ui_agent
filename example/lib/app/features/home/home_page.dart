import 'package:flutter/material.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter--;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  void _setCounter(int value) {
    setState(() {
      _counter = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('AI Agent Demo'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
              AiActionWidget(
                actionId: 'increment_counter',
                description: 'Increment the counter by one',
                onExecute: _incrementCounter,
                child: ElevatedButton.icon(
                  onPressed: _incrementCounter,
                  icon: const Icon(Icons.add),
                  label: const Text('Increment'),
                ),
              ),
              const SizedBox(height: 16),
              AiActionWidget(
                actionId: 'decrement_counter',
                description: 'Decrement the counter by one',
                onExecute: _decrementCounter,
                child: ElevatedButton.icon(
                  onPressed: _decrementCounter,
                  icon: const Icon(Icons.remove),
                  label: const Text('Decrement'),
                ),
              ),
              const SizedBox(height: 16),
              AiActionWidget(
                actionId: 'reset_counter',
                description: 'Reset the counter to zero',
                onExecute: _resetCounter,
                child: ElevatedButton.icon(
                  onPressed: _resetCounter,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ),
              const SizedBox(height: 16),
              // NEW: Parameterized action - set counter to specific value
              AiActionWidget(
                actionId: 'set_counter',
                description: 'Set the counter to a specific value',
                parameters: const [
                  AgentActionParameter.integer(
                    name: 'value',
                    description: 'Target counter value',
                  ),
                ],
                onExecuteWithParams: (params) {
                  final value = params['value'] as int?;
                  if (value != null) {
                    _setCounter(value);
                    debugPrint('Counter set to $value');
                  }
                },
                child: const SizedBox.shrink(), // Hidden action
              ),
              const SizedBox(height: 40),
              AiActionWidget(
                actionId: 'nav_profile',
                description: 'Navigate to user profile page',
                onExecuteAsync: () async {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/profile',
                    (route) => route.isFirst,
                  );
                  // Small delay to let navigation start
                  await Future.delayed(const Duration(milliseconds: 100));
                },
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('My Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/profile',
                      (route) => route.isFirst,
                    );
                  },
                ),
              ),
              AiActionWidget(
                actionId: 'nav_pokedex',
                description: 'Navigate to Pokedex page to browse Pokemon',
                onExecuteAsync: () async {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/pokedex',
                    (route) => route.isFirst,
                  );
                  // Small delay to let navigation start
                  await Future.delayed(const Duration(milliseconds: 100));
                },
                child: ListTile(
                  leading:
                      const Icon(Icons.catching_pokemon, color: Colors.red),
                  title: const Text('Pokedex'),
                  subtitle: const Text('Browse Pokemon'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/pokedex',
                      (route) => route.isFirst,
                    );
                  },
                ),
              ),
              AiActionWidget(
                actionId: 'nav_shopping',
                description:
                    'Open shopping page, enter the store, show products, browse shop items',
                onExecuteAsync: () async {
                  debugPrint('🛍️ Navigating to shopping page...');
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/shopping',
                    (route) => route.isFirst,
                  );
                  // Small delay to let navigation start
                  await Future.delayed(const Duration(milliseconds: 100));
                  debugPrint(
                      '🛍️ Navigation completed, continuing to next action');
                },
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.green),
                  title: const Text('Shopping'),
                  subtitle: const Text('Browse products & shop'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/shopping',
                      (route) => route.isFirst,
                    );
                  },
                ),
              ),
              AiActionWidget(
                actionId: 'nav_settings',
                description:
                    'Navigate to settings page, open settings, show settings',
                onExecuteAsync: () async {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/settings',
                    (route) => route.isFirst,
                  );
                  // Small delay to let navigation start
                  await Future.delayed(const Duration(milliseconds: 100));
                },
                child: ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/settings',
                      (route) => route.isFirst,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
