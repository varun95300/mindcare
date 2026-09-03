import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/psychologist.dart';
import '../models/screening_result.dart';
import '../models/consultation.dart';
import '../services/auth_service.dart';
import '../services/consultation_service.dart';

class PsychologistProfileScreen extends StatelessWidget {
  final Psychologist psychologist;
  final PsychologistRecommendation? recommendation;
  final ScreeningResult? screeningResult;

  const PsychologistProfileScreen({
    super.key,
    required this.psychologist,
    this.recommendation,
    this.screeningResult,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final consultationService = context.watch<ConsultationService>();
    final userName = auth.currentUser?.name ?? 'User';
    final userEmail = auth.currentUser?.email ?? '';
    final existingRequest = consultationService.requestFor(
      psychologist.id,
      userName,
    );
    final alreadySent = existingRequest != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Psychologist Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MindCareTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile header
              _ProfileHeader(psychologist: psychologist),
              const SizedBox(height: MindCareTheme.spacingLg),

              // Match info
              if (recommendation != null) ...[
                _MatchCard(recommendation: recommendation!),
                const SizedBox(height: MindCareTheme.spacingLg),
              ],

              // About
              _SectionCard(
                title: 'About',
                icon: Icons.person_outlined,
                child: Text(
                  psychologist.bio,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingMd),

              // Details
              _SectionCard(
                title: 'Details',
                icon: Icons.info_outlined,
                child: Column(
                  children: [
                    _DetailRow(
                        icon: Icons.work_outline,
                        label: 'Experience',
                        value: psychologist.experienceLabel),
                    _DetailRow(
                        icon: Icons.star_outline,
                        label: 'Rating',
                        value:
                            '${psychologist.rating} (${psychologist.reviewCount} reviews)'),
                    _DetailRow(
                        icon: Icons.currency_rupee,
                        label: 'Consultation Fee',
                        value: '₹${psychologist.consultationFee.toInt()}'),
                    _DetailRow(
                        icon: Icons.video_call_outlined,
                        label: 'Mode',
                        value: psychologist.consultationMode),
                  ],
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingMd),

              // Specializations
              _SectionCard(
                title: 'Specializations',
                icon: Icons.psychology_outlined,
                child: Wrap(
                  spacing: MindCareTheme.spacingSm,
                  runSpacing: MindCareTheme.spacingSm,
                  children: psychologist.specializations.map((spec) {
                    final color = MindCareTheme.domainColor(spec.label);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(MindCareTheme.radiusFull),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Text(
                        spec.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: color,
                              fontSize: 14,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: MindCareTheme.spacingXl),

              // Send consultation request button
              if (screeningResult != null && !alreadySent)
                ElevatedButton.icon(
                  onPressed: () {
                    _showSendRequestDialog(
                        context, consultationService, userName, userEmail);
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Reach Out'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                )
              else if (alreadySent)
                _AlreadySentCard(request: existingRequest!)
              else
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Please check in first so we can connect you properly.'),
                        backgroundColor: MindCareTheme.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(MindCareTheme.radiusMd),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Connect'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              const SizedBox(height: MindCareTheme.spacingMd),

              // Info about what gets shared
              if (screeningResult != null && !alreadySent)
                Container(
                  padding: const EdgeInsets.all(MindCareTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: MindCareTheme.surfaceVariant,
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: MindCareTheme.textLight),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'What you shared goes directly to this psychologist so they\'re prepared for you — you won\'t see it yourself, it\'s just for them.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: MindCareTheme.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: MindCareTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendRequestDialog(BuildContext context,
      ConsultationService service, String userName, String userEmail) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        ),
        title: const Text('Reach Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What you shared will be sent directly to ${psychologist.name} so they understand where you\'re coming from before you talk.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: MindCareTheme.spacingMd),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Anything you\'d like them to know? (optional)',
                filled: true,
                fillColor: MindCareTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(MindCareTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              service.sendRequest(
                patientName: userName,
                patientEmail: userEmail,
                psychologistId: psychologist.id,
                screeningResult: screeningResult!,
                message: messageController.text.isNotEmpty
                    ? messageController.text
                    : null,
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${psychologist.name} will be in touch soon. You\'ve taken a great step.'),
                  backgroundColor: MindCareTheme.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(MindCareTheme.radiusMd),
                  ),
                ),
              );
            },
            child: const Text('Reach Out'),
          ),
        ],
      ),
    );
  }
}

/// Shown when the patient has already reached out to this psychologist.
/// If the psychologist has accepted and scheduled a time, that's shown
/// here along with any note they left — this is the one place a patient
/// hears back from their psychologist through the app.
class _AlreadySentCard extends StatelessWidget {
  final ConsultationRequest request;
  const _AlreadySentCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final scheduledLabel = request.scheduledAtLabel;

    if (scheduledLabel == null) {
      return Container(
        padding: const EdgeInsets.all(MindCareTheme.spacingMd),
        decoration: BoxDecoration(
          color: MindCareTheme.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
          border: Border.all(color: MindCareTheme.success.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle,
                color: MindCareTheme.success, size: 22),
            const SizedBox(width: MindCareTheme.spacingSm),
            Text(
              'You\'ve reached out — they\'ll respond soon.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MindCareTheme.success,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        color: MindCareTheme.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        border: Border.all(color: MindCareTheme.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available,
                  color: MindCareTheme.success, size: 22),
              const SizedBox(width: MindCareTheme.spacingSm),
              Expanded(
                child: Text(
                  'Your Appointment is Confirmed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: MindCareTheme.success,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MindCareTheme.spacingSm),
          Text(
            scheduledLabel,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (request.psychologistNote != null) ...[
            const SizedBox(height: MindCareTheme.spacingSm),
            Text(
              '"${request.psychologistNote}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: MindCareTheme.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Psychologist psychologist;
  const _ProfileHeader({required this.psychologist});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: MindCareTheme.heroGradient,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 3),
            ),
            child: Center(
              child: Text(
                psychologist.name
                    .split(' ')
                    .map((w) => w[0])
                    .take(2)
                    .join(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(height: MindCareTheme.spacingMd),
          Text(
            psychologist.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            psychologist.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
          ),
          const SizedBox(height: MindCareTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickStat(
                  value: '${psychologist.rating}',
                  label: 'Rating',
                  icon: Icons.star),
              _QuickStat(
                  value: '${psychologist.yearsExperience}y',
                  label: 'Experience',
                  icon: Icons.work),
              _QuickStat(
                  value: '${psychologist.reviewCount}',
                  label: 'Reviews',
                  icon: Icons.rate_review),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _QuickStat(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final PsychologistRecommendation recommendation;
  const _MatchCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingMd),
      decoration: BoxDecoration(
        color: MindCareTheme.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(MindCareTheme.radiusMd),
        border: Border.all(color: MindCareTheme.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MindCareTheme.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(recommendation.matchScore * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MindCareTheme.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: MindCareTheme.spacingSm),
          Expanded(
            child: Text(recommendation.explanation,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: MindCareTheme.success)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MindCareTheme.spacingLg),
      decoration: BoxDecoration(
        color: MindCareTheme.surface,
        borderRadius: BorderRadius.circular(MindCareTheme.radiusLg),
        boxShadow: MindCareTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: MindCareTheme.primary, size: 22),
            const SizedBox(width: MindCareTheme.spacingSm),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ]),
          const SizedBox(height: MindCareTheme.spacingMd),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MindCareTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: MindCareTheme.textLight),
          const SizedBox(width: MindCareTheme.spacingSm),
          SizedBox(
              width: 120,
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
              child: Text(value,
                  style: Theme.of(context).textTheme.titleMedium)),
        ],
      ),
    );
  }
}
