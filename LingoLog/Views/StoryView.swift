import SwiftUI

struct StoryView: View {
    let wordRepository: WordRepository
    let storyRepository: StoryRepository
    
    @StateObject private var viewModel: StoryViewModel
    
    init(wordRepository: WordRepository, storyRepository: StoryRepository) {
        self.wordRepository = wordRepository
        self.storyRepository = storyRepository
        _viewModel = StateObject(wrappedValue: StoryViewModel(
            wordRepository: wordRepository,
            storyRepository: storyRepository
        ))
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
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
        .animation(.easeInOut(duration: 0.3), value: viewModel.viewState)
    }
}

#Preview {
    StoryView(
        wordRepository: WordRepository(dataManager: DataManager.shared),
        storyRepository: StoryRepository(dataManager: DataManager.shared)
    )
}
