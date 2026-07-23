import SwiftUI

struct SavedDieEditor: View {
    @Bindable var store: AppStateStore
    @Environment(\.dismiss) private var dismiss

    @State private var sidesText = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Number of sides (2–999)", text: $sidesText)
                    .keyboardType(.numberPad)

                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(LifeGridPalette.destructive)
                }
            }
            .scrollContentBackground(.hidden)
            .background(LifeGridPalette.background)
            .preferredColorScheme(.dark)
            .navigationTitle("Custom Die")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(sidesText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() async {
        guard let sides = Int(sidesText), (2...999).contains(sides) else {
            error = "Enter a whole number between 2 and 999."
            return
        }
        guard await store.addCustomDie(sides: sides) != nil else {
            error = "A d\(sides) already exists."
            return
        }
        dismiss()
    }
}
