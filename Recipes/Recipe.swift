import Foundation

struct Recipe: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var description: String
    var time: String
    var servings: String
    var ingredients: [String]
    var instructions: String
    var rawResponse: String
}
