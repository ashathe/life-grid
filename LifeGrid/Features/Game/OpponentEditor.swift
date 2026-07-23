import SwiftUI

struct OpponentEditor: View {
    @Bindable var store: AppStateStore
    let opponent: OpponentState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var partnerName: String

    init(store: AppStateStore, opponent: OpponentState) {
        self.store = store
        self.opponent = opponent
        _name = State(initialValue: opponent.displayName)
        _partnerName = State(initialValue: opponent.partner?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Opponent name", text: $name)
                }
                Section("Partner Commander") {
                    TextField("Partner name (optional)", text: $partnerName)
                }
            }
            .scrollContentBackground(.hidden)
            .background(LifeGridPalette.background)
            .preferredColorScheme(.dark)
            .navigationTitle("Edit Opponent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await store.renameOpponent(opponent.id, to: name)
                            await store.setOpponentPartnerName(opponent.id, name: partnerName)
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
