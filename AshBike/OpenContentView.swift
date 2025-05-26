//
//  ContentView.swift
//  AshBike
//
//  Created by Siamak Ashrafi on 5/23/25.
//
import SwiftUI
import SwiftData

struct OpenContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [DataExampleItem]

    var body: some View {
        NavigationSplitView {
            // ┌───────────────────────────────────┐
            // │   PRIMARY COLUMN (sidebar)       │
            // └───────────────────────────────────┘
            List {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        Text(item.timestamp,
                             format: Date.FormatStyle(date: .numeric,
                                                      time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                // these buttons now live *only* in the sidebar
  #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
  #endif
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }

        } detail: {
            // ┌───────────────────────────────────┐
            // │   DETAIL COLUMN                  │
            // └───────────────────────────────────┘
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = DataExampleItem(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for idx in offsets {
                modelContext.delete(items[idx])
            }
        }
    }
}

#Preview {
    OpenContentView()
        .modelContainer(for: DataExampleItem.self, inMemory: true)
}


