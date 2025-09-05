import SwiftUI

// creates a tab at the bottom to switch between ingredients and recipes
struct MainTabView: View {
    @State private var ingredients: [Ingredient] = []
    
    var body: some View {
        TabView {
            InventoryView(ingredients: $ingredients)
                .tabItem {
                    Image(systemName: "house")
                    Text("Inventory")
                }
            
// pass the ingredients list to the recipe
            RecipeView(ingredients: ingredients)
                .tabItem {
                    Image(systemName: "book")
                    Text("Recipes")
                }
            ShoppingListView()
                    .tabItem {
                        Image(systemName: "cart")
                        Text("Shopping")
                    }
        }
    }
}
