import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    
    private var versionInfo: String {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        return "Build \(build)"
    }
    
    var body: some View {
        Form {
            Section(header: Text("Artikel Filter")) {
                Picker("Zeitraum", selection: $settings.cutoffHours) {
                    Text("Keine Limite").tag(0.0)
                    Text("24 Stunden").tag(24.0)
                    Text("48 Stunden").tag(48.0)
                    Text("72 Stunden").tag(72.0)
                }
            }
            
            Section {
                Text(versionInfo)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Einstellungen")
    }
} 
