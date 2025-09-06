import SwiftUI
import Foundation

struct RecipeView: View {
    let ingredients: [Ingredient]
    @State private var recipes: [Recipe] = []
    @State private var isLoading: Bool = false
    // variables for debugging errors
    @State private var errorMessage: String?
    @State private var debugInfo: String = ""
    
    @State private var selectedServings: Int = 2
    @StateObject private var recipeManager = RecipeManager.shared
    
    private let apiKey = "API_KEY_HERE"
    
    private let servingOptions = [1, 2, 3, 4, 5, 6, 7, 8]
    
    // avaliable recipes are ones that aren't currently making
    private var availableRecipes: [Recipe] {
        let currentlyMakingIds = Set(recipeManager.currentlyMakingRecipes.map { $0 })
        return recipes.filter { !currentlyMakingIds.contains($0.id) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // show this screen when loading
                if isLoading {
                    ProgressView("Generating recipes...")
                        .padding()
                } else if let error = errorMessage {
                    VStack {
                        Text("Oops! Something went wrong")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // use this to debug the issue
                        if !debugInfo.isEmpty {
                            ScrollView {
                                Text("Debug Info:")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                Text(debugInfo)
                                    .font(.system(size: 10))
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            .frame(maxHeight: 200)
                        }
                        
                        Button("Try Again") {
                            generateRecipes()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack {
                        // serving size dropdown
                        HStack {
                            Text("Servings:")
                                .font(.headline)
                            Spacer()
                            Picker("Servings", selection: $selectedServings) {
                                ForEach(servingOptions, id: \.self) { serving in
                                    Text("\(serving)").tag(serving)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 80)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                
                                // if there is a recipe that is currently being made, show currently cooking section
                                if !recipeManager.currentlyMakingRecipes.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "flame.fill")
                                                .foregroundColor(.orange)
                                            Text("Currently Cooking...")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                        }
                                        .padding(.horizontal)
                                        
                                        ForEach(recipeManager.getCurrentlyMakingRecipes(), id: \.id) { cookingRecipe in
                                            RecipeRow(recipe: scaleRecipe(cookingRecipe, for: selectedServings), isCurrentlyMaking: true)
                                        }
                                    }

                                    Divider()
                                        .padding(.vertical, 8)
                                }
                                
                                // show avaliable recipes
                                if !availableRecipes.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "book.fill")
                                                .foregroundColor(.blue)
                                            Text("Available Recipes")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.horizontal)
                                        
                                        ForEach(availableRecipes) { recipe in
                                            RecipeRow(recipe: scaleRecipe(recipe, for: selectedServings), isCurrentlyMaking: false)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Recipes")
            .onChange(of: ingredients) {
                generateRecipes()
            }
            .onAppear {
                if recipes.isEmpty {
                    generateRecipes()
                }
            }
        }
    }
    
    func generateRecipes() {
        
        // check for API key
        if apiKey == "API_KEY" {
            self.errorMessage = "Please add your API key"
            self.debugInfo = "Add your API key"
            return
        }
        
        isLoading = true
        // clears errors
        errorMessage = nil
        debugInfo = "Starting API request..."
        
        let ingredientList = ingredients.map { "\($0.quantity) \($0.unit) \($0.name)" }.joined(separator: ", ")
        
        // check that API key is valid
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            self.errorMessage = "Invalid API URL"
            self.isLoading = false
            return
        }
        
        // build the http request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // prompt for AI
        let prompt = "What are some recipes I can make with only the following ingredients: \(ingredientList). Follow this format exactly: Recipe 1: Title, Description, Time, Servings, Ingredients, Instructions ---- Recipe 2: Title, Description, Time, Servings, Ingredients, Instructions, and continue that for the rest"
        
        // decide on a model
        let body: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 500,
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            self.errorMessage = "Failed to create request"
            self.isLoading = false
            return
        }
        
        // send the request asyncronously
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                defer { self.isLoading = false }
                
                // catch network errors
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                // catch http response errors
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response"
                    return
                }
                
                self.debugInfo += "\nStatus code: \(httpResponse.statusCode)"
                
                // catch no data errors
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                // the non-parsed response
                let rawResponse = String(data: data, encoding: .utf8) ?? "Could not decode response"
                self.debugInfo += "\n\nRaw response:\n\(rawResponse)"
                
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.debugInfo += "\n\nJSON keys: \(Array(jsonResponse.keys))"
                        
                        // catch errors from the model
                        if let error = jsonResponse["error"] as? [String: Any],
                           let message = error["message"] as? String {
                            self.errorMessage = "Groq Error: \(message)"
                            return
                        }
                        
                        // parse the json to get the actual content
                        if let choices = jsonResponse["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let message = firstChoice["message"] as? [String: Any],
                           let content = message["content"] as? String {
                            
                            // parse through the content
                            self.debugInfo += "\n\nSUCCESS! Generated text: \(content.prefix(100))..."
                            let recipe = self.parseRecipesFromText(content, ingredientList: ingredientList)
                            self.recipes = recipe
                            
                        } else {
                            // debug the error from the json or parsing
                            self.debugInfo += "\n\nUnexpected response structure"
                            if let choices = jsonResponse["choices"] as? [Any] {
                                self.debugInfo += "\n\nChoices found: \(choices.count)"
                                if let firstChoice = choices.first {
                                    self.debugInfo += "\n\nFirst choice: \(firstChoice)"
                                }
                            }
                            self.errorMessage = "Could not parse Groq response"
                        }
                    }
                } catch {
                    // catch any errors
                    self.debugInfo += "\n\nJSON parsing failed: \(error.localizedDescription)"
                    self.errorMessage = "Failed to parse JSON: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func parseRecipesFromText(_ text: String, ingredientList: String) -> [Recipe] {
        let lines = text.components(separatedBy: .newlines)
        
        var recipes: [Recipe] = []
        
        var title = ""
        var time = ""
        var servings = ""
        var instructions: [String] = []
        var description = ""
        var aiIngredients: [String] = []
        
        var currentSection = ""
        
        func saveRecipeIfValid() {
            guard !title.isEmpty, !instructions.isEmpty else { return }
            
            // extract the title and remove fluff
            let cleanTitle = shortenTitle(title)
            
            // number the instructions
            let numberedInstructions = instructions.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")
            
            // extract the ingredients - use all ingredients if there are no ingredients being generated
            let finalIngredients = aiIngredients.isEmpty ? ingredientList.components(separatedBy: ", ") : aiIngredients
            
            // add the recipe
            let recipe = Recipe(
                id: UUID(),
                title: cleanTitle,
                description: description.isEmpty ? "A delicious recipe using your ingredients." : description,
                time: time,
                servings: servings,
                ingredients: finalIngredients,
                instructions: numberedInstructions,
                rawResponse: text
            )
            recipes.append(recipe)
        }
        
        func shortenTitle(_ fullTitle: String) -> String {
            let cleaned = fullTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "*", with: "")
            
            // remove fluff that have showed up
            let prefixesToRemove = ["Recipe for ", "Easy ", "Simple ", "Quick ", "Delicious ", "Homemade "]
            let suffixesToRemove = [" Recipe", " Dish", " (using your ingredients)", " with available ingredients"]
            
            var result = cleaned

            for prefix in prefixesToRemove {
                if result.lowercased().hasPrefix(prefix.lowercased()) {
                    result = String(result.dropFirst(prefix.count))
                }
            }

            for suffix in suffixesToRemove {
                if result.lowercased().hasSuffix(suffix.lowercased()) {
                    result = String(result.dropLast(suffix.count))
                }
            }
            
            // max 5 words in the title
            let words = result.components(separatedBy: " ").filter { !$0.isEmpty }
            if words.count > 5 {
                result = words.prefix(5).joined(separator: " ")
            } else {
                result = words.joined(separator: " ")
            }
            
            // capitalize
            result = result.capitalized
            
            // default
            return result.isEmpty ? "Mystery Dish" : result
        }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "*", with: "")
            
            if trimmed.isEmpty { continue }
            
            // if it says recipe - save the previous recipe and start new recipe
            if trimmed.lowercased().hasPrefix("recipe ") || trimmed.lowercased().hasPrefix("**recipe") {
                saveRecipeIfValid()
                // remove for new recipe
                title = ""
                time = ""
                servings = ""
                instructions = []
                description = ""
                aiIngredients = []
                currentSection = ""
                
                if let range = trimmed.range(of: ":") {
                    title = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                continue
            }
            
            // extract the information from the AI answer
            if trimmed.lowercased().hasPrefix("title:") {
                title = trimmed.replacingOccurrences(of: "title:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
                currentSection = "title"
            } else if trimmed.lowercased().hasPrefix("description:") {
                description = trimmed.replacingOccurrences(of: "description:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
                currentSection = "description"
            } else if trimmed.lowercased().hasPrefix("time:") {
                time = trimmed.replacingOccurrences(of: "time:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
                currentSection = "time"
            } else if trimmed.lowercased().hasPrefix("servings:") {
                servings = trimmed.replacingOccurrences(of: "servings:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
                currentSection = "servings"
            } else if trimmed.lowercased().hasPrefix("ingredients:") {
                currentSection = "ingredients"
            } else if trimmed.lowercased().hasPrefix("instructions:") {
                currentSection = "instructions"
            } else {
                switch currentSection {
                    // if the current section is ingredients:
                    case "ingredients":
                        var clean = trimmed
                        // remove bullets and stuff
                        clean = clean.replacingOccurrences(of: "^[-•\\s]+", with: "", options: .regularExpression)
                        if !clean.isEmpty { aiIngredients.append(clean) }

                    // if the current section is instruction
                    case "instructions":
                        var step = trimmed
                        // remove bullets, or numbers and stuff
                        step = step.replacingOccurrences(of: "^[0-9]+[.)]\\s*", with: "", options: .regularExpression)
                        step = step.replacingOccurrences(of: "^[-•\\s]+", with: "", options: .regularExpression)
                        if !step.isEmpty { instructions.append(step) }
                    case "description":
                        if description.isEmpty {
                            description = trimmed
                        } else {
                            // add any extra lines of description
                            description += " " + trimmed
                        }
                    default:
                        break
                }
            }
        }
        
        // save the last recipe
        saveRecipeIfValid()
        
        return recipes
    }
    
    // scale the ingredients, servings, cooktime based on selected servings
    private func scaleRecipe(_ recipe: Recipe, for servings: Int) -> Recipe {
        // extract the number of servings default to 4
        let numbers = recipe.servings.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
            .filter { $0 > 0 }
        let originalServings = numbers.first ?? 4
        
        // scale by the selected serving/original serving
        let scaleFactor = Double(servings) / Double(originalServings)
        
        // iterate through the ingredients and scale each
        let scaledIngredients = recipe.ingredients.map { ingredient in
            scaleIngredientString(ingredient, by: scaleFactor)
        }
        
        // scale the cooking time
        var scaledTime = recipe.time
        
        let pattern = #"(\d+)\s*(min|minute|minutes|hr|hour|hours)"#

        do { let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let nsString = recipe.time as NSString
            let results = regex.matches(in: recipe.time, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if !results.isEmpty {
                // match in reverse order to keep indices
                for match in results.reversed() {
                    let fullMatchRange = match.range
                    let numberRange = match.range(at: 1)
                    let unitRange = match.range(at: 2)
                    
                    let numberString = nsString.substring(with: numberRange)
                    let unitString = nsString.substring(with: unitRange)
                    
                    // extracts the number and scales it and keeps the unit
                    if let originalTime = Int(numberString) {
                        let scaledValue = scaleTimeValue(originalTime, unit: unitString, by: scaleFactor)
                        let newTimeString = "\(scaledValue) \(unitString)"
                        
                        scaledTime = (scaledTime as NSString).replacingCharacters(in: fullMatchRange, with: newTimeString)
                    }
                }
            }
        } catch {
            scaledTime = recipe.time
        }
        
        // create new recipe with new serving time and ingredients
        return Recipe(
            id: recipe.id,
            title: recipe.title,
            description: recipe.description,
            time: scaledTime,
            servings: "\(servings)",
            ingredients: scaledIngredients,
            instructions: recipe.instructions,
            rawResponse: recipe.rawResponse
        )
    }

    // scale the ingredients
    private func scaleIngredientString(_ ingredient: String, by scaleFactor: Double) -> String {

        let pattern = #"(\d+(?:\.\d+)?(?:/\d+)?|\d+/\d+)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return ingredient
        }
        
        let nsString = ingredient as NSString
        let results = regex.matches(in: ingredient, options: [], range: NSRange(location: 0, length: nsString.length))
            
        var scaledIngredient = ingredient
        
        // match in reverse order to keep indices
        for match in results.reversed() {
            let numberRange = match.range
            let numberString = nsString.substring(with: numberRange)
                
            let numberValue: Double
            if numberString.contains("/") {
                // check for fractions and change them into decimals
                let parts = numberString.split(separator: "/").compactMap { Double($0) }
                numberValue = parts.count == 2 ? parts[0] / parts[1] : 0.0
                } else {
                    // if it's already a whole number or decimal
                    numberValue = Double(numberString) ?? 0.0
                }
                    
                // scale the number to the number of servings
                let scaledValue = numberValue * scaleFactor
                    
                let newNumberString: String
                if scaledValue.rounded() == scaledValue {
                    newNumberString = String(Int(scaledValue))  // whole number
                } else if scaledValue < 10 {
                    // use fractions for numbers less than 10
                    let roundedHalf = round(scaledValue * 2) / 2
                    if abs(scaledValue - roundedHalf) < 0.01 {
                        let whole = Int(roundedHalf)
                        if roundedHalf == Double(whole) {
                            newNumberString = "\(whole)"
                        } else {
                            newNumberString = "\(whole) 1/2"
                        }
                    } else {
                        newNumberString = String(format: "%.2f", scaledValue).replacingOccurrences(of: ".00", with: "")
                    }
                } else {
                    newNumberString = String(format: "%.2f", scaledValue).replacingOccurrences(of: ".00", with: "")
                }
                    
                // use new number in string while keep the rest the same
                scaledIngredient = (scaledIngredient as NSString)
                    .replacingCharacters(in: numberRange, with: newNumberString)
            }
            
            return scaledIngredient
        }
    }
    
    // scale the time
private func scaleTimeValue(_ time: Int, unit: String, by factor: Double) -> Int {
    var timeInMinutes = 0
    // convert time into minutes
    let lowerUnit = unit.lowercased()
    if lowerUnit.contains("hr") || lowerUnit.contains("hour") {
        timeInMinutes = time * 60
    } else {
        timeInMinutes = time
    }
    
    let scaledMinutes: Double
    
    if timeInMinutes <= 15 {
        // increases time by 20% for double the servings
        scaledMinutes = Double(timeInMinutes) * (1.0 + (factor - 1.0) * 0.2)
    } else if timeInMinutes <= 60 {
        // increases time by 30% for double the servings
        scaledMinutes = Double(timeInMinutes) * (1.0 + (factor - 1.0) * 0.3)
    } else {
        // increases time by 40% for double the servings
        scaledMinutes = Double(timeInMinutes) * (1.0 + (factor - 1.0) * 0.4)
    }
        let finalMinutes = max(Int(scaledMinutes.rounded()), 1)
        let roundedMinutes = ((finalMinutes + 2) / 5) * 5
        
        // switch back from minutes
        if lowerUnit.contains("hr") || lowerUnit.contains("hour") {
            return max(1, roundedMinutes / 60)
        }
        return roundedMinutes
}
    
