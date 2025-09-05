import SwiftUI

// for each ingredient, this is the card that shows
struct IngredientRow: View {
    let ingredient: Ingredient
    
    var body: some View {
        return HStack (spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.headline)
                Text("\(ingredient.quantity, specifier: "%.1f") \(ingredient.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        // rectangle shaped card
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color:.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        
    }
}
