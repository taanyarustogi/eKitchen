import Foundation
import Combine

class PantryManager: ObservableObject {
    static let shared = PantryManager()
    
    // automatically updates when ingredients or shoppingList changes
    @Published var ingredients: [Ingredient] = []
    @Published var shoppingList: [ShoppingList] = []
    
    // loads from user defaults
    func loadIngredients() {
        if let data = UserDefaults.standard.data(forKey: "pantryIngredients"),
           let decoded = try? JSONDecoder().decode([Ingredient].self, from: data) {
            ingredients = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "shoppingList"),
           let decoded = try? JSONDecoder().decode([ShoppingList].self, from: data) {
            shoppingList = decoded
        }
    }
    
    // saves to user defaults
    func saveIngredients() {
        if let encoded = try? JSONEncoder().encode(ingredients) {
            UserDefaults.standard.set(encoded, forKey: "pantryIngredients")
        }
        
        if let encoded = try? JSONEncoder().encode(shoppingList) {
            UserDefaults.standard.set(encoded, forKey: "shoppingList")
        }
    }
    
    // used after clicking completed on recipes - parses and removes ingredients from pantry
    func consumeIngredients(from recipe: Recipe) {
        for recipeIngredient in recipe.ingredients {
            let (quantity, itemName) = parseIngredient(recipeIngredient)
            removeFromPantry(itemName: itemName, quantity: quantity)
        }
        saveIngredients()
    }
    
    // if it already exists - add more quantity, otherwise add new item
    func addToShoppingList(name: String, quantity: Double, unit: String) {
        if let index = shoppingList.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            shoppingList[index].quantity += quantity
        } else {
            let newItem = ShoppingList(
                id: UUID(),
                name: name,
                quantity: quantity,
                unit: unit,
                isCompleted: false
            )
            shoppingList.append(newItem)
        }
        saveIngredients()
    }
    
    // deletes an item from the list
    func removeFromShoppingList(_ item: ShoppingList) {
        shoppingList.removeAll { $0.id == item.id }
        saveIngredients()
    }
    
    // ticks an item on the list
    func toggleShoppingList(_ item: ShoppingList) {
        if let index = shoppingList.firstIndex(where: { $0.id == item.id }) {
            shoppingList[index].isCompleted.toggle()
            saveIngredients()
        }
    }
    
    // parses from the recipe - to see what to remove from pantry
    private func parseIngredient(_ ingredient: String) -> (quantity: Double, item: String) {
        let components = ingredient.components(separatedBy: " ")
        
        for i in 0..<min(3, components.count) {
            let component = components[i]
            
            if component.contains("/") {
                let fractionParts = component.components(separatedBy: "/")
                if fractionParts.count == 2,
                   let numerator = Double(fractionParts[0]),
                   let denominator = Double(fractionParts[1]),
                   denominator != 0 {
                    let item = components.dropFirst(i + 1).joined(separator: " ")
                    return (numerator / denominator, item)
                }
            }
            
            if let quantity = Double(component) {
                let item = components.dropFirst(i + 1).joined(separator: " ")
                return (quantity, item)
            }
            
            if i < components.count - 1 {
                let nextComponent = components[i + 1]
                if let wholeNumber = Double(component),
                   nextComponent.contains("/") {
                    let fractionParts = nextComponent.components(separatedBy: "/")
                    if fractionParts.count == 2,
                       let numerator = Double(fractionParts[0]),
                       let denominator = Double(fractionParts[1]),
                       denominator != 0 {
                        let item = components.dropFirst(i + 2).joined(separator: " ")
                        return (wholeNumber + (numerator / denominator), item)
                    }
                }
            }
        }
        
        return (1.0, ingredient)
    }
    
    // adds item to pantry - add more quantity, otherwise add new item
    func addToPantry(name: String, quantity: Double, unit: String) {
        if let index = ingredients.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            let existingIngredient = ingredients[index]
            ingredients[index] = Ingredient(
                id: existingIngredient.id,
                name: existingIngredient.name,
                quantity: existingIngredient.quantity + quantity,
                unit: existingIngredient.unit // Keep the existing unit
            )
        } else {
            let newIngredient = Ingredient(
                id: UUID(),
                name: name,
                quantity: quantity,
                unit: unit
            )
            ingredients.append(newIngredient)
        }
        saveIngredients()
    }
    
    // removes item from pantry
    private func removeFromPantry(itemName: String, quantity: Double) {
        let normalizedRecipeItem = itemName.lowercased().trimmingCharacters(in: .whitespaces)
        
        if let index = ingredients.firstIndex(where: { ingredient in
            let pantryItemName = ingredient.name.lowercased().trimmingCharacters(in: .whitespaces)
            
            if pantryItemName == normalizedRecipeItem {
                return true
            }
            if pantryItemName.contains(normalizedRecipeItem) || normalizedRecipeItem.contains(pantryItemName) {
                return true
            }
            // removes anything that's similar
            return calculateSimilarity(pantryItemName, normalizedRecipeItem) > 0.7
        }) {
            
            let pantryIngredient = ingredients[index]
            let originalQuantity = pantryIngredient.quantity
            let newQuantity = max(0, pantryIngredient.quantity - quantity)
            
            ingredients[index] = Ingredient(
                id: pantryIngredient.id,
                name: pantryIngredient.name,
                quantity: newQuantity,
                unit: pantryIngredient.unit
            )
            
            // if item is finished, adds to shopping list
            if newQuantity <= 0 {
                ingredients.remove(at: index)
                addToShoppingList(
                    name: pantryIngredient.name,
                    quantity: originalQuantity,
                    unit: pantryIngredient.unit
                )
            }
        }
    }
    
    // found online to check similarity between two strings
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let longer = str1.count > str2.count ? str1 : str2
        let shorter = str1.count > str2.count ? str2 : str1
        
        if longer.count == 0 {
            return 1.0
        }
        
        let distance = levenshteinDistance(longer, shorter)
        return (Double(longer.count) - Double(distance)) / Double(longer.count)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let str1Array = Array(str1)
        let str2Array = Array(str2)
        let str1Count = str1Array.count
        let str2Count = str2Array.count
        
        if str1Count == 0 { return str2Count }
        if str2Count == 0 { return str1Count }
        
        var matrix = Array(repeating: Array(repeating: 0, count: str2Count + 1), count: str1Count + 1)
        
        for i in 0...str1Count {
            matrix[i][0] = i
        }
        
        for j in 0...str2Count {
            matrix[0][j] = j
        }
        
        for i in 1...str1Count {
            for j in 1...str2Count {
                let cost = str1Array[i-1] == str2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }
        
        return matrix[str1Count][str2Count]
    }
}
