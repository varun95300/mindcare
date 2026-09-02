# MindCare — Adaptive Mental Health Screening Prototype

> A Flutter-based mental health screening app that demonstrates adaptive questioning, explainable AI-style results, and professional matching.

## 🎯 Project Purpose

MindCare is a **college project prototype** demonstrating how an adaptive screening system can:
1. Ask personalized questions that change based on previous answers (like Akinator)
2. Produce explainable screening reports showing WHY a result was reached
3. Match users with relevant mental health professionals
4. Share screening reports with psychologists for consultation preparation

**⚠️ Important:** This is a SCREENING tool, NOT a clinical diagnostic system. It never tells users they "have" a condition — it only identifies areas that may benefit from professional attention.

---

## 🏗️ Architecture

### Tech Stack
- **Framework:** Flutter 3.47.2 / Dart 3.13.2
- **State Management:** Provider (MVVM pattern)
- **Data:** In-memory mock data (no backend/Firebase yet)
- **Target Platform:** Web (Chrome) for demos

### Project Structure

```
lib/
├── config/
│   └── theme.dart              # Design system (colors, typography, spacing)
├── data/
│   ├── question_bank.dart      # 15 screening questions across 3 phases
│   └── seed_psychologists.dart # 5 psychologist profiles
├── models/
│   ├── quiz_question.dart      # Question model + ScreeningDomain enum
│   ├── quiz_answer.dart        # User answer model
│   ├── domain_evidence.dart    # Evidence tracking per domain
│   ├── screening_result.dart   # Result + reasoning trace models
│   ├── psychologist.dart       # Psychologist + recommendation models
│   ├── consultation.dart       # Consultation request model
│   └── user_model.dart         # User model (student/psychologist)
├── services/
│   ├── adaptive_engine.dart    # Core adaptive question selection
│   ├── report_generator.dart   # Deterministic result generation
│   ├── recommendation_service.dart  # Psychologist matching
│   ├── consultation_service.dart    # Consultation request management
│   └── auth_service.dart       # Demo auth (no real auth)
├── viewmodels/
│   └── quiz_viewmodel.dart     # Quiz state management
└── views/
    ├── welcome_screen.dart     # Landing page
    ├── login_screen.dart       # Demo login (student/psychologist)
    ├── quiz_intro_screen.dart  # Pre-quiz info
    ├── quiz_screen.dart        # Adaptive quiz with animations
    ├── processing_screen.dart  # Post-quiz analysis animation
    ├── report_screen.dart      # Screening report display
    ├── reasoning_screen.dart   # Detailed reasoning trace
    ├── recommendations_screen.dart      # Recommended psychologists
    ├── psychologist_profile_screen.dart  # Individual profile + send request
    └── psychologist/
        ├── dashboard_screen.dart       # Psychologist's dashboard
        └── patient_report_screen.dart  # View patient's screening report
```

---

## ✅ What's Been Done

### Core Engine
- [x] **Adaptive Question Engine** — Rule-based selection across 3 phases:
  - Phase 1 (Broad): General opener questions
  - Phase 2 (Focused): Drills into highest-evidence domain
  - Phase 3 (Confirmation): Validates the emerging profile
- [x] **4 Screening Domains**: Depression, Anxiety, Stress, Sleep Issues
- [x] **15 Questions** with weighted evidence mapping to multiple domains
- [x] **Report Generator** — Produces deterministic, explainable results with:
  - Normalized domain scores + severity labels
  - Key observations explaining what influenced the result
  - Full question-by-question reasoning trace
  - Methodology explanation + disclaimer

### User Flow (Student Side)
- [x] Welcome screen with feature overview
- [x] Demo login screen (Student / Psychologist modes)
- [x] Quiz intro screen explaining the process
- [x] Adaptive quiz with animated transitions
- [x] Post-quiz processing animation
- [x] Full screening report with domain scores
- [x] Detailed reasoning trace (per-question evidence)
- [x] Recommended psychologists ranked by match %
- [x] Psychologist profile with details, specializations, ratings
- [x] Send consultation request (attaches screening report)

### Psychologist Flow
- [x] Psychologist dashboard with stats and consultation requests
- [x] View patient's complete screening report (domains, scores, observations, reasoning trace)
- [x] Accept/decline consultation requests

### Design & UX
- [x] Custom design system (MindCare Theme)
- [x] Gradient hero sections, card-based layouts
- [x] Domain-specific color coding (blue=depression, amber=anxiety, red=stress, indigo=sleep)
- [x] Animated transitions between quiz states
- [x] Responsive layout (optimized for web demo)

---

## 🚧 What's Left To Do

### High Priority (For the Demo)
- [ ] **End-to-end flow testing** — Complete a full run-through to verify all screens connect properly
- [ ] **Polish edge cases** — Handle empty states, back navigation, restart quiz flow
- [ ] **Demo script** — Write a step-by-step presentation script for the teacher

### Medium Priority (Enhancements)
- [ ] **More questions** — Expand from 15 to 25–30 questions for better screening depth
- [ ] **History/multiple screenings** — Let users retake the quiz and compare results
- [ ] **Psychologist availability** — Add time slots and booking calendar
- [ ] **Notifications** — Notify psychologists of new requests (in-app)
- [ ] **Better onboarding** — Add intro carousel explaining how MindCare works
- [ ] **Dark mode** — Theme is ready, just needs a toggle

### Low Priority (Future Scope / Full Product)
- [ ] **Firebase Integration:**
  - [ ] Firebase Auth (Google sign-in, email/password)
  - [ ] Cloud Firestore (persist users, results, consultations)
  - [ ] Firebase Cloud Messaging (push notifications)
- [ ] **Real psychologist onboarding** — Registration, verification, profile editing
- [ ] **Chat/video integration** — In-app messaging or video call with psychologist
- [ ] **ML-based adaptive engine** — Replace rule-based engine with trained model
- [ ] **Localization** — Hindi, regional languages
- [ ] **Mobile optimization** — Android/iOS native builds
- [ ] **Analytics dashboard** — Track screening trends, popular domains
- [ ] **Admin panel** — Manage psychologists, review reports

---

## 🚀 How to Run

### Prerequisites
- Flutter SDK 3.47+ installed and on PATH
- Chrome browser (for web demo)

### Commands
```bash
# Get dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Analyze code
flutter analyze

# Run tests
flutter test
```

### Demo Login
The app has two demo login modes:
- **Student:** Login as "Demo Student" to take the screening quiz
- **Psychologist:** Login as "Dr. Priya Sharma" to see the psychologist dashboard

---

## 👥 For Team Members

### How the Adaptive Engine Works
1. Questions are tagged with a `phase` (1–3) and `evidenceWeights` mapping to domains
2. Phase 1 questions are broad and asked first
3. After Phase 1, the engine looks at which domain has the most evidence and selects Phase 2 questions targeting that domain
4. Phase 3 questions confirm the emerging profile
5. Each answer (0–4 scale) multiplies against the question's evidence weights

### How Recommendations Work
- Each psychologist has `specializations` (list of ScreeningDomains)
- The `RecommendationService` computes a match score based on overlap between the user's top domains and the psychologist's specializations
- Results are sorted by match score descending

### Key Files to Understand
| File | Purpose |
|------|---------|
| `adaptive_engine.dart` | The "brain" — selects next question based on evidence |
| `report_generator.dart` | Produces the explainable screening result |
| `quiz_viewmodel.dart` | Manages quiz state, calls engine + generator |
| `consultation_service.dart` | Bridges user requests with psychologist dashboard |
| `question_bank.dart` | All 15 questions with weights — **edit this to add questions** |
| `seed_psychologists.dart` | Mock psychologist data — **edit to add profiles** |

### Adding New Questions
Edit `lib/data/question_bank.dart`. Each question needs:
```dart
QuizQuestion(
  id: 'unique_id',
  text: 'Question text?',
  phase: 2,  // 1=broad, 2=focused, 3=confirmation
  primaryDomain: ScreeningDomain.anxiety,
  evidenceWeights: {
    ScreeningDomain.anxiety: 1.0,
    ScreeningDomain.stress: 0.3,  // cross-domain weight
  },
)
```

### Adding New Psychologists
Edit `lib/data/seed_psychologists.dart`. Each psychologist needs name, title, bio, specializations, fee (₹), rating, experience years, etc.

---

## 📋 Currency & Locale
- Consultation fees are in **₹ (INR)**
- App language: English

## 📄 License
College project — not for commercial use.
