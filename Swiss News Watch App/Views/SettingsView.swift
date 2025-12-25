import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var rssParser: RSSFeedParser
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            timeFilterSection
            versionSection
        }
        .navigationTitle("Einstellungen")
        .onAppear {
            rssParser.setSettingsViewActive(true)
            settings.beginSettingsSession()
        }
        .onDisappear {
            if !rssParser.isSettingsViewActive {  // Only commit if actually dismissing
                settings.commitSettingsChanges()
            }
        }
    }
    
    private var timeFilterSection: some View {
        Section(header: Text("Artikel Filter")) {
            Picker("Zeitraum", selection: $settings.cutoffHours) {
                Text("Keine Limite").tag(0.0)
                Text("24 Stunden").tag(24.0)
                Text("48 Stunden").tag(48.0)
                Text("72 Stunden").tag(72.0)
            }
            .accessibilityIdentifier("timeFilterPicker")
        }
    }
    
    private var versionSection: some View {
        Section {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
            
            Text("Version \(version) (\(build))")
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
} 
