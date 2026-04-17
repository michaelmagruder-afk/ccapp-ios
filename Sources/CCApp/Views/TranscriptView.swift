import SwiftUI

struct TranscriptView: View {
    let messages: [Message]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if messages.isEmpty {
                    VStack {
                        Spacer(minLength: 120)
                        Text("Start a conversation")
                            .foregroundColor(.gray)
                            .font(.body)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(hex: "#0f1923"))
    }
}

struct MessageBubble: View {
    let message: Message

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content.isEmpty && message.isStreaming ? "▋" : message.content)
                    .foregroundColor(.white)
                    .font(.body)
                    .multilineTextAlignment(isUser ? .trailing : .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isUser ? Color(hex: "#1B2B4B") : Color(hex: "#162233"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        isUser ? Color.clear :
                                            (message.isStreaming ? Color(hex: "#0E7C7B") : Color.gray.opacity(0.3)),
                                        lineWidth: message.isStreaming ? 1.5 : 0.5
                                    )
                            )
                    )

                if let cost = message.costUsd, cost > 0 {
                    Text("$\(String(format: "%.4f", cost))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
