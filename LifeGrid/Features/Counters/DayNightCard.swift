import SwiftUI

struct DayNightCard: View {
    @Bindable var store: AppStateStore

    private var currentState: DayNightState {
        store.state.activeGame?.dayNightState ?? .notSet
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("Day / Night")
                .font(.caption.bold())
                .foregroundStyle(LifeGridPalette.secondaryText)

            Text(currentState.displayString)
                .font(.subheadline.bold())
                .foregroundStyle(stateColor)
                .accessibilityLabel("Day/Night state")
                .accessibilityValue(currentState.displayString)

            Button {
                Task { await store.toggleDayNight() }
            } label: {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.subheadline)
                    .frame(width: 36, height: 36)
                    .background(LifeGridPalette.accent, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(toggleLabel)
            .accessibilityIdentifier("day-night-toggle")
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(LifeGridPalette.field, in: RoundedRectangle(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).stroke(LifeGridPalette.border) }
        .foregroundStyle(LifeGridPalette.primaryText)
    }

    private var stateColor: Color {
        switch currentState {
        case .notSet: return LifeGridPalette.secondaryText
        case .day: return Color(red: 0.95, green: 0.75, blue: 0.25)
        case .night: return Color(red: 0.35, green: 0.40, blue: 0.95)
        }
    }

    private var toggleLabel: String {
        switch currentState {
        case .notSet: return "Set Day"
        case .day: return "Set Night"
        case .night: return "Set Day"
        }
    }
}

extension DayNightState {
    var displayString: String {
        switch self {
        case .notSet: return "Not Set"
        case .day: return "Day"
        case .night: return "Night"
        }
    }
}
