import SwiftUI

struct CustomCounterEditor: View {
    @Bindable var store: AppStateStore
    @Environment(\.dismiss) private var dismiss
    @State private var newCounterName = ""
    @State private var editingCounterID: UUID?
    @State private var editingName = ""
    @State private var showDeleteConfirmation = false
    @State private var deleteTarget: CustomCounterDefinition?

    var body: some View {
        NavigationStack {
            List {
                Section("Add") {
                    HStack {
                        TextField("Counter name", text: $newCounterName)
                            .textFieldStyle(.plain)
                        Button("Add") {
                            addCounter()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(LifeGridPalette.accent)
                        .frame(minHeight: 44)
                        .disabled(newCounterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Manage") {
                    if store.state.customCounters.isEmpty {
                        Text("No custom counters")
                            .font(.subheadline)
                            .foregroundStyle(LifeGridPalette.secondaryText)
                    } else {
                        ForEach(store.state.customCounters) { custom in
                            HStack {
                                if editingCounterID == custom.id {
                                    TextField("Name", text: $editingName)
                                        .textFieldStyle(.plain)
                                        .onSubmit { commitRename(custom) }
                                    Button("Save") { commitRename(custom) }
                                        .font(.subheadline)
                                        .foregroundStyle(LifeGridPalette.accent)
                                    Button("Cancel") { editingCounterID = nil }
                                        .font(.subheadline)
                                        .foregroundStyle(LifeGridPalette.secondaryText)
                                } else {
                                    Text(custom.name)
                                        .font(.body)
                                    Spacer()
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    confirmDelete(custom)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button("Rename") {
                                    startEditing(custom)
                                }
                                .tint(LifeGridPalette.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Custom Counters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .background(LifeGridPalette.background)
            .scrollContentBackground(.hidden)
            .alert("Delete Counter?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { executeDelete() }
            } message: {
                if let target = deleteTarget {
                    Text("Delete \"\(target.name)\"? This cannot be undone. Its value and pin will be removed from the active game.")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addCounter() {
        let name = newCounterName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        Task { await store.addCustomCounter(name: name) }
        newCounterName = ""
    }

    private func startEditing(_ custom: CustomCounterDefinition) {
        editingCounterID = custom.id
        editingName = custom.name
    }

    private func commitRename(_ custom: CustomCounterDefinition) {
        let name = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        Task { await store.renameCustomCounter(custom.id, to: name) }
        editingCounterID = nil
    }

    private func confirmDelete(_ custom: CustomCounterDefinition) {
        deleteTarget = custom
        showDeleteConfirmation = true
    }

    private func executeDelete() {
        guard let target = deleteTarget else { return }
        Task { await store.deleteCustomCounter(target.id) }
        deleteTarget = nil
    }
}
