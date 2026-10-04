# MindCare — Project Transfer & Context Handoff for LLM (Antigravity / Claude Code)

> **Instructions for the Incoming AI Assistant**:
> You are picking up development of **MindCare**, a privacy-first, full-stack mental health adaptive screening and psychologist consultation platform built with **Flutter** and **Firebase**.
> Below is a comprehensive breakdown of the application architecture, what has been implemented, how it works, the database schema, and pending tasks so you can immediately continue coding without missing context.

---

## 1. Project Overview & Core Mission
MindCare is a clinical-grade mental health triage and consultation app designed to replace cold, rigid, multiple-choice screening questionnaires (like PHQ-9 or GAD-7) with an **empathetic, interactive AI chatbot**.
- **Privacy First**: Mental health data is extremely sensitive. Instead of passing user text to external third-party LLM cloud APIs (OpenAI/Gemini) which poses privacy and compliance risks, the text sentiment and severity scoring is done **entirely on-device** using a hybrid clinical NLP analyzer.
- **Adaptive Clinical Screening**: Rather than asking 20 static questions, an **Adaptive Diagnostic Engine** selects questions in 3 phases:
  1. *Broad Screening*: Probing 4 core domains (Depression, Anxiety, Stress, Interpersonal / Trauma).
  2. *Focused Inquiry*: Dynamically branching into the highest-risk domain based on previous answers.
  3. *Confirmation*: Asking targeted verification questions to gauge clinical severity.
- **Clinician-in-the-Loop**: Patients are intentionally **not** shown self-diagnostic labels (like "Severe Depression") to prevent panic or premature disengagement. Instead, an explainable clinical report with full reasoning traces and sentiment breakdowns is securely stored in Firestore and delivered to the chosen licensed psychologist.
- **Psychologist Matching & Booking**: Recommends psychologists based on domain specialization match scores. Psychologists have a dedicated dashboard to accept/decline requests, review patient clinical reports, and schedule appointments.

---

## 2. Technology Stack & Key Dependencies
- **Frontend / Framework**: Flutter 3.x, Dart 3.x (Null safety enabled)
- **State Management**: `Provider` (MVVM architecture: ViewModels + Services + Views)
- **Typography & UI**: `google_fonts` (Nunito & Inter), Custom Design System "Sage & Sand" (`lib/config/theme.dart`)
- **Backend & Cloud Database**:
  - `firebase_core`: ^3.12.1
  - `firebase_auth`: ^5.5.1 (Email & Password authentication for Patients & Psychologists)
  - `cloud_firestore`: ^5.6.5 (NoSQL real-time document store)
- **Platforms Supported**: Flutter Web, Windows Desktop, Android, iOS.

---

## 3. Architecture & Directory Structure
```
mindcare/
├── lib/
│   ├── config/
│   │   └── theme.dart                 # MindCareTheme: "Sage & Sand" palette, typography, radii, shadows
│   ├── data/
│   │   ├── afinn_lexicon.dart         # AFINN-165 sentiment lexicon map (on-device sentiment scores -5 to +5)
│   │   ├── mental_health_lexicon.dart # Domain keywords, clinical weights, intensifiers, negation rules
│   │   ├── quiz_questions_data.dart   # Question bank (15+ questions across 4 clinical domains)
│   │   └── seed_psychologists.dart    # 5 Seed psychologist profiles with specializations & bios
│   ├── models/
│   │   ├── chat_message.dart          # ChatMessage model (text, sender, sentimentScore, emotionLabel)
│   │   ├── consultation.dart          # ConsultationRequest model (status: pending/accepted/declined)
│   │   ├── domain_evidence.dart       # DomainEvidence tracking scores, answers, and clinical confidence
│   │   ├── psychologist.dart          # Psychologist model (name, bio, specializations, rate, match score)
│   │   ├── quiz_answer.dart           # QuizAnswer model (maps questionId to numeric answer & notes)
│   │   ├── quiz_question.dart         # QuizQuestion model (id, text, domain, phase, severityWeight)
│   │   ├── screening_result.dart      # ScreeningResult (primary/secondary domain, severity, reasoning trace)
│   │   └── user_model.dart            # AppUser model (id, name, email, role: patient / psychologist)
│   ├── services/
│   │   ├── adaptive_engine.dart       # 3-phase question selector & adaptive diagnostic algorithm
│   │   ├── auth_service.dart          # Firebase Auth (signUp, signIn, signOut/logout, role resolution)
│   │   ├── consultation_service.dart  # Legacy in-memory service, bridging with FirestoreService
│   │   ├── firestore_service.dart     # Firestore CRUD (users, screenings, consultations, psychologists)
│   │   ├── report_generator.dart      # Generates explainable screening results & psychologist reports
│   │   └── sentiment_analyzer.dart    # On-device clinical sentiment & emotion analyzer
│   ├── viewmodels/
│   │   ├── chat_viewmodel.dart        # ChatViewModel: drives chatbot UI, text processing & state
│   │   ├── consultation_viewmodel.dart# ConsultationViewModel: booking flow & status
│   │   ├── psychologist_viewmodel.dart# PsychologistViewModel: directory search & filtering
│   │   └── quiz_viewmodel.dart        # Legacy static quiz ViewModel (kept for backwards compatibility)
│   ├── views/
│   │   ├── chat_screening_screen.dart # Interactive chatbot screening UI with typing indicators & chips
│   │   ├── login_screen.dart          # Role-based Email/Password Sign In & Sign Up with Firebase
│   │   ├── processing_screen.dart     # Calming transition animation while report generates
│   │   ├── psychologist_profile_screen.dart # Psychologist details, bios, fee, book button
│   │   ├── quiz_intro_screen.dart     # Intro screen before starting chatbot session
│   │   ├── quiz_screen.dart           # Legacy multiple-choice screen (fallback)
│   │   ├── recommendations_screen.dart# Recommended psychologists ranked by clinical match score
│   │   ├── screening_complete_screen.dart # Reassurance screen after chat screening completes
│   │   ├── share_more_screen.dart     # Optional freeform text area for patient's personal note
│   │   ├── welcome_screen.dart        # Welcome landing screen
│   │   └── psychologist/
│   │       ├── dashboard_screen.dart  # Psychologist dashboard (pending requests, patients list)
│   │       ├── patient_report_screen.dart # Detailed clinical triage report with reasoning traces
│   │       └── schedule_appointment_screen.dart # Appointment date/time picker & acceptance
│   ├── firebase_options.dart          # Generated Firebase project configuration
│   └── main.dart                      # App entry point, Firebase initialization & psychologist seeding
```

---

## 4. Detailed Component Implementation

### 4.1 On-Device Sentiment & Emotion Analyzer (`lib/services/sentiment_analyzer.dart`)
- **Privacy Architecture**: Runs purely client-side with zero external API calls.
- **Hybrid Scoring**:
  1. Tokenizes input text, applies negation window (e.g., "not happy" flips polarity).
  2. Detects intensifiers (e.g., "extremely anxious" scales score by 1.5x).
  3. Matches against AFINN-165 sentiment dictionary (`lib/data/afinn_lexicon.dart`).
  4. Matches against `MentalHealthLexicon` (`lib/data/mental_health_lexicon.dart`) which tags clinical keywords (e.g., panic, despair, insomnia, trauma) to `ScreeningDomain` hints.
  5. Translates response polarity into a severity score (0 to 3) aligned with standard clinical scoring.
  6. Checks for crisis/emergency indicators (self-harm, suicide) to trigger safety interventions.

### 4.2 Conversational Chatbot Screening (`lib/viewmodels/chat_viewmodel.dart` & `lib/views/chat_screening_screen.dart`)
- Asks questions from `lib/data/quiz_questions_data.dart`.
- Allows users to type freeform text or pick quick-reply chips.
- Bot responds with empathetic acknowledging replies before delivering the next clinical question.
- Tracks phase progression: Broad -> Focused -> Confirmation -> Complete.
- Once finished, compiles `ScreeningResult` via `ReportGenerator` and saves the screening and chat log to Firestore under `screenings/{screeningId}`.

### 4.3 Firebase Full-Stack Backend Integration
- **Auth**: `AuthService` handles `signUp` and `signIn` using `FirebaseAuth`. User profile with role (`patient` or `psychologist`) is saved in Firestore `users/{uid}`.
- **Firestore Collections**:
  - `users/{uid}`: `{ name, email, role, psychologistId, createdAt }`
  - `psychologists/{id}`: `{ id, name, title, bio, rating, reviewCount, hourlyRate, specializations, imageUrl, available }` (Auto-seeded at app launch via `_seedPsychologists()` in `main.dart`).
  - `screenings/{screeningId}`: `{ userId, timestamp, primaryDomain, secondaryDomain, domainScores, severityLabels, reasoningTrace, patientNote, messages }`
  - `consultations/{consultationId}`: `{ patientId, patientName, patientEmail, psychologistId, screeningId, status, requestedAt, scheduledDate, notes }`

### 4.4 Clinical Report & Psychologist Dashboard
- **Screening Complete Screen**: Empathetically informs the patient that their responses were safely recorded and routes them to matched specialists.
- **Psychologist Dashboard**:
  - Shows incoming consultation requests from real Firestore stream or seed fallback.
  - Clicking a request opens `PatientReportScreen` showing the full reasoning trace: dominant risk domains, individual answer weights, sentiment analysis scores, and patient notes.
  - Allows psychologist to accept, reschedule, or decline requests.

---

## 5. Current Working Status & Verification
- **Code Health**: `flutter analyze` has **0 errors**. All deprecated members (`withOpacity` -> `withValues`) and unused imports have been cleaned up.
- **Git Branch**: Currently on `main`. Branch contains:
  - All recent work from `shuchi` branch merged cleanly.
  - Full chatbot implementation with on-device sentiment analyzer.
  - Complete Firebase authentication and Firestore integration.
  - Updated navigation flow routing from Quiz Intro directly into Chatbot.

---

## 6. How to Run & Test
### Web:
```bash
flutter run -d chrome
```
### Windows:
```bash
flutter run -d windows
```

### Testing the User Flow:
1. Open the app -> Welcome Screen -> Sign Up / Sign In as a **Patient**.
2. Click **Start Screening** -> Enter the **Chatbot Screen**.
3. Type natural responses (e.g., "I've been feeling overwhelmed with university exams and can't sleep").
4. Observe the on-device sentiment analyzer extracting keywords, acknowledging your feelings, and adapting questions.
5. Finish screening -> View matched psychologists -> Send a Consultation Request.
6. Log out and Sign In as a **Psychologist** (`sarah.mitchell@mindcare.com` or demo credentials).
7. Review the incoming request, examine the clinical reasoning report, and accept the consultation.

---

## 7. Recommended Next Steps / Roadmap
1. **Realtime Firestore Streams for Consultations**: Wire `consultations` collection directly to real-time snapshot listeners in `PsychologistDashboardScreen` so new patient requests appear instantly without page refresh.
2. **In-App Messaging / Consultation Chat**: Add a 1-on-1 private messaging screen between patient and psychologist once a consultation request is accepted.
3. **Appointment Notification Push**: Integrate Firebase Cloud Messaging (FCM) or local notifications when appointment status updates.
4. **Export Report to PDF**: Allow psychologists to export the explainable triage report as a PDF for medical records.
