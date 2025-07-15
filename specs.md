# LingoLog Specs

## Overview
LingoLog is an iOS app for intermediate language learners to build and maintain vocabulary through daily practice and spaced repetition. It is designed for quick word capture, context tracking, and adaptive review scheduling.

## Target Users
- Intermediate language learners
- People learning through immersion (TV, conversation, reading)
- Busy or self-directed learners who prefer spaced repetition

## Core Features
- **Quick Word Input**: Add new vocabulary with translation, language, and context
- **Context Tracking**: Remember where you encountered each word
- **Spaced Repetition**: Adaptive quiz scheduling based on mastery level
- **Progress Tracking**: Visual indicators for each word, review counts, and statistics
- **Word Management**: Browse, search, filter, and delete words by language
- **Interactive Quizzes**: Test knowledge with context-aware questions
- **Notifications**: Daily reminders for words due for review
- **Data Export**: Export vocabulary as CSV
- **Settings**: Manage notifications, export, and reset data

## Main Screens & Navigation
- **Dashboard**: Overview of progress, quick actions (Add Word, Take Quiz), stats, recent words
- **Word List**: Browse/search/filter words, delete, add new word
- **Quiz**: Review words due, answer translation questions, get feedback, see results
- **Settings**: View stats, manage notifications, export/reset data, about section

Navigation is via a bottom TabView with four tabs: Dashboard, Words, Quiz, Settings.

## Data Model
### WordEntry (Core Data)
- `id: UUID`
- `word: String`
- `translation: String`
- `language: String`
- `context: String?`
- `dateAdded: Date`
- `lastReviewed: Date?`
- `masteryLevel: Int (0-5)`
- `isMastered: Bool`
- `nextReviewDate: Date?`
- `reviewCount: Int`

## Algorithms & Logic
### Spaced Repetition & Mastery
- Each word has a mastery level (0-5)
- Correct quiz answers increment mastery (max 5), incorrect decrement (min 0)
- After a correct answer, next review is scheduled for 24 hours later (future: intervals may increase with mastery)
- Incorrect answers make the word immediately due again
- Words are considered "mastered" at level 5
- Only non-mastered, due words are shown in quizzes

### Quiz Flow
- User is shown words due for review
- User types translation; feedback is given (correct/incorrect)
- Mastery level and review count are updated
- Quiz results are shown at the end

### Word Management
- Words can be filtered by language and searched by word, translation, or context
- Words can be deleted
- Recent words and stats are shown on the dashboard

### Notifications
- Daily notification at user-selected time for words due for review
- App badge shows count of due words
- Notifications can be enabled/disabled in settings

### Data Export
- User can export all vocabulary as a CSV file (Word, Translation, Language, Context, Date Added, Mastery Level, Review Count, Is Mastered)
- Export is available via the Settings screen

### Language Detection & Translation
- When adding a word, the app uses the **Apple Translation API** to detect language and provide translation
- User can select the source and target language for translation from a set of supported languages (English, Korean, Japanese, Chinese, Spanish, French, German, Italian, Portuguese, Russian, Arabic)
- Detected language is displayed in the UI
- Prewarming network for translation is no longer required

## Integrations
- **Apple Translation API**: For automatic translation and language detection when adding words
- **UserNotifications**: For daily reminders and app badge updates
- **Core Data**: For local persistent storage of all vocabulary and progress

## Settings & Customization
- Enable/disable daily notifications
- Set daily reminder time
- Export all data as CSV
- Reset all data (delete all words and progress)
- View app version, privacy policy, and terms

## Privacy
- All data is stored locally on device
- No user accounts or authentication; single-user only
- No data is shared with third parties
- Export is manual and user-initiated

## Future Enhancements (from README)
- Audio pronunciation support
- API integrations for richer data
- Cloud sync
- Advanced analytics
- Customizable review schedules
- Social/progress sharing 