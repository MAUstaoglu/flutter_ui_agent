import 'package:flutter/material.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';

/// Global AI chat overlay that stays on top of all pages
class AgentChatOverlay extends StatefulWidget {
  final Widget child;

  const AgentChatOverlay({
    super.key,
    required this.child,
  });

  @override
  State<AgentChatOverlay> createState() => _AgentChatOverlayState();
}

class _AgentChatOverlayState extends State<AgentChatOverlay> {
  bool _isChatOpen = false;
  Offset _fabPosition = const Offset(20, 100); // Initial position
  final List<ChatMessage> _chatHistory = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _chatHistory.add(ChatMessage(text: text, isUser: isUser));
    });
    // Scroll to bottom after adding message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _processQuery(String query) async {
    if (query.trim().isEmpty) return;

    final agentService = AgentServiceProvider.of(context, listen: false);

    // Add user message
    _addMessage(query, true);
    _textController.clear();

    try {
      // Process the query
      final result = await agentService.processQueryWithNavigation(query);

      // Add AI response
      _addMessage(result, false);
    } catch (e) {
      _addMessage('Error: $e', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final maxChatHeight = screenHeight * 0.7; // Max 70% of screen height

    return Stack(
      children: [
        // Main content - always visible and interactive
        widget.child,

        // Chat overlay backdrop with opacity
        Visibility(
          visible: _isChatOpen,
          child: Positioned.fill(
            child: GestureDetector(
              onTap: _toggleChat,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),

        // Chat panel - positioned at bottom right
        Positioned(
          right: 0,
          bottom: keyboardHeight,
          left: screenWidth > 800 ? screenWidth - 400 : 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxChatHeight - keyboardHeight,
            ),
            child: Visibility(
              visible: _isChatOpen,
              maintainState: true, // Keep state even when hidden
              child: _buildChatPanel(),
            ),
          ),
        ),

        // Draggable floating action button
        Positioned(
          left: _fabPosition.dx,
          top: _fabPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _fabPosition = Offset(
                  (_fabPosition.dx + details.delta.dx)
                      .clamp(0.0, screenWidth - 60),
                  (_fabPosition.dy + details.delta.dy)
                      .clamp(0.0, screenHeight - 60),
                );
              });
            },
            child: _buildFAB(),
          ),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    final agentService = AgentServiceProvider.of(context, listen: true);
    final isProcessing = agentService.isProcessing;

    return Material(
      elevation: 8,
      shape: const CircleBorder(),
      color: isProcessing ? Colors.orange : Colors.blue,
      child: InkWell(
        onTap: _toggleChat, // Always clickable
        customBorder: const CircleBorder(),
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _isChatOpen ? Icons.close : Icons.smart_toy,
                color: Colors.white,
                size: 30,
              ),
              if (isProcessing)
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Material(
        elevation: 16,
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: AgentServiceProvider.of(context),
                      builder: (context, _) {
                        final agentService =
                            AgentServiceProvider.of(context, listen: false);
                        final isProcessing = agentService.isProcessing;

                        if (isProcessing) {
                          return IconButton(
                            icon: const Icon(Icons.cancel_outlined,
                                color: Colors.white),
                            onPressed: () {
                              agentService.cancelCurrentRequest();
                            },
                            tooltip: 'Cancel request',
                          );
                        }

                        return IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _chatHistory.clear();
                            });
                          },
                          tooltip: 'Clear chat',
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Chat messages
              Expanded(
                child: _chatHistory.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _chatHistory.length,
                        itemBuilder: (context, index) {
                          return _buildChatBubble(_chatHistory[index]);
                        },
                      ),
              ),

              // Input field
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: _processQuery,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ListenableBuilder(
                      listenable: AgentServiceProvider.of(context),
                      builder: (context, _) {
                        final agentService =
                            AgentServiceProvider.of(context, listen: false);
                        final isProcessing = agentService.isProcessing;

                        return FloatingActionButton(
                          onPressed: isProcessing
                              ? null
                              : () => _processQuery(_textController.text),
                          backgroundColor:
                              isProcessing ? Colors.grey : Colors.blue,
                          child: isProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.send),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Start a conversation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask me to navigate, search,\nor perform actions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              child: Icon(Icons.smart_toy,
                  color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? theme.colorScheme.primary
                    : isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor:
                  theme.colorScheme.secondary.withValues(alpha: 0.2),
              child: Icon(Icons.person,
                  color: theme.colorScheme.secondary, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
  }) : timestamp = DateTime.now();
}
