import SwiftUI

struct AddIngredientView: View {
    // so that it's a pop up window
    @Environment(\.presentationMode) var presentationMode
    
    // list of ingredients
    @Binding var ingredients: [Ingredient]
    
    @State private var name: String = ""
    @State private var quantity: String = ""
    @State private var selectedUnit: String = ""
    @State private var showError: Bool = false
    
    let units = ["kgs", "g", "lbs", "oz", "ml", "L", "pieces", "slices", "cloves"]
    
    var body: some View {
        NavigationView {
            // creates a form for the user to fill
            Form {
                HStack {
                    Image(systemName: "leaf")
                        .foregroundColor(.green)
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                    // this is added to clear the error when the user starts fixing it
                        .onChange(of: name) {
                            showError = false
                        }
                }
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.blue)
                    TextField("Quantity", text: $quantity)
                    // quantity is a number
                        .keyboardType(.decimalPad)
                        .onChange(of: quantity) {
                            showError = false
                        }
                        
                }
                // wheel picker for the units
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(units, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                if showError {
                    Section(footer: Text("Please fill in all fields and enter a valid quantity")
                        .foregroundColor(.red)
                        .font(.caption)
                    ) { EmptyView() }
                }
            }
            .navigationTitle(Text("Add Ingredient"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        // show an error if missing inputs or words in quantity
                        if name.isEmpty || quantity.isEmpty || Double(quantity) == nil || selectedUnit.isEmpty {
                            showError = true
                        } else {
                            // add the new ingredient to ingredients
                            let newIngredient = Ingredient(name: name, quantity: Double(quantity)!, unit: selectedUnit)
                            ingredients.append(newIngredient)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Text("Add")
                            .fontWeight(.bold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}
