import SwiftUI

struct SourceSelectionView: View {
    @ObservedObject var settings: Settings
    @Binding var showWelcome: Bool
    @State private var selectedSources: Set<String>
    @State private var showCategorySelection = false
    @State private var currentSourceIndex = 0
    
    init(settings: Settings, showWelcome: Binding<Bool>) {
        self._settings = ObservedObject(wrappedValue: settings)
        self._showWelcome = showWelcome
        self._selectedSources = State(initialValue: Set<String>())
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
                    
                    ForEach(NewsSource.available) { source in
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
                        settings.selectedSources = selectedSources
                        settings.selectedCategories.removeAll()
                        currentSourceIndex = 0
                        showCategorySelection = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedSources.isEmpty)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Quellen")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showCategorySelection) {
            if let sourceId = Array(selectedSources)[safe: currentSourceIndex] {
                let source = NewsSource.available.first(where: { $0.id == sourceId })!
                NavigationView {
                    WelcomeView(
                        settings: settings,
                        showWelcome: $showWelcome,
                        sourceId: sourceId,
                        onCompletion: {
                            currentSourceIndex += 1
                            if currentSourceIndex >= selectedSources.count {
                                settings.isFirstLaunch = false
                                showWelcome = false
                            }
                        }
                    )
                    .navigationTitle(source.name)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
} 