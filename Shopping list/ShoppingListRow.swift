import SwiftUI

struct ShoppingListRow: View {
    let item: ShoppingList
    @ObservedObject var pantryManager: PantryManager
    
    var body: some View {
        HStack(spacing: 16) {
            // checkmark button
            Button(action: {
                pantryManager.toggleShoppingList(item)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                
                Text("\(Int(item.quantity.rounded())) \(item.unit)")
                    .font(.subheadline)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .opacity(item.isCompleted ? 0.6 : 1.0)
    }
}
