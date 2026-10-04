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
    Psychologist(
      id: 'psy_006',
      name: 'Dr. Meera Iyer',
      title: 'Child & Adolescent Psychologist',
      specializations: [ScreeningDomain.anxiety, ScreeningDomain.interpersonal],
      yearsExperience: 9,
      rating: 4.7,
      reviewCount: 112,
      consultationFee: 1400,
      consultationMode: 'Online & In-person',
      bio:
          'Dr. Iyer works with teenagers and young adults facing anxiety, social pressure and '
          'difficult family dynamics. She blends play-based and cognitive approaches and involves '
          'family members where it helps, always keeping the young person at the centre.',
    ),
    Psychologist(
      id: 'psy_007',
      name: 'Dr. Karan Malhotra',
      title: 'Sleep & Stress Specialist',
      specializations: [ScreeningDomain.stress, ScreeningDomain.depression],
      yearsExperience: 11,
      rating: 4.6,
      reviewCount: 88,
      consultationFee: 1600,
      consultationMode: 'Online',
      bio:
          'Dr. Malhotra treats stress, burnout and the sleep problems that come with them. He uses '
          'CBT for insomnia, relaxation training and workload coaching to help professionals and '
          'students get their energy and routines back.',
    ),
    Psychologist(
      id: 'psy_008',
      name: 'Dr. Fatima Khan',
      title: 'Student Wellbeing Counsellor',
      specializations: [ScreeningDomain.anxiety, ScreeningDomain.stress],
      yearsExperience: 7,
      rating: 4.8,
      reviewCount: 143,
      consultationFee: 1100,
      consultationMode: 'Online & In-person',
      bio:
          'Dr. Khan supports college students with exam anxiety, perfectionism and the pressure of '
          'big life transitions. Her sessions are practical and structured, with tools you can use '
          'between appointments.',
    ),
    Psychologist(
      id: 'psy_009',
      name: 'Dr. Rahul Nair',
      title: 'Clinical Psychologist, Mood Disorders',
      specializations: [ScreeningDomain.depression, ScreeningDomain.anxiety],
      yearsExperience: 14,
      rating: 4.9,
      reviewCount: 201,
      consultationFee: 2200,
      consultationMode: 'In-person',
      bio:
          'Dr. Nair is a senior clinician in persistent low mood, depression and related anxiety. '
          'He combines behavioural activation, CBT and, when needed, coordination with psychiatrists '
          'for a complete care plan.',
    ),
    Psychologist(
      id: 'psy_010',
      name: 'Dr. Ishita Banerjee',
      title: 'Couples & Family Therapist',
      specializations: [ScreeningDomain.interpersonal, ScreeningDomain.stress],
      yearsExperience: 13,
      rating: 4.7,
      reviewCount: 176,
      consultationFee: 1900,
      consultationMode: 'Online & In-person',
      bio:
          'Dr. Banerjee helps people with relationship conflict, communication breakdowns and the '
          'stress of family expectations. She works with individuals, couples and families using '
          'systemic and emotion-focused therapy.',
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
