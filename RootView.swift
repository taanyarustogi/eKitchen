import SwiftUI

struct RootView: View {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    
    // shows the main tab if app's been opened before, otherwise home view
    var body: some View {
        if hasLaunchedBefore {
            MainTabView()
        } else {
            HomeScreenView()
        }
    }
}
