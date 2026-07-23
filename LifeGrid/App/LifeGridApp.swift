import SwiftUI

@main
struct LifeGridApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = AppStateStore(environment: .live())

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(
            red: 0.035, green: 0.03, blue: 0.05, alpha: 1.0
        )
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        UITextField.appearance().attributedPlaceholder = NSAttributedString(
            string: "",
            attributes: [.foregroundColor: UIColor(red: 0.63, green: 0.60, blue: 0.69, alpha: 0.6)]
        )
    }

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
