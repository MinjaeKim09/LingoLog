import SwiftUI

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    let dataManager: DataManager
    let translationService: TranslationService
    @StateObject private var viewModel: AddWordViewModel
    
    @State private var showingSourcePicker = false
    @State private var showingTargetPicker = false
    
    // Add state for animation
    @State private var isSwapped = false
    
    init(dataManager: DataManager, translationService: TranslationService) {
        self.dataManager = dataManager
        self.translationService = translationService
        _viewModel = StateObject(
            wrappedValue: AddWordViewModel(
                dataManager: dataManager,
                translationService: translationService
            )
        )
    }
    
    private func swapLanguages() {
        viewModel.swapLanguages()
        isSwapped.toggle()
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Input Section
                        VStack(alignment: .leading, spacing: 12) {
                            Theme.Typography.title("Word or Phrase")
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            TextField("Type or paste here", text: $viewModel.inputText)
                                .padding()
                                .background(Theme.Colors.inputBackground)
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.Colors.divider, lineWidth: 1)
                                )
                        }
                        .padding()
                        .glassCard()
                        
                        // Languages Section
                        HStack(alignment: .bottom, spacing: 12) {
                            // Translate From
                            VStack(alignment: .leading, spacing: 8) {
                                Theme.Typography.body("From")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                Button(action: { showingSourcePicker = true }) {
                                    HStack {
                                        Text(viewModel.languageName(for: viewModel.sourceLanguage))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(Theme.Colors.textSecondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.Colors.inputBackground)
                                    .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Swap Button
                            Button(action: swapLanguages) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .foregroundColor(Theme.Colors.accent)
                                    .padding(8)
                                    .background(Theme.Colors.accent.opacity(0.1))
                                    .clipShape(Circle())
                                    .rotationEffect(.degrees(isSwapped ? 180 : 0))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSwapped)
                            }
                            .padding(.bottom, 6)
                            
                            // Translate To
                            VStack(alignment: .leading, spacing: 8) {
                                Theme.Typography.body("To")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                Button(action: { showingTargetPicker = true }) {
                                    HStack {
                                        Text(viewModel.languageName(for: viewModel.targetLanguage))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(Theme.Colors.textSecondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.Colors.inputBackground)
                                    .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .glassCard()
                        
                        // Status & Result
                        if viewModel.isTranslating && viewModel.translation == nil {
                            HStack(spacing: 12) {
                                ProgressView()
                                Theme.Typography.body("Translating...")
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .glassCard()
                        }
                        
                        if let translated = viewModel.translation, !translated.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Theme.Typography.title("Translation")
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    
                                    if viewModel.isTranslating {
                                        Spacer()
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                                
                                Text(translated)
                                    .font(.system(.title3, design: .serif))
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Theme.Colors.accent.opacity(0.1))
                                    .cornerRadius(12)
                                    .contentTransition(.opacity)
                            }
                            .padding()
                            .glassCard()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(Theme.Colors.error)
                                .font(.caption)
                                .padding()
                                .glassCard()
                        }
                        
                        // Context Section
                        VStack(alignment: .leading, spacing: 12) {
                            Theme.Typography.title("Context (Optional)")
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            TextField("Where did you see this? (e.g., K-drama)", text: $viewModel.context)
                                .padding()
                                .background(Theme.Colors.inputBackground)
                                .cornerRadius(12)
                                .font(.system(.body, design: .rounded))
                                .autocapitalization(.sentences)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.Colors.divider, lineWidth: 1)
                                )
                        }
                        .padding()
                        .glassCard()
                    }
                    .padding()
                }

                .navigationTitle("Add New Word")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.saveTranslation()
                            dismiss()
                        } label: {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                        .disabled(viewModel.translation == nil || viewModel.translation?.isEmpty == true)
                        .foregroundStyle(viewModel.translation == nil || viewModel.translation?.isEmpty == true ? Color.gray : Theme.Colors.accent)
                    }
                }
            }
            .navigationViewStyle(.stack)
            .sheet(isPresented: $showingSourcePicker) {
                LanguagePickerView(
                    selectedLanguage: $viewModel.sourceLanguage,
                    title: "Translate From",
                    languages: viewModel.allLanguages
                )
            }
            .sheet(isPresented: $showingTargetPicker) {
                LanguagePickerView(
                    selectedLanguage: $viewModel.targetLanguage,
                    title: "Translate To",
                    languages: viewModel.allLanguages
                )
            }
            .task {
                await viewModel.loadLanguages()
            }
        }

    }
    
}

#Preview {
    AddWordView(
        dataManager: DataManager.shared,
        translationService: TranslationService.shared
    )
} 
