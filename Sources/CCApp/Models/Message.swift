import Foundation

enum MessageRole {
    case user
    case assistant
}

struct Message: Identifiable {
    let id: UUID
    var role: MessageRole
    var content: String
    var isStreaming: Bool
    var costUsd: Double? = nil
    var model: String? = nil

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        isStreaming: Bool = false,
        costUsd: Double? = nil,
        model: String? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.isStreaming = isStreaming
        self.costUsd = costUsd
        self.model = model
    }
}
