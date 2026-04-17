import SwiftUI

struct SessionView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var currentSessionType = "cc_session"
    @State private var currentSessionId: String? = nil
    @State private var messages: [Message] = []
    @State private var sessionCost: Double = 0
    @State private var isStreaming: Bool = false
    @State private var inputText: String = ""
    @State private var lastModel: String = ""
    @State private var showSettings = false
    @StateObject private var speechService = SpeechService()

    var body: some View {
        Group {
            if sizeClass == .regular {
                NavigationSplitView {
                    sidebar
                } detail: {
                    detailPane
                }
            } else {
                VStack(spacing: 0) {
                    detailPane
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(env)
        }
    }

    private var sidebar: some View {
        SessionTypePicker(selectedType: $currentSessionType)
            .navigationTitle("CC Session")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
    }

    private var detailPane: some View {
        VStack(spacing: 0) {
            topBar

            TranscriptView(messages: messages)

            if speechService.isRecording && !speechService.transcript.isEmpty {
                Text(speechService.transcript)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#162233"))
            }

            inputBar
        }
        .background(Color(hex: "#0f1923"))
    }

    private var topBar: some View {
        HStack {
            Text("Customer Core")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            if !lastModel.isEmpty {
                Text(lastModel)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Text("$\(String(format: "%.4f", sessionCost))")
                .font(.caption)
                .foregroundColor(Color(hex: "#0E7C7B"))

            if let sid = currentSessionId {
                Text(String(sid.prefix(8)))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if sizeClass != .regular {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#162233"))
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            VoiceButton(
                isRecording: $speechService.isRecording,
                onSend: { text in
                    inputText = text
                    sendMessage()
                },
                startRecording: { try await speechService.startRecording() },
                stopRecording: { speechService.stopRecording() }
            )

            TextField("Message...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Color(hex: "#162233"))
                .cornerRadius(10)
                .foregroundColor(.white)
                .disabled(isStreaming || speechService.isRecording)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(isStreaming || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? .gray
                        : Color(hex: "#0E7C7B"))
            }
            .disabled(isStreaming || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#0f1923"))
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }

        inputText = ""
        isStreaming = true

        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)

        let assistantMessage = Message(role: .assistant, content: "", isStreaming: true)
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1

        Task {
            let stream = GatewayService.shared.send(
                message: text,
                sessionType: currentSessionType,
                sessionId: currentSessionId,
                token: env.ccToken,
                baseURL: env.gatewayURL
            )

            for await event in stream {
                await MainActor.run {
                    switch event {
                    case .token(let content):
                        messages[assistantIndex].content += content

                    case .done(let sid, let cost, _, _, let model):
                        messages[assistantIndex].isStreaming = false
                        messages[assistantIndex].costUsd = cost
                        messages[assistantIndex].model = model
                        currentSessionId = sid
                        sessionCost += cost
                        lastModel = model
                        isStreaming = false

                    case .error(let errMsg):
                        messages[assistantIndex].content = "Error: \(errMsg)"
                        messages[assistantIndex].isStreaming = false
                        isStreaming = false
                    }
                }
            }

            await MainActor.run {
                isStreaming = false
            }
        }
    }
}
