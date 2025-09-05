import Foundation

struct Ingredient: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String
}
