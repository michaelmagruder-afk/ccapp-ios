import SwiftUI

struct VoiceButton: View {
    @Binding var isRecording: Bool
    let onSend: (String) -> Void
    let startRecording: () async throws -> Void
    let stopRecording: () -> String

    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(isRecording ? Color.red : Color(hex: "#0E7C7B"))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                )
                .scaleEffect(scale)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard !isRecording else { return }
                            Task {
                                try? await startRecording()
                            }
                        }
                        .onEnded { _ in
                            guard isRecording else { return }
                            let text = stopRecording()
                            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                onSend(trimmed)
                            }
                        }
                )
                .onChange(of: isRecording) { _, recording in
                    if recording {
                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                            scale = 1.15
                        }
                    } else {
                        withAnimation(.default) {
                            scale = 1.0
                        }
                    }
                }

            Text(isRecording ? "Listening..." : "Hold to speak")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
