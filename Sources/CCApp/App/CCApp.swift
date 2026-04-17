import SwiftUI

@main
struct CCApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            SessionView()
                .environmentObject(environment)
        }
    }
}
