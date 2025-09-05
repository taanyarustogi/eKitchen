import SwiftUI

@main
struct ekitchenApp: App {
    init() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
    }
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
