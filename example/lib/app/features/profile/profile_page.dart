import 'package:flutter/material.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = 'Mehmet Ali';
  final String _email = 'mehmet.ali@example.com';
  String _bio = 'Flutter developer and AI enthusiast';
  bool _notificationsEnabled = true;
  final int _profileViews = 42;

  // Text field state
  final TextEditingController _statusController = TextEditingController(
    text: 'Available for work',
  );

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _statusController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _editName() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _name);
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _name = controller.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _changeBio(String newBio) {
    if (!mounted) return;
    setState(() {
      _bio = newBio;
    });
    debugPrint('✏️ Bio updated: $newBio');
  }

  void _changeStatus(String newStatus) {
    if (!mounted) return;
    setState(() {
      _statusController.text = newStatus;
    });
    debugPrint('📝 Status updated: $newStatus');
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    debugPrint('📜 Scrolled to top');
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    debugPrint('📜 Scrolled to bottom');
  }

  void _scrollToSection(String section) {
    double targetOffset = 0;
    switch (section.toLowerCase()) {
      case 'bio':
        targetOffset = 300;
        break;
      case 'status':
        targetOffset = 600;
        break;
      case 'stats':
      case 'statistics':
        targetOffset = 900;
        break;
      case 'settings':
        targetOffset = 1200;
        break;
      default:
        targetOffset = 0;
    }

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    debugPrint('📜 Scrolled to $section');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Scroll to top button
          AiActionWidget(
            actionId: 'scroll_to_top',
            description: 'Scroll to the top of the profile page',
            onExecute: _scrollToTop,
            child: IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: _scrollToTop,
              tooltip: 'Scroll to top',
            ),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Picture
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, size: 60, color: Colors.blue),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: AiActionWidget(
                    actionId: 'change_profile_picture',
                    description: 'Change or update profile picture',
                    onExecute: () {
                      debugPrint('📸 Profile picture updated!');
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Name with edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _name,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              AiActionWidget(
                actionId: 'edit_name',
                description: 'Edit or change the profile name',
                onExecute: _editName,
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _editName,
                  tooltip: 'Edit Name',
                ),
              ),
            ],
          ),

          // Email
          Center(
            child: Text(
              _email,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),

          // Bio Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bio',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_bio),
                  const SizedBox(height: 12),
                  AiActionWidget(
                    actionId: 'update_bio',
                    description:
                        'Update or change the profile bio/description. Specify the new bio text.',
                    parameters: const [
                      AgentActionParameter.string(
                        name: 'bio_text',
                        description: 'New bio text to display',
                      ),
                    ],
                    immediateRegistration: true,
                    onExecuteWithParams: (params) {
                      // Accept multiple parameter name variations
                      final newBio = params['bio_text'] as String? ??
                          params['new_bio_text'] as String? ??
                          params['bio'] as String? ??
                          params['text'] as String?;
                      if (newBio != null && newBio.isNotEmpty) {
                        _changeBio(newBio);
                      }
                    },
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final controller =
                                TextEditingController(text: _bio);
                            return AlertDialog(
                              title: const Text('Edit Bio'),
                              content: TextField(
                                controller: controller,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Bio',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _changeBio(controller.text);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Bio'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Text Field Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  AiActionWidget(
                    actionId: 'update_status',
                    description:
                        'Update or change the current status message. Specify the new status text.',
                    parameters: const [
                      AgentActionParameter.string(
                        name: 'status_text',
                        description: 'New status message',
                      ),
                    ],
                    immediateRegistration: true,
                    onExecuteWithParams: (params) {
                      // Accept multiple parameter name variations
                      final newStatus = params['status_text'] as String? ??
                          params['new_status_text'] as String? ??
                          params['status'] as String? ??
                          params['text'] as String?;
                      if (newStatus != null && newStatus.isNotEmpty) {
                        _changeStatus(newStatus);
                      }
                    },
                    child: TextField(
                      controller: _statusController,
                      decoration: InputDecoration(
                        hintText: 'Enter your current status',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.message),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _statusController.clear();
                          },
                          tooltip: 'Clear',
                        ),
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        // Auto-save on change
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tip: Say "update my status to [your message]" to change it with AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Posts', '127'),
                      _buildStatItem('Followers', '1.2K'),
                      _buildStatItem('Following', '384'),
                      _buildStatItem('Views', '$_profileViews'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Settings Section
          Card(
            child: Column(
              children: [
                AiActionWidget(
                  actionId: 'toggle_notifications',
                  description: 'Turn notifications on or off',
                  onExecute: () {
                    setState(() {
                      _notificationsEnabled = !_notificationsEnabled;
                    });
                    debugPrint(_notificationsEnabled
                        ? '🔔 Notifications enabled'
                        : '🔕 Notifications disabled');
                  },
                  child: SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Receive push notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      debugPrint(value
                          ? '🔔 Notifications enabled'
                          : '🔕 Notifications disabled');
                    },
                    secondary: const Icon(Icons.notifications),
                  ),
                ),
                const Divider(),
                AiActionWidget(
                  actionId: 'view_privacy_settings',
                  description: 'Open or view privacy settings',
                  onExecute: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Privacy Settings'),
                        content: const Text(
                          'Privacy settings would be shown here.\n\n'
                          '• Public Profile\n'
                          '• Private Messages\n'
                          '• Data Sharing\n'
                          '• Location Services',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy Settings'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Privacy Settings'),
                          content: const Text(
                            'Privacy settings would be shown here.\n\n'
                            '• Public Profile\n'
                            '• Private Messages\n'
                            '• Data Sharing\n'
                            '• Location Services',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                AiActionWidget(
                  actionId: 'logout',
                  description: 'Log out of the application',
                  onExecute: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              debugPrint('👋 Logged out');
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                debugPrint('👋 Logged out');
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Hidden action to go back to home
                AiActionWidget(
                  actionId: 'go_back',
                  description: 'Go back to home page, return to main screen',
                  immediateRegistration: true,
                  onExecuteAsync: () async {
                    if (mounted) {
                      Navigator.pop(context);
                      await Future.delayed(const Duration(milliseconds: 500));
                    }
                  },
                  child: const SizedBox.shrink(), // Hidden action
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Scroll Controls Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Scroll',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AiActionWidget(
                        actionId: 'scroll_to_bottom',
                        description: 'Scroll to the bottom of the profile page',
                        onExecute: _scrollToBottom,
                        child: ElevatedButton.icon(
                          onPressed: _scrollToBottom,
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          label: const Text('Bottom'),
                        ),
                      ),
                      AiActionWidget(
                        actionId: 'scroll_to_bio',
                        description: 'Scroll to the bio section',
                        onExecute: () => _scrollToSection('bio'),
                        child: OutlinedButton.icon(
                          onPressed: () => _scrollToSection('bio'),
                          icon: const Icon(Icons.person, size: 16),
                          label: const Text('Bio'),
                        ),
                      ),
                      AiActionWidget(
                        actionId: 'scroll_to_stats',
                        description: 'Scroll to the statistics section',
                        onExecute: () => _scrollToSection('stats'),
                        child: OutlinedButton.icon(
                          onPressed: () => _scrollToSection('stats'),
                          icon: const Icon(Icons.bar_chart, size: 16),
                          label: const Text('Stats'),
                        ),
                      ),
                      AiActionWidget(
                        actionId: 'scroll_to_settings',
                        description: 'Scroll to the settings section',
                        onExecute: () => _scrollToSection('settings'),
                        child: OutlinedButton.icon(
                          onPressed: () => _scrollToSection('settings'),
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Settings'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Back button with immediate registration
          AiActionWidget(
            actionId: 'go_back',
            description: 'Return home, close profile, exit current screen',
            immediateRegistration: true,
            onExecute: () {
              Navigator.of(context).pop();
            },
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
