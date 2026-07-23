import SwiftUI

struct CounterCard: View {
    @Bindable var store: AppStateStore
    let counterID: CounterID
    let value: Int
    let label: String
    let isDayNight: Bool
    let dayNightState: DayNightState
    let isPinned: Bool

    @State private var exactValueText = ""
    @State private var showsExactEntry = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(LifeGridPalette.secondaryText)
                    .accessibilityLabel(label)

                Spacer()

                if !isDayNight {
                    pinButton
                }
            }

            if isDayNight {
                dayNightControl
            } else {
                numericControl
            }

            helperText
        }
        .padding(12)
        .background(LifeGridPalette.field, in: RoundedRectangle(cornerRadius: 8))
        .alert("Set \(label)", isPresented: $showsExactEntry) {
            TextField("Value", text: $exactValueText)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Set") { submitExactValue() }
        }
    }

    // MARK: - Numeric control

    private var numericControl: some View {
        HStack(spacing: 0) {
            Button {
                Task { await store.changeCounterValue(counterID, by: -1) }
            } label: {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, minHeight: 48)
            .overlay(
                Image(systemName: "minus")
                    .font(.title3)
            )
            .accessibilityLabel("Remove one \(label) counter")

            Button {
                showsExactEntry = true
                exactValueText = String(value)
            } label: {
                Text("\(value)")
                    .font(.title.bold())
                    .monospacedDigit()
                    .padding(.horizontal, 12)
                    .frame(minWidth: 44, minHeight: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label): \(value)")
            .accessibilityHint("Tap to enter exact value")

            Button {
                Task { await store.changeCounterValue(counterID, by: 1) }
            } label: {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, minHeight: 48)
            .overlay(
                Image(systemName: "plus")
                    .font(.title3)
            )
            .accessibilityLabel("Add one \(label) counter")
        }
    }

    // MARK: - Day/Night

    private var dayNightControl: some View {
        Button {
            Task { await store.toggleDayNight() }
        } label: {
            HStack {
                Image(systemName: dayNightIcon)
                Text(dayNightLabel)
                    .font(.title3.bold())
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.bordered)
        .tint(dayNightColor)
        .accessibilityLabel("Day/Night: \(dayNightLabel)")
        .accessibilityHint("Tap to cycle state")
    }

    private var dayNightIcon: String {
        switch dayNightState {
        case .notSet: return "circle"
        case .day: return "sun.max.fill"
        case .night: return "moon.fill"
        }
    }

    private var dayNightLabel: String {
        switch dayNightState {
        case .notSet: return "Not Set"
        case .day: return "Day"
        case .night: return "Night"
        }
    }

    private var dayNightColor: Color {
        switch dayNightState {
        case .notSet: return LifeGridPalette.control
        case .day: return .orange
        case .night: return .indigo
        }
    }

    // MARK: - Pin

    private var pinButton: some View {
        Button {
            Task {
                if isPinned {
                    await store.unpinCounter(counterID)
                } else {
                    await store.pinCounter(counterID)
                }
            }
        } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.caption)
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(isPinned ? "Unpin \(label)" : "Pin \(label)")
        .disabled(!isPinned && (store.state.activeGame?.pinnedCounterIDs.count ?? 0) >= 4)
    }

    // MARK: - Helper text

    private var helperText: some View {
        Text("Tap ±1 · Hold to repeat · Tap value to set")
            .font(.caption2)
            .foregroundStyle(LifeGridPalette.secondaryText.opacity(0.7))
    }

    // MARK: - Exact entry

    private func submitExactValue() {
        guard let intValue = Int(exactValueText), intValue >= 0 else { return }
        Task { await store.setCounterValue(counterID, to: intValue) }
    }
}
