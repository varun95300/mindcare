import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../data/seed_psychologists.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';
import '../widgets/ui.dart';

/// Direct chat between a patient and their psychologist about one request.
/// The same screen is used by both sides; [asDoctor] says who is looking.
class ConsultationChatScreen extends StatefulWidget {
  final String requestId;
  final bool asDoctor;

  const ConsultationChatScreen({
    super.key,
    required this.requestId,
    required this.asDoctor,
  });

  @override
  State<ConsultationChatScreen> createState() => _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  ConsultationService? _service;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service = context.read<ConsultationService>();
      _service!.markRead(widget.requestId, asDoctor: widget.asDoctor);
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    // Anything that arrived while this screen was open counts as read.
    _service?.markRead(widget.requestId, asDoctor: widget.asDoctor);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<ConsultationService>().sendDirectMessage(
          widget.requestId,
          fromDoctor: widget.asDoctor,
          text: text,
        );
    _controller.clear();
    _scrollToEnd();
  }

  String _time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final clock = '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
    return sameDay ? clock : '${d.day}/${d.month} $clock';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ConsultationService>();
    final request = service.byId(widget.requestId);
    final text = Theme.of(context).textTheme;

    if (request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('This conversation no longer exists.')),
      );
    }

    final doctor = SeedPsychologists.getById(request.psychologistId);
    final otherName =
        widget.asDoctor ? request.patientName : (doctor?.name ?? 'Psychologist');
    final closed = request.status == ConsultationStatus.declined;

    // New messages arriving while open should scroll into view.
    _scrollToEnd();
    if (request.unreadFor(asDoctor: widget.asDoctor) > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          service.markRead(widget.requestId, asDoctor: widget.asDoctor);
        }
      });
    }

    return Scaffold(
      backgroundColor: MindCareTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(otherName.replaceFirst('Dr. ', ''), size: 36),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherName, style: text.titleMedium?.copyWith(fontSize: 16)),
                Text(
                  widget.asDoctor
                      ? 'Patient · ${request.status.label}'
                      : '${doctor?.title ?? 'Psychologist'} · ${request.status.label}',
                  style: text.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Container(
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: MindCareTheme.border),
              ),
            ),
            child: Column(
              children: [
                if (request.scheduledAtLabel != null &&
                    request.status == ConsultationStatus.accepted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: MindCareTheme.primaryLight.withValues(alpha: 0.5),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available,
                            size: 18, color: MindCareTheme.primaryDark),
                        const SizedBox(width: 8),
                        Text('Session: ${request.scheduledAtLabel}',
                            style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: MindCareTheme.primaryDark)),
                      ],
                    ),
                  ),
                Expanded(
                  child: request.messages.isEmpty
                      ? EmptyState(
                          icon: Icons.forum_outlined,
                          title: 'No messages yet',
                          message: widget.asDoctor
                              ? 'Say hello, or ask the patient anything you would like to know before you meet.'
                              : 'Send a message to your psychologist, for example to ask a question before your session.',
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: request.messages.length,
                          itemBuilder: (context, i) {
                            final m = request.messages[i];
                            final mine = m.fromDoctor == widget.asDoctor;
                            return _Bubble(
                              text: m.text,
                              time: _time(m.sentAt),
                              mine: mine,
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: MindCareTheme.surface,
                    border:
                        Border(top: BorderSide(color: MindCareTheme.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: closed
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'This request was declined, so the chat is closed.',
                              style: text.bodyMedium,
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  minLines: 1,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _send(),
                                  decoration: InputDecoration(
                                    hintText: 'Write a message...',
                                    filled: true,
                                    fillColor: MindCareTheme.background,
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _send,
                                style: IconButton.styleFrom(
                                    backgroundColor: MindCareTheme.primary),
                                icon: const Icon(Icons.send_rounded),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final String time;
  final bool mine;

  const _Bubble({required this.text, required this.time, required this.mine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: mine
              ? MindCareTheme.primary.withValues(alpha: 0.55)
              : MindCareTheme.surface,
          border: mine ? null : Border.all(color: MindCareTheme.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: theme.bodyLarge?.copyWith(
                  fontSize: 14.5,
                  color: MindCareTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10.5,
                color: MindCareTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
