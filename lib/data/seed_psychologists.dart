import '../models/psychologist.dart';
import '../models/quiz_question.dart';

/// Seed psychologist data for the prototype demo.
class SeedPsychologists {
  static const List<Psychologist> all = [
    Psychologist(
      id: 'psy_001',
      name: 'Dr. Sarah Mitchell',
      title: 'Clinical Psychologist',
      specializations: [ScreeningDomain.anxiety, ScreeningDomain.stress],
      yearsExperience: 12,
      rating: 4.8,
      reviewCount: 156,
      consultationFee: 1500,
      consultationMode: 'Online & In-person',
      bio:
          'Dr. Mitchell is a clinical psychologist specializing in anxiety disorders and stress management. '
          'She uses evidence-based approaches including CBT and mindfulness techniques to help clients '
          'develop effective coping strategies. She has extensive experience working with young adults '
          'and college students.',
    ),
    Psychologist(
      id: 'psy_002',
      name: 'Dr. Raj Patel',
      title: 'Counselling Psychologist',
      specializations: [ScreeningDomain.depression, ScreeningDomain.anxiety],
      yearsExperience: 8,
      rating: 4.6,
      reviewCount: 98,
      consultationFee: 1200,
      consultationMode: 'Online',
      bio:
          'Dr. Patel specializes in mood disorders and anxiety, with a focus on helping clients '
          'navigate depression and low motivation. He combines cognitive-behavioral therapy with '
          'positive psychology approaches to support emotional wellbeing and personal growth.',
    ),
    Psychologist(
      id: 'psy_003',
      name: 'Dr. Priya Sharma',
      title: 'Senior Clinical Psychologist',
      specializations: [ScreeningDomain.stress, ScreeningDomain.interpersonal],
      yearsExperience: 15,
      rating: 4.9,
      reviewCount: 230,
      consultationFee: 2000,
      consultationMode: 'In-person',
      bio:
          'With 15 years of experience, Dr. Sharma is a senior clinical psychologist who specializes '
          'in stress-related conditions and interpersonal difficulties. She works with clients facing '
          'burnout, relationship challenges, and trauma recovery using integrative therapeutic approaches.',
    ),
    Psychologist(
      id: 'psy_004',
      name: 'Dr. David Chen',
      title: 'Trauma & Relationship Specialist',
      specializations: [
        ScreeningDomain.interpersonal,
        ScreeningDomain.depression,
      ],
      yearsExperience: 10,
      rating: 4.7,
      reviewCount: 134,
      consultationFee: 1800,
      consultationMode: 'Online & In-person',
      bio:
          'Dr. Chen specializes in trauma-informed care and interpersonal difficulties. He helps clients '
          'work through trust issues, relationship patterns, and emotional wounds using EMDR and '
          'attachment-based therapy. He creates a safe, supportive space for healing.',
    ),
    Psychologist(
      id: 'psy_005',
      name: 'Dr. Anika Reddy',
      title: 'Wellness Psychologist',
      specializations: [ScreeningDomain.depression, ScreeningDomain.stress],
      yearsExperience: 6,
      rating: 4.5,
      reviewCount: 67,
      consultationFee: 1000,
      consultationMode: 'Online',
      bio:
          'Dr. Reddy focuses on depression, stress, and overall emotional wellness. She is passionate '
          'about making mental health support accessible and uses a blend of CBT, behavioral activation, '
          'and lifestyle interventions. She has a warm, approachable therapeutic style.',
    ),
  ];

  /// Get a psychologist by ID.
  static Psychologist? getById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
