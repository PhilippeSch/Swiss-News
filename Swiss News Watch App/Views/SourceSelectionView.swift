import SwiftUI

struct SourceSelectionView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var rssParser: RSSFeedParser
    @Binding var showWelcome: Bool
    @State private var selectedSources: Set<String>
    @State private var showCategorySelection = false
    @State private var currentSourceIndex = 0
    @State private var showAlert = false
    
    init(settings: Settings, rssParser: RSSFeedParser, showWelcome: Binding<Bool>) {
        self._settings = ObservedObject(wrappedValue: settings)
        self._rssParser = ObservedObject(wrappedValue: rssParser)
        self._showWelcome = showWelcome
        self._selectedSources = State(initialValue: settings.selectedSources)
        self._currentSourceIndex = State(initialValue: 0)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Willkommen bei Swiss News 👋")
                        .font(.title2)
                        .padding(.top)
                    
                    Text("Wähle deine bevorzugten Nachrichtenquellen:")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    
                    ForEach(NewsSource.available.sorted(by: { $0.order < $1.order })) { source in
                        HStack {
                            Image(source.logoName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 20)
                            
                            Text(source.name)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { selectedSources.contains(source.id) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedSources.insert(source.id)
                                    } else {
                                        selectedSources.remove(source.id)
                                    }
                                }
                            ))
                        }
                        .padding(.vertical, 5)
                    }
                    
                    Button("Weiter") {
                        handleSourceSelection()
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedSources.isEmpty)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Quellen")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Keine Quelle ausgewählt", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Bitte wähle mindestens eine Nachrichtenquelle aus.")
            }
        }
        .sheet(isPresented: $showCategorySelection) {
            if let sourceId = Array(selectedSources)[safe: currentSourceIndex] {
                let source = NewsSource.available.first(where: { $0.id == sourceId })!
                NavigationView {
                    WelcomeView(
                        settings: settings,
                        rssParser: rssParser,
                        showWelcome: $showWelcome,
                        sourceId: sourceId,
                        onCompletion: {
                            currentSourceIndex += 1
                            if currentSourceIndex >= selectedSources.count {
                                handleCompletion()
                            }
                        }
                    )
                    .navigationTitle(source.name)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    private func moveToNextSource() {
        settings.selectedSources = selectedSources
        currentSourceIndex = 0
        showCategorySelection = true
    }
    
    private func handleSourceSelection() {
        if selectedSources.isEmpty {
            showAlert = true
        } else {
            moveToNextSource()
        }
    }
    
    private func handleCompletion() {
        settings.isFirstLaunch = false
        showWelcome = false
        Task {
            await rssParser.fetchAllFeeds()
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
} 