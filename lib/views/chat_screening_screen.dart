import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../services/auth_service.dart';
import '../services/voice_input_service.dart';
import '../models/chat_message.dart';
import '../models/quiz_question.dart';
import '../config/theme.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

/// Chatbot-style screening screen.
///
/// The bot asks the same adaptive questions as the old quiz, but in a
/// natural chat-bubble interface.  The user types freely instead of
/// picking a Likert option.  Sentiment analysis runs on-device.
class ChatScreeningScreen extends StatefulWidget {
  const ChatScreeningScreen({super.key});

  @override
  State<ChatScreeningScreen> createState() => _ChatScreeningScreenState();
}

class _ChatScreeningScreenState extends State<ChatScreeningScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late ChatViewModel _viewModel;
  final VoiceInputService _voice = VoiceInputService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel();
    _voice.addListener(_onViewModelChanged);
    _voice.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final auth = Provider.of<AuthService>(context, listen: false);
      final patientId = auth.currentUser?.id ?? 'anonymous';
      _viewModel.startConversation(patientId);
      _viewModel.addListener(_onViewModelChanged);
    }
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _voice.removeListener(_onViewModelChanged);
    _voice.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Toggle voice dictation. The transcript fills the text box so the user
  /// can review or edit it, then send as usual.
  void _toggleVoice() {
    if (_voice.isListening) {
      _voice.stop();
      return;
    }
    _voice.start((text, isFinal) {
      _textController.text = text;
      _textController.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  void _handleSend() {
    if (_voice.isListening) _voice.stop();
    if (_viewModel.isBusy) return; // one reply at a time
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _viewModel.sendMessage(text);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MindCareTheme.background,
      appBar: _buildAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            decoration: BoxDecoration(
              color: MindCareTheme.background,
              border: Border.symmetric(
                vertical: BorderSide(color: MindCareTheme.border),
              ),
            ),
            child: Column(
              children: [
                // Progress indicator
                _buildProgressBar(),
                // Chat messages
                Expanded(child: _buildMessageList()),
                // Typing indicator
                if (_viewModel.isTyping) _buildTypingIndicator(),
                // One-tap answers
                if (_viewModel.canQuickReply) _buildQuickReplies(),
                // Input bar or completion prompt
                if (_viewModel.isComplete)
                  _buildCompletionBar()
                else
                  _buildInputBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: MindCareTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: MindCareTheme.textPrimary),
        onPressed: () => _showExitDialog(),
      ),
      title: Row(
        children: [
          const BrandMark(size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MindCare',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MindCareTheme.textPrimary,
                ),
              ),
              Text(
                _viewModel.isTyping ? 'typing...' : 'Wellness Check-in',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color:
                      _viewModel.isTyping
                          ? MindCareTheme.primary
                          : MindCareTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: MindCareTheme.border),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 3,
      color: MindCareTheme.surface,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _viewModel.progress),
        duration: Motion.of(context, const Duration(milliseconds: 500)),
        curve: Curves.easeOut,
        builder:
            (context, v, _) => LinearProgressIndicator(
              value: v,
              backgroundColor: MindCareTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(MindCareTheme.primary),
              minHeight: 3,
            ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _viewModel.messages.length,
      itemBuilder: (context, index) {
        final message = _viewModel.messages[index];
        return _buildMessageBubble(message, index);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isBot = message.isBot;
    final showAvatar =
        isBot && (index == 0 || _viewModel.messages[index - 1].isUser);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: isBot ? 0 : 48,
        right: isBot ? 48 : 0,
      ),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isBot) ...[
            if (showAvatar)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: BrandMark(size: 28),
              )
            else
              const SizedBox(width: 36),
          ],
          Flexible(
            child: _AnimatedBubble(
              isBot: isBot,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isBot ? MindCareTheme.surface : MindCareTheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isBot ? 4 : 18),
                    bottomRight: Radius.circular(isBot ? 18 : 4),
                  ),
                  border:
                      isBot
                          ? Border.all(color: MindCareTheme.border, width: 1)
                          : null,
                  boxShadow: [
                    BoxShadow(
                      color: (isBot
                              ? MindCareTheme.textSecondary
                              : MindCareTheme.primary)
                          .withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    height: 1.45,
                    color: MindCareTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 52, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: MindCareTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: MindCareTheme.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: Duration(milliseconds: 600 + i * 200),
                  curve: Curves.easeInOut,
                  builder: (_, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: MindCareTheme.primary.withValues(
                            alpha: 0.4 + value * 0.4,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Never ... Almost always buttons: a quick way to answer the current
  /// question without typing.
  Widget _buildQuickReplies() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      color: MindCareTheme.surface,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final r in LikertResponse.values)
            ActionChip(
              label: Text(r.label),
              onPressed: () => _viewModel.sendQuickReply(r),
              backgroundColor: MindCareTheme.primaryLight.withValues(
                alpha: 0.5,
              ),
              side: BorderSide(
                color: MindCareTheme.primary.withValues(alpha: 0.4),
              ),
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MindCareTheme.primaryDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        border: Border(top: BorderSide(color: MindCareTheme.border, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: MindCareTheme.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: MindCareTheme.border),
                ),
                child: GlowOnFocus(
                  radius: 24,
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: MindCareTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          _voice.isListening
                              ? 'Listening...'
                              : 'Or type your answer in your own words...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: MindCareTheme.textSecondary.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_voice.isAvailable) ...[
              IconButton(
                tooltip: _voice.isListening ? 'Stop listening' : 'Speak',
                icon: Icon(
                  _voice.isListening ? Icons.stop_circle : Icons.mic_none,
                  color:
                      _voice.isListening
                          ? MindCareTheme.error
                          : MindCareTheme.primary,
                ),
                onPressed: _toggleVoice,
              ),
              const SizedBox(width: 4),
            ],
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: MindCareTheme.primary,
                foregroundColor: MindCareTheme.textPrimary,
              ),
              icon: const Icon(Icons.send_rounded, size: 20),
              onPressed: _viewModel.isBusy ? null : _handleSend,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        border: Border(top: BorderSide(color: MindCareTheme.border, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                '/screening-complete',
                arguments: {
                  'result': _viewModel.result,
                  'screeningId': _viewModel.screeningId,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MindCareTheme.primary,
              foregroundColor: MindCareTheme.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'View My Summary',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showSoftDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: MindCareTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Leave for now?',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: MindCareTheme.textPrimary,
              ),
            ),
            content: Text(
              'Your progress is saved. You can resume this conversation any time.',
              style: GoogleFonts.inter(color: MindCareTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Stay',
                  style: TextStyle(color: MindCareTheme.primary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(
                  'Leave',
                  style: TextStyle(color: MindCareTheme.textSecondary),
                ),
              ),
            ],
          ),
    );
  }
}

/// Animated wrapper that slides and fades in chat bubbles.
class _AnimatedBubble extends StatefulWidget {
  final bool isBot;
  final Widget child;

  const _AnimatedBubble({required this.isBot, required this.child});

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isBot ? -0.3 : 0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
