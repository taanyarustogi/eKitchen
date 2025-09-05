import SwiftUI

// the class changes
class RecipeManager: ObservableObject {
    static let shared = RecipeManager()
    // list of IDs that are being made
    @Published var currentlyMakingRecipes: Set<UUID> = []
    // stores the recipes with their ID and info to show later
    private var recipeReferences: [UUID: Recipe] = [:]
    
    // add recipe if currently making is clicked
    func setRecipeAsCurrentlyMaking(_ recipe: Recipe) {
        currentlyMakingRecipes.insert(recipe.id)
        recipeReferences[recipe.id] = recipe
    }
    
    // remove if completed or cancel is clicked
    func setRecipeAsCompleted(_ recipeId: UUID) {
        currentlyMakingRecipes.remove(recipeId)
        recipeReferences.removeValue(forKey: recipeId)
    }
    
    func isRecipeCurrentlyMaking(_ recipeId: UUID) -> Bool {
        return currentlyMakingRecipes.contains(recipeId)
    }
    
    // returns all the currently making recipes
    func getCurrentlyMakingRecipes() -> [Recipe] {
        return currentlyMakingRecipes.compactMap { id in
            recipeReferences[id]
        }
    }
}
