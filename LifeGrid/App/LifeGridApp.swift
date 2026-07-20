import SwiftUI

@main
struct LifeGridApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = AppStateStore(environment: .live())

    var body: some Scene {
        WindowGroup {
            LifeGridRootView(store: store)
                .task {
                    await store.load()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase != .active else { return }
                    Task { await store.saveForLifecycle() }
                }
        }
    }
}
