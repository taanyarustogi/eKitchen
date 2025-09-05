import SwiftUI

struct HomeScreenView: View {
    // variables stored in the phone
    @AppStorage("startingPantry") private var startingPantry: Data = Data()
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    
    // list of ingredients
    @State private var selectedIngredients: Set<String> = []
    @State private var ingredientDetails: [String: (quantity: String, unit: String)] = [:]
    
    let commonIngredients = [
        "Eggs", "Milk", "Bread", "Butter", "Cheese", "Rice", "Pasta", "Flour", "Tomato", "Beans", "Beef", "Fish", "Onions", "Oil", "Garlic"
    ]
    
    let units = ["kgs", "g", "lbs", "oz", "ml", "L", "pieces", "slices", "cloves"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        Group {
            ScrollView {
            VStack(spacing: 24) {
                Text("Welcome! Select what you have in your kitchen:")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // stack of common ingredients in capsule buttons
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(commonIngredients, id: \.self) { ingredient in
                        Button(action: {
                            if selectedIngredients.contains(ingredient) {
                                selectedIngredients.remove(ingredient)
                                ingredientDetails.removeValue(forKey: ingredient)
                            } else {
                                selectedIngredients.insert(ingredient)
                                ingredientDetails[ingredient] = ("1", "pieces")
                            }
                        }) {
                            Text(ingredient)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                    // selected ingredients have a colored outline to differenciate
                                        .stroke(selectedIngredients.contains(ingredient) ? Color.accentColor : Color.gray, lineWidth: 2)
                                        .background(
                                            Capsule()
                                                .fill(selectedIngredients.contains(ingredient) ? Color.accentColor.opacity(0.2) : Color.clear)
                                        )
                                )
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal)
                // when there are ingredients selected, UI for users to enter quantity and unit
                if !selectedIngredients.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(Array(selectedIngredients), id: \.self) { name in
                            HStack {
                                Text(name)
                                    .frame(width: 90, alignment: .leading)
                                TextField("Qty", text: Binding(
                                    get: { ingredientDetails[name]?.quantity ?? ""},
                                    set: { newValue in
                                        var detail = ingredientDetails[name] ?? ("", "pieces")
                                        detail.quantity = newValue
                                        ingredientDetails[name] = detail
                                    }
                                ))
                                .keyboardType(.decimalPad)
                                .frame(width: 50)
                                // use a picker for the unit
                                Picker("Unit", selection: Binding(
                                    get: { ingredientDetails[name]?.unit ?? "pieces"},
                                    set: { newValue in
                                        var detail = ingredientDetails[name] ?? ("", "pieces")
                                        detail.unit = newValue
                                        ingredientDetails[name] = detail
                                    }
                                )){
                                    ForEach(units, id: \.self) { unit in
                                        Text(unit).tag(unit)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 100)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                // continue button saves the ingredients details to show in inventory view
                Button(action: {
                    let pantry = ingredientDetails.compactMap{ (name, detail) -> Ingredient? in
                        if let qty = Double(detail.quantity), !name.isEmpty, !detail.unit.isEmpty {
                            return Ingredient(name: name, quantity: qty, unit: detail.unit)
                        }
                        return nil
                    }
                       if let data = try? JSONEncoder().encode(pantry) {
                    startingPantry = data
                }
                       hasLaunchedBefore = true
            }) {
                Text("Continue")
                    .fontWeight(.bold)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(30)
            }
            .padding(.bottom)
        }
        .padding()
    }
}
}
}

