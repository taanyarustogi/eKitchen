import SwiftUI

struct ShoppingListView: View {
    @StateObject private var pantryManager = PantryManager.shared
    @State private var showAddItem: Bool = false
    
    // checks weather to show the delete and add button
    private var hasCompletedItems: Bool {
        pantryManager.shoppingList.contains { $0.isCompleted }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // show a different view if there are no items
                if pantryManager.shoppingList.isEmpty {
                    VStack (spacing: 16) {
                        Image(systemName: "cart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray.opacity(0.4))
                        Text("Your shopping list is empty!")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Items will be added automatically when your pantry runs out")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 200)
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVStack (spacing: 16) {
                                // creates a shopping item row for every item
                                ForEach(pantryManager.shoppingList, id: \.id) { item in
                                    ShoppingListRow(item: item, pantryManager: pantryManager)
                                        .contextMenu {
                                            // delete an item by 3d holding it
                                            Button(role: .destructive) {
                                                pantryManager.removeFromShoppingList(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding()
                        }
                        
                        // delete and add button
                        if hasCompletedItems {
                            Button(action: {
                                deleteAndAddToInventory()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Delete & Add to Pantry")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .padding()
                            .transition(.slide)
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // show the add item view with the plus button
                    Button(action: {
                        showAddItem = true
                    }) {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddShoppingItemView()
            }
        }
        .onAppear {
            pantryManager.loadIngredients()
        }
    }
    
    private func deleteAndAddToInventory() {
        let completedItems = pantryManager.shoppingList.filter { $0.isCompleted }
        
        // add the ticked items to the pantry
        for item in completedItems {
            pantryManager.addToPantry(name: item.name, quantity: item.quantity, unit: item.unit)
        }
        
        // remove the ticked items from the shopping list
        for item in completedItems {
            pantryManager.removeFromShoppingList(item)
        }
    }
}
