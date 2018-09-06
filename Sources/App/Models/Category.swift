
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
    
    static func addCategory(_ name: String, to acronym: Acronym, on req: Request) throws -> Future<Void> {
        
        // Perform a query to search for a category with the provided name.
        return Category.query(on: req).filter(\.name == name).first().flatMap(to: Void.self, { foundCategory in
            
            // If the category exists, set up the relationship and transform to result to Void. () is shorthand for Void()
            if let existingCategory = foundCategory {
                return acronym.categories.attach(existingCategory, on: req).transform(to: ())
            } else {
                // If the category doesn’t exist, create a new Category object with the provided name.
                let category = Category(name: name)
                
                // Save the new category and unwrap the returned future.
                return category.save(on: req).flatMap(to: Void.self, { savedCategory in
                    
                    // Set up the relationship and transform the result to Void
                    return acronym.categories.attach(savedCategory, on: req).transform(to:())
                })
            }
        })
    }
}
