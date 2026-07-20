import SwiftUI

struct SettingsScreen: View {
    @Bindable var store: AppStateStore
    @State private var input: StartingLifeInput

    init(store: AppStateStore) {
        self.store = store
        _input = State(initialValue: StartingLifeInput(
            value: store.state.preferences.defaultStartingLife
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Settings")
                            .font(.title2.bold())
                        Text("Saved locally on this device")
                            .font(.caption)
                            .foregroundStyle(LifeGridPalette.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Default Starting Life")
                            .font(.headline)
                        Text("Used for your next New Game")
                            .font(.caption)
                            .foregroundStyle(LifeGridPalette.secondaryText)
                        StartingLifePicker(input: $input)

                        if input.choice == .custom {
                            Button("Set Default") {
                                persistCurrentValue()
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                input.value == nil
                                    ? LifeGridPalette.control
                                    : LifeGridPalette.accent,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .disabled(input.value == nil)
                            .accessibilityIdentifier("set-default-life")
                        }
                    }
                    .lifeGridCard()
                    .accessibilityIdentifier("settings-default-life")
                }
                .frame(maxWidth: 560)
                .padding(16)
                .frame(maxWidth: .infinity)
            }
            .background(LifeGridPalette.background.ignoresSafeArea())
            .foregroundStyle(LifeGridPalette.primaryText)
            .onChange(of: input.choice) { _, choice in
                if case .preset = choice {
                    persistCurrentValue()
                }
            }
            .onChange(of: store.state.preferences.defaultStartingLife) { _, value in
                guard input.value != value else { return }
                input = StartingLifeInput(value: value)
            }
        }
    }

    private func persistCurrentValue() {
        guard let value = input.value else { return }
        Task { await store.setDefaultStartingLife(value) }
    }
}
