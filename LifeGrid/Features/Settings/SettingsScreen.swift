import SwiftUI

struct SettingsScreen: View {
    @Bindable var store: AppStateStore
    @State private var input: StartingLifeInput
    @State private var playerName: String
    @State private var commanderEnabled: Bool
    @State private var damageLinkEnabled: Bool
    @State private var screenAwake: Bool
    @State private var haptics: Bool
    @State private var sound: Bool

    init(store: AppStateStore) {
        self.store = store
        let prefs = store.state.preferences
        _input = State(initialValue: StartingLifeInput(value: prefs.defaultStartingLife))
        _playerName = State(initialValue: prefs.playerName)
        _commanderEnabled = State(initialValue: prefs.commanderEnabled)
        _damageLinkEnabled = State(initialValue: prefs.commanderDamageChangesLife)
        _screenAwake = State(initialValue: prefs.keepScreenAwakeDuringGames)
        _haptics = State(initialValue: prefs.hapticsEnabled)
        _sound = State(initialValue: prefs.soundEffectsEnabled)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    playerSection
                    startingLifeSection
                    commanderSection
                    displaySection
                    feedbackSection
                    legalSection
                }
                .frame(maxWidth: 560)
                .padding(12)
                .frame(maxWidth: .infinity)
            }
            .background(LifeGridPalette.background.ignoresSafeArea())
            .foregroundStyle(LifeGridPalette.primaryText)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: input.choice) { _, choice in
                if case .preset = choice { persistCurrentValue() }
            }
            .onChange(of: store.state.preferences.defaultStartingLife) { _, value in
                guard input.value != value else { return }
                input = StartingLifeInput(value: value)
            }
        }
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Player").font(.headline)
            TextField("Your name", text: $playerName, prompt: Text("You").foregroundStyle(LifeGridPalette.secondaryText))
                .foregroundStyle(LifeGridPalette.primaryText)
                .padding(10)
                .background(LifeGridPalette.field, in: RoundedRectangle(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).stroke(LifeGridPalette.border) }
                .onSubmit { persistPlayerName() }
        }
        .lifeGridCard()
    }

    private var startingLifeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Default Starting Life").font(.headline)
            Text("Used for your next New Game").font(.caption).foregroundStyle(LifeGridPalette.secondaryText)
            StartingLifePicker(input: $input)
            if input.choice == .custom {
                Button("Set Default") { persistCurrentValue() }
                    .font(.subheadline).frame(maxWidth: .infinity, minHeight: 40)
                    .background(input.value == nil ? LifeGridPalette.control : LifeGridPalette.accent, in: RoundedRectangle(cornerRadius: 8))
                    .disabled(input.value == nil)
            }
        }
        .lifeGridCard()
    }

    private var commanderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gameplay").font(.headline)
            Toggle("Commander", isOn: $commanderEnabled)
                .tint(LifeGridPalette.accent)
                .onChange(of: commanderEnabled) { _, v in Task { await store.setCommanderEnabled(v) } }
            if commanderEnabled {
                Divider().overlay(LifeGridPalette.border)
                Toggle("Commander Damage Changes Life", isOn: $damageLinkEnabled)
                    .tint(LifeGridPalette.accent)
                    .onChange(of: damageLinkEnabled) { _, v in Task { await store.setCommanderDamageLink(v) } }
            }
        }
        .lifeGridCard()
    }

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display").font(.headline)
            Toggle("Keep Screen Awake During Games", isOn: $screenAwake)
                .tint(LifeGridPalette.accent)
                .onChange(of: screenAwake) { _, v in Task { await store.setKeepScreenAwake(v) } }
        }
        .lifeGridCard()
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Feedback").font(.headline)
            Toggle("Haptics", isOn: $haptics)
                .tint(LifeGridPalette.accent)
                .onChange(of: haptics) { _, v in Task { await store.setHapticsEnabled(v) } }
            Divider().overlay(LifeGridPalette.border)
            Toggle("Sound Effects", isOn: $sound)
                .tint(LifeGridPalette.accent)
                .onChange(of: sound) { _, v in Task { await store.setSoundEffectsEnabled(v) } }
        }
        .lifeGridCard()
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            Link(destination: URL(string: "https://ashathe.github.io/life-grid/")!) {
                HStack {
                    Text("Terms of Service & Privacy Policy")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                }
                .foregroundStyle(LifeGridPalette.secondaryText)
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 4)
    }

    private func persistCurrentValue() {
        guard let value = input.value else { return }
        Task { await store.setDefaultStartingLife(value) }
    }

    private func persistPlayerName() {
        Task { await store.setPlayerName(playerName) }
    }
}
