
import Vapor
import FluentPostgreSQL

final class Category: Codable {
    var id: Int?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

// MARK: - Conform Category to Fluent's PostgreSQL Model
extension Category: PostgreSQLModel {}

// MARK: - Conform Category to Migration for saving data to db
extension Category: Migration {}

// MARK: - Conform Category to Content for converting data from Model to various formats using Content and Codable
extension Category: Content {}

// MARK: - Conform Category to Parameter
extension Category: Parameter {}

// MARK: - Category's Acronyms
extension Category {
    
    // 1. Add a computed property to Category to get its acronyms. This returns Fluent’s generic Sibling type. It returns the siblings of a Category that are of type Acronym and held using the AcronymCategoryPivot
    var acronyms : Siblings<Category, Acronym, AcronymCategoryPivot> {
        
        // 2. Use Fluent’s siblings() function to retrieve all the acronyms. Fluent handles everything else.
        return siblings()
    }
}
