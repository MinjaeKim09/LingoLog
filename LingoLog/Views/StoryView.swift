import SwiftUI

struct StoryView: View {
    let wordRepository: WordRepository
    let storyRepository: StoryRepository
    let storyService: GeminiService
    let storeManager: StoreManager
    @ObservedObject var languageSpaceManager: LanguageSpaceManager
    
    @StateObject private var viewModel: StoryViewModel
    
    init(
        wordRepository: WordRepository,
        storyRepository: StoryRepository,
        storyService: GeminiService = .shared,
        storeManager: StoreManager = .shared,
        languageSpaceManager: LanguageSpaceManager
    ) {
        self.wordRepository = wordRepository
        self.storyRepository = storyRepository
        self.storyService = storyService
        self.storeManager = storeManager
        self.languageSpaceManager = languageSpaceManager
        _viewModel = StateObject(wrappedValue: StoryViewModel(
            wordRepository: wordRepository,
            storyRepository: storyRepository,
            geminiService: storyService,
            storeManager: storeManager,
            languageSpaceManager: languageSpaceManager
        ))
    }
    
    var body: some View {
        ZStack {
            AmbientBackground()
            
            switch viewModel.viewState {
            case .home:
                StoryHomeView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            case .reading:
                StoryReadingView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            case .quiz:
                StoryQuizView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            case .history:
                StoryHistoryView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
        .animation(Theme.Motion.standard, value: viewModel.viewState)
    }
}

#Preview {
    StoryView(
        wordRepository: WordRepository(dataManager: DataManager.shared),
        storyRepository: StoryRepository(dataManager: DataManager.shared),
        languageSpaceManager: LanguageSpaceManager.shared
    )
}
