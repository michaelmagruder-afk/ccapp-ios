import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var gatewayURL: String = ""
    @State private var ccToken: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    LabeledContent("Gateway URL") {
                        TextField("http://...", text: $gatewayURL)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
#if os(iOS)
                            .textInputAutocapitalization(.never)
#endif
                    }

                    LabeledContent("CC Token") {
                        TextField("Token", text: $ccToken)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
#if os(iOS)
                            .textInputAutocapitalization(.never)
#endif
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "0.1")
                    LabeledContent("Build", value: "Phase 3a")
                    LabeledContent("Gateway", value: env.gatewayURL)
                }

                Section {
                    Button("Save") {
                        env.gatewayURL = gatewayURL
                        env.ccToken = ccToken
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(hex: "#0E7C7B"))
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                gatewayURL = env.gatewayURL
                ccToken = env.ccToken
            }
        }
    }
}
