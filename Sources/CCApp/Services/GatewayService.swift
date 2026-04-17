import Foundation

enum GatewayEvent {
    case token(String)
    case done(sessionId: String, costUsd: Double, inputTokens: Int, outputTokens: Int, model: String)
    case error(String)
}

class GatewayService {
    static let shared = GatewayService()

    private init() {}

    func send(
        message: String,
        sessionType: String,
        sessionId: String?,
        token: String,
        baseURL: String
    ) -> AsyncStream<GatewayEvent> {
        AsyncStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(baseURL)/chat") else {
                        continuation.yield(.error("Invalid gateway URL"))
                        continuation.finish()
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(token, forHTTPHeaderField: "X-CC-Token")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let body: [String: Any?] = [
                        "session_id": sessionId,
                        "session_type": sessionType,
                        "message": message
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        continuation.yield(.error("HTTP error from gateway"))
                        continuation.finish()
                        return
                    }

                    var lineBuffer = ""

                    for try await byte in asyncBytes {
                        let char = Character(UnicodeScalar(byte))
                        if char == "\n" {
                            let line = lineBuffer
                            lineBuffer = ""

                            if line.isEmpty || line.hasPrefix(": keep-alive") {
                                continue
                            }

                            if line.hasPrefix("data: ") {
                                let jsonString = String(line.dropFirst(6))

                                guard let data = jsonString.data(using: .utf8),
                                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                      let type = json["type"] as? String else {
                                    continue
                                }

                                switch type {
                                case "token":
                                    if let content = json["content"] as? String {
                                        continuation.yield(.token(content))
                                    }
                                case "done":
                                    let sid = json["session_id"] as? String ?? ""
                                    let cost = json["cost_usd"] as? Double ?? 0
                                    let inputTok = json["input_tokens"] as? Int ?? 0
                                    let outputTok = json["output_tokens"] as? Int ?? 0
                                    let model = json["model"] as? String ?? ""
                                    continuation.yield(.done(
                                        sessionId: sid,
                                        costUsd: cost,
                                        inputTokens: inputTok,
                                        outputTokens: outputTok,
                                        model: model
                                    ))
                                    continuation.finish()
                                    return
                                default:
                                    break
                                }
                            }
                        } else {
                            lineBuffer.append(char)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.yield(.error(error.localizedDescription))
                    continuation.finish()
                }
            }
        }
    }
}
