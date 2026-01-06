# LingoLog
### *A Personal Language Learning Companion for the Immersion-Based Learner*

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Language](https://img.shields.io/badge/Language-Swift-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg)
![Framework](https://img.shields.io/badge/Framework-SwiftUI-red.svg)
![Database](https://img.shields.io/badge/Database-CoreData-blue.svg)

LingoLog is a high-fidelity iOS application designed for intermediate language learners who prioritize immersion. Unlike flashcard apps that rely on pre-built decks, LingoLog empowers users to capture vocabulary from their daily lives—K-dramas, podcasts, or street signs—and master them using a scientifically-backed Spaced Repetition System (SRS).

---

## Demo

<p align="center">
  <img src="docs/screenshots/dashboard.png" width="250" alt="Dashboard View"/>
  <img src="docs/screenshots/add-word.png" width="250" alt="Add Word View"/>
  <img src="docs/screenshots/word-list.png" width="250" alt="Quiz View"/>
</p>

| Dashboard | Add Word | Quiz |
|:---------:|:--------:|:----:|
| At-a-glance stats on your study streak and upcoming reviews | Real-time translation powered by Azure AI | Test your vocabulary with spaced repetition quizzes |

---

## Key Features

### Intelligent Spaced Repetition (SRS)
- **Mastery Calibration**: A 5-level system that tracks your familiarity with each word.
- **Dynamic Scheduling**: Review intervals expand as mastery increases (1, 3, 7, 14, 30 days), optimizing long-term retention.
- **Smart Quizzing**: The app dynamically filters "Due for Review" words, ensuring you only study what you're about to forget.

### Context-Aware Learning
- **Real-time Translation**: Integrated with **Azure AI Translator** for instant, accurate lookups.
- **Context Tagging**: Users can record *where* they encountered a word (e.g., "In a restaurant menu in Seoul"), creating stronger mental associations.

### Native User Experience
- **Glassmorphism Design**: A custom design system built in SwiftUI using vibrant gradients, blurs, and micro-animations.
- **Dynamic Dashboard**: At-a-glance stats on your study streak, word count, and upcoming reviews.

---

## Technical Architecture

LingoLog is built with a focus on clean code and modern iOS best practices:

- **SwiftUI**: Utilizes a declarative UI approach with custom `ViewModifiers` for a consistent design system.
- **Core Data**: Local-first persistence handling complex queries for SRS scheduling and distinctive language filtering.
- **MVVM Architecture**: Ensures a clean separation between business logic, data management, and the view layer.
- **Service-Oriented Design**: Encapsulated network logic for Azure AI services, featuring secure API key management and robust error handling.

---

## Challenges & Learnings

### 1. Complex State in SwiftUI
Handling real-time translation feedback while ensuring the UI remained responsive required deep dives into `@StateObject` and `@Published` patterns, specifically when managing the lifecycle of the `TranslationService`.

### 2. Spaced Repetition Logic in Core Data
Implementing a performant "Next Review Date" calculation directly within Core Data predicates allowed the app to remain snappy even as the vocabulary list grows into the thousands.

---

## Getting Started

### Prerequisites
- **Xcode 15+** (with iOS 17+ SDK)
- **Azure Translator API Key** ([Get one here](https://azure.microsoft.com/en-us/products/ai-services/ai-translator))

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MinjaeKim09/LingoLog.git
   cd LingoLog
   ```

2. **Configure your API key:**
   - Copy the example secrets file:
     ```bash
     cp LingoLog/Secrets.plist.example LingoLog/Secrets.plist
     ```
   - Open `LingoLog/Secrets.plist` and replace `YOUR_AZURE_TRANSLATOR_API_KEY_HERE` with your actual Azure Translator API key.
   - **Note:** `Secrets.plist` is in `.gitignore` and will not be committed to version control.

3. **Open and run:**
   - Open `LingoLog.xcodeproj` in Xcode.
   - Select your target device or simulator.
   - Build and Run (⌘R).

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contact
**Minjae Kim** - [LinkedIn](https://www.linkedin.com/in/minjae-kim09/) - [Email](mailto:kim.minjae@nyu.edu)