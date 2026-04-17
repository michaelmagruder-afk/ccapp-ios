import Foundation
import Combine

class AppEnvironment: ObservableObject {
    @Published var gatewayURL: String {
        didSet { UserDefaults.standard.set(gatewayURL, forKey: "gatewayURL") }
    }

    @Published var ccToken: String {
        didSet { UserDefaults.standard.set(ccToken, forKey: "ccToken") }
    }

    init() {
        self.gatewayURL = UserDefaults.standard.string(forKey: "gatewayURL")
            ?? "http://204.168.190.66:8001"
        self.ccToken = UserDefaults.standard.string(forKey: "ccToken")
            ?? "a38662c6-a32e-48e4-82ad-047bbb64cb29"
    }
}
