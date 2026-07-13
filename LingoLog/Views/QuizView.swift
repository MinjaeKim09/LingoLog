import SwiftUI

struct QuizView: View {
    let wordRepository: WordRepository
    let dataManager: DataManager
    @ObservedObject var languageSpaceManager: LanguageSpaceManager
    @State private var showingSession = false
    @StateObject private var homeViewModel: QuizHomeViewModel
    @StateObject private var sessionViewModel: QuizSessionViewModel
    
    init(
        wordRepository: WordRepository,
        dataManager: DataManager,
        languageSpaceManager: LanguageSpaceManager
    ) {
        self.wordRepository = wordRepository
        self.dataManager = dataManager
        self.languageSpaceManager = languageSpaceManager
        _homeViewModel = StateObject(wrappedValue: QuizHomeViewModel(
            wordRepository: wordRepository,
            languageSpaceManager: languageSpaceManager
        ))
        _sessionViewModel = StateObject(
            wrappedValue: QuizSessionViewModel(
                wordRepository: wordRepository,
                dataManager: dataManager,
                languageSpaceManager: languageSpaceManager
            )
        )
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            if showingSession {
                QuizSessionView(
                    viewModel: sessionViewModel,
                    onDismiss: {
                        withAnimation {
                            showingSession = false
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                QuizHomeView(
                    viewModel: homeViewModel,
                    onStartQuiz: {
                        withAnimation {
                            sessionViewModel.loadWordsForQuiz()
                            showingSession = true
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            }
        }
    }
}

#Preview {
    QuizView(
        wordRepository: WordRepository(dataManager: DataManager.shared),
        dataManager: DataManager.shared,
        languageSpaceManager: LanguageSpaceManager.shared
    )
}
