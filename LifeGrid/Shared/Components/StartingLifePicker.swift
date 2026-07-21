import SwiftUI

struct StartingLifePicker: View {
    @Binding var input: StartingLifeInput

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 3
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(StartingLifeInput.presets, id: \.self) { value in
                    choiceButton(
                        title: String(value),
                        choice: .preset(value),
                        identifier: "starting-life-\(value)"
                    )
                }
                choiceButton(
                    title: "Custom",
                    choice: .custom,
                    identifier: "starting-life-custom"
                )
            }

            if input.choice == .custom {
                TextField("Starting life", text: $input.customText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(
                        LifeGridPalette.field,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .accessibilityLabel("Custom starting life")
                    .accessibilityIdentifier("custom-starting-life")

                if let message = input.validationMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(LifeGridPalette.destructive)
                        .accessibilityIdentifier("custom-starting-life-error")
                }
            }
        }
    }

    private func choiceButton(
        title: String,
        choice: StartingLifeChoice,
        identifier: String
    ) -> some View {
        let selected = input.choice == choice
        return Button {
            input.choice = choice
        } label: {
            Text(title)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            selected ? LifeGridPalette.accent : LifeGridPalette.control,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? LifeGridPalette.accent : LifeGridPalette.border)
        }
        .foregroundStyle(LifeGridPalette.primaryText)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}
