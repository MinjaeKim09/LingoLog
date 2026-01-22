//
//  ContentView.swift
//  LingoLog
//
//  Created by Minjae Kim on 6/18/25.
//

import SwiftUI

struct ContentView: View {
    let dataManager: DataManager
    let wordRepository: WordRepository
    let storyRepository: StoryRepository
    let userManager: UserManager
    let translationService: TranslationService
    
    var body: some View {
        TabView {
            DashboardView(
                wordRepository: wordRepository,
                dataManager: dataManager,
                userManager: userManager,
                translationService: translationService
            )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            WordListView(
                wordRepository: wordRepository,
                dataManager: dataManager,
                translationService: translationService
            )
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Words")
                }
            
            QuizView(
                wordRepository: wordRepository,
                dataManager: dataManager
            )
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Quiz")
                }
            
            StoryView(
                wordRepository: wordRepository,
                storyRepository: storyRepository
            )
                .tabItem {
                    Image(systemName: "book.pages.fill")
                    Text("Stories")
                }
            
            SettingsView(
                wordRepository: wordRepository,
                dataManager: dataManager,
                userManager: userManager
            )
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(Theme.Colors.accent)
    }
}

#Preview {
    ContentView(
        dataManager: DataManager.shared,
        wordRepository: WordRepository(dataManager: DataManager.shared),
        storyRepository: StoryRepository(dataManager: DataManager.shared),
        userManager: UserManager.shared,
        translationService: TranslationService.shared
    )
}
