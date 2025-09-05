import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var isCurrentlyMaking: Bool = false
    
    // clicked on a recipe it opens this view with the ingredients and instructions
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(recipe.description)
                    .font(.body)
                HStack {
                    Text("Time: \(recipe.time)")
                    Text("Servings: \(recipe.servings)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // cooking buttons
                HStack(spacing: 12) {
                    if !isCurrentlyMaking {
                        Button(action: {
                            isCurrentlyMaking = true
                            // mark this recipe as being made to prevent regeneration
                            RecipeManager.shared.setRecipeAsCurrentlyMaking(recipe)
                        }) {
                            Label("Start Making", systemImage: "play.fill")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    } else {
                        HStack(spacing: 12) {
                            Button(action: {
                                isCurrentlyMaking = false
                                RecipeManager.shared.setRecipeAsCompleted(recipe.id)
                            }) {
                                Label("Cancel", systemImage: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                // remove the ingredients used from pantrymanager
                                PantryManager.shared.consumeIngredients(from: recipe)
                                isCurrentlyMaking = false
                                RecipeManager.shared.setRecipeAsCompleted(recipe.id)
                            }) {
                                Label("Done Making", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                Text("Ingredients")
                    .font(.headline)
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    HStack {
                        Text("• \(ingredient)")
                        Spacer()
                        if isCurrentlyMaking {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
                Divider()
                Text("Instructions")
                    .font(.headline)
                Text(recipe.instructions)
                
//                if !recipe.rawResponse.isEmpty {
//                    Text("Raw Response")
//                        .font(.headline)
//                    ScrollView(.horizontal) { // horizontal scroll for long lines
//                        Text(recipe.rawResponse)
//                            .font(.system(size: 12, design: .monospaced))
//                            .padding()
//                            .background(Color.gray.opacity(0.1))
//                            .cornerRadius(8)
//                    }
//                }
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .onAppear {
            // check each recipe's status on appear
            isCurrentlyMaking = RecipeManager.shared.isRecipeCurrentlyMaking(recipe.id)
        }
    }
}
