import SwiftUI

struct CustomCounterEditor: View {
    enum Mode {
        case create
        case rename(id: UUID, currentName: String)
    }

    let mode: Mode
    @Bindable var store: AppStateStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var error: String?

    init(mode: Mode, store: AppStateStore) {
        self.mode = mode
        self.store = store
        switch mode {
        case .create:
            self._name = State(initialValue: "")
        case .rename(_, let currentName):
            self._name = State(initialValue: currentName)
        }
    }

    private var isEditing: Bool {
        if case .rename = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Counter name", text: $name)
                    .accessibilityIdentifier("custom-counter-name-field")

                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(LifeGridPalette.destructive)
                        .accessibilityLabel(error)
                }
            }
            .accessibilityIdentifier("custom-counter-editor")
            .navigationTitle(isEditing ? "Rename Counter" : "New Custom Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Rename" : "Create") {
                        Task { await save() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            error = "Name cannot be blank."
            return
        }

        switch mode {
        case .create:
            guard await store.addCustomCounter(name: trimmed) != nil else {
                error = "A counter with this name already exists."
                return
            }
        case .rename(let id, let currentName):
            if trimmed.caseInsensitiveCompare(currentName) == .orderedSame {
                dismiss()
                return
            }
            guard await store.renameCustomCounter(id, to: trimmed) else {
                error = "A counter with this name already exists."
                return
            }
        }

        dismiss()
    }
}
