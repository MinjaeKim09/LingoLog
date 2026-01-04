# LingoLog - Personal Language Learning Companion

LingoLog is an iOS app designed for intermediate language learners who want to build and maintain their vocabulary through daily practice and spaced repetition.

## Features

### Core Functionality
- **Quick Word Input**: Add new vocabulary words you encounter throughout the day.
- **Context Tracking**: Remember where you heard/saw each word (e.g., "K-drama", "restaurant menu").
- **Spaced Repetition**: Intelligent quiz scheduling based on your mastery level.
- **Progress Tracking**: Visual indicators showing your learning progress for each word.

### User Interface
- **Dashboard**: Overview of your learning progress and quick access to main features.
- **Word Management**: Browse, search, and filter your vocabulary by language.
- **Interactive Quizzes**: Test your knowledge with context-aware questions.
- **Settings**: Export data, view statistics, and manage your learning journey.

### Learning Algorithm
- **5-Level Mastery System**: Words progress from 0 to 5 mastery levels.
- **Adaptive Scheduling**: Review intervals increase as you master words (1, 3, 7, 14, 30, 90 days).
- **Smart Quizzing**: Only shows words that are due for review.

## How It Works

### Adding Words
1. Tap the "Add Word" button or use the quick action.
2. Enter the word in the target language.
3. Provide the translation.
4. Select the language (Korean, Japanese, Chinese, Spanish, etc.).
5. Optionally add context (where you heard/saw the word).

### Taking Quizzes
1. The app automatically tracks which words are due for review.
2. Take quizzes to test your knowledge.
3. Correct answers increase mastery level, incorrect answers decrease it.
4. Words are considered "mastered" at level 5.

### Technical Details

#### Architecture
- **SwiftUI**: Modern declarative UI framework.
- **Core Data**: Persistent storage for vocabulary and progress.
- **MVVM Pattern**: Clean separation of concerns.
- **Spaced Repetition Algorithm**: Based on proven learning science.
- **Azure Translator**: Integrated for automated translations (requires API Key).

#### Data Model
Each word entry includes:
- Word and translation.
- Language and context.
- Date added and last reviewed.
- Mastery level (0-5) and review count.
- Next review date (calculated automatically).

## Getting Started

1. Clone the repository.
2. Create `Secrets.plist` in the `LingoLog` directory.
3. Add your Azure Translator API Key with the key `TranslatorAPIKey` to `Secrets.plist`.
4. Open the project in Xcode.
5. Build and run on an iOS device or simulator.

## Target Users

LingoLog is perfect for:
- **Intermediate language learners** who already have basic vocabulary.
- **People learning through immersion** (media, conversations, reading).
- **Busy learners** who want to capture vocabulary quickly.
- **Self-directed learners** who prefer spaced repetition.

## Privacy

- All data is stored locally on your device.
- No personal data is shared with third parties.
- Export functionality allows you to backup your vocabulary.
