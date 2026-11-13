import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.unitKey) private var unit: WeightUnit = .localeDefault
    @AppStorage(AppSettings.restKey) private var restSeconds = AppSettings.defaultRest

    private let restOptions = [30, 45, 60, 90, 120, 150, 180, 240, 300]

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Weight", selection: $unit) {
                        ForEach(WeightUnit.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Picker("Rest timer", selection: $restSeconds) {
                        ForEach(restOptions, id: \.self) { seconds in
                            Text(formatDuration(TimeInterval(seconds))).tag(seconds)
                        }
                    }
                } footer: {
                    Text("The rest timer starts when you check off a set.")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}
