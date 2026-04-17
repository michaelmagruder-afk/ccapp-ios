import Foundation
import Combine

class CCSession: ObservableObject, Identifiable {
    let id: String
    let sessionType: String

    @Published var messages: [Message]
    @Published var totalCost: Double
    @Published var turnCount: Int

    init(id: String, sessionType: String, messages: [Message] = [], totalCost: Double = 0, turnCount: Int = 0) {
        self.id = id
        self.sessionType = sessionType
        self.messages = messages
        self.totalCost = totalCost
        self.turnCount = turnCount
    }
}
