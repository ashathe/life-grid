import SwiftUI

@main
struct LifeGridApp: App {
    @State private var store = AppStateStore(environment: .live())

    var body: some Scene {
        WindowGroup {
            FoundationRootView()
                .task {
                    await store.load()
                }
        }
    }
}
