import SwiftUI

struct SessionTypeOption {
    let type: String
    let displayName: String
    let subtitle: String
    let icon: String
}

private let sessionTypeOptions: [SessionTypeOption] = [
    SessionTypeOption(type: "quick_chat",        displayName: "Quick Chat",        subtitle: "Fast questions, Haiku model",         icon: "bolt.fill"),
    SessionTypeOption(type: "cc_session",        displayName: "CC Session",        subtitle: "Core CC methodology work",            icon: "brain.head.profile"),
    SessionTypeOption(type: "dpr_standard",      displayName: "DPR Standard",      subtitle: "Deep pass review",                    icon: "magnifyingglass.circle.fill"),
    SessionTypeOption(type: "dpr_adversarial",   displayName: "DPR Adversarial",   subtitle: "Hard critique, Opus model",           icon: "shield.lefthalf.filled"),
    SessionTypeOption(type: "research_sweep",    displayName: "Research Sweep",    subtitle: "Source synthesis",                    icon: "doc.text.magnifyingglass"),
    SessionTypeOption(type: "governance_ruling", displayName: "Governance",        subtitle: "Formal CC rulings",                   icon: "checkmark.seal.fill"),
]

struct SessionTypePicker: View {
    @Binding var selectedType: String

    var body: some View {
        List(sessionTypeOptions, id: \.type, selection: .constant(selectedType)) { option in
            Button(action: { selectedType = option.type }) {
                HStack(spacing: 12) {
                    Image(systemName: option.icon)
                        .foregroundColor(selectedType == option.type ? Color(hex: "#0E7C7B") : .gray)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.displayName)
                            .font(.body)
                            .foregroundColor(.white)
                            .fontWeight(selectedType == option.type ? .semibold : .regular)

                        Text(option.subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    if selectedType == option.type {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color(hex: "#0E7C7B"))
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(
                selectedType == option.type
                    ? Color(hex: "#1B2B4B").opacity(0.6)
                    : Color.clear
            )
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color(hex: "#0f1923"))
        .navigationTitle("Session Type")
    }
}
