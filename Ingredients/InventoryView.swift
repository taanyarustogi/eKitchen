import SwiftUI

struct InventoryView: View {
    // list of ingredients
    @Binding var ingredients: [Ingredient]
    @State private var showAddIngredient: Bool = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    
    // get the starting inventory from home view
    @AppStorage("startingPantry") private var startingPantry: Data = Data()
    
    var body: some View {
        NavigationView {
            ZStack {
                // show a different view if there are no ingredients
                if ingredients.isEmpty {
                    VStack (spacing: 16) {
                        Image(systemName: "house")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray.opacity(0.4))
                        Text("Your pantry is empty!")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap + to add your first ingredient")
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 200)
                } else {
                    ScrollView {
                        LazyVStack (spacing: 16) {
                            // creates a ingredient card for every ingredient
                            ForEach(ingredients) {ingredient in
                                IngredientRow(
                                    ingredient: ingredient,
                                )
                                .contextMenu{
                                    // delete an ingredient by 3d holding it
                                    Button(role: .destructive) {
                                        if let idx = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                                            ingredients.remove(at: idx)
                                            // Sync with PantryManager
                                            syncWithPantryManager()
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }}
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Virtual Kitchen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // show the add ingredient view with the plus button
                    Button(action: {
                        showAddIngredient = true
                    }) {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showAddIngredient) {
                AddIngredientView(ingredients: $ingredients)
            }
        }
        .onAppear {
            loadIngredients()
        }
        .onChange(of: ingredients) { _ in
            // pantrymanager is the localised set of ingredients across the app
            syncWithPantryManager()
        }
    }
    
    private func loadIngredients() {
        // load the ingredients from the pantrymanager
        PantryManager.shared.loadIngredients()
        if !PantryManager.shared.ingredients.isEmpty {
            ingredients = PantryManager.shared.ingredients
            return
        }
        
        // if it's the user's first time, populate with selected ingredients
        if startingPantry != Data() {
            if let decoded = try? JSONDecoder().decode([Ingredient].self, from: startingPantry) {
                ingredients = decoded
                syncWithPantryManager()
                startingPantry = Data()
            }
        }
    }
    
    private func syncWithPantryManager() {
        // use this function to keep the pantry manager syncronized
        PantryManager.shared.ingredients = ingredients
        PantryManager.shared.saveIngredients()
    }
}
