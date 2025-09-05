import SwiftUI

struct RecipeRow: View {
    let recipe: Recipe
    var isCurrentlyMaking: Bool = false
    
    // UI for the recipe card showing the title, description, time and servings
    var body: some View {
        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recipe.title)
                        .font(.headline)
                        .foregroundColor(isCurrentlyMaking ? .orange : .primary)
                    
                    Spacer()
                    
                }
                
                Text(recipe.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("Time: \(recipe.time)")
                    Text("Servings: \(recipe.servings)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                // have an orange outline if it's currently making
                    .fill(isCurrentlyMaking ? Color.orange.opacity(0.1) : Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isCurrentlyMaking ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
