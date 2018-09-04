
import FluentPostgreSQL
import Foundation
import Vapor

// MARK: - Conform to PostgreSQLPivot and ModifiablePivot
// Define a new object AcronymCategoryPivot that conforms to PostgreSQLUUIDPivot. This is a helper protocol on top of Fluent’s Pivot protocol. Also conform to ModifiablePivot. This allows you to use the syntactic sugar Vapor provides for adding and removing the relationships.
final class AcronymCategoryPivot: PostgreSQLUUIDPivot, ModifiablePivot {
    
    // 2. Define an id for the model. Note this is a UUID type so you must import the Foundation module in the file.
    var id: UUID?
    
    // 3. Define two properties to link to the IDs of Acronym and Category. This is what holds the relationship.
    var acronymID: Acronym.ID
    var categoryID: Category.ID
    
    // 4. Define the Left and Right types required by Pivot. This tells Fluent what the two models in the relationship are.
    typealias Left = Acronym
    typealias Right = Category
    
    // 5. Tell Fluent the key path of the two ID properties for each side of the relationship.
    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID
    
    // 6. Implement the throwing initializer, as required by ModifiablePivot.
    init(_ acronym: Acronym, _ category: Category) throws {
        self.acronymID = try acronym.requireID()
        self.categoryID = try category.requireID()
    }
}

// MARK: - Conform AcronymCategoryPivot to Migration for saving data to db
// 1. Conform AcronymCategoryPivot to Migration.
extension AcronymCategoryPivot: Migration {
    
    // 2. Implement prepare(on:) as defined by Migration. This overrides the default implementation.
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        
        // 3. Create the table for AcronymCategoryPivot in the database.
        return Database.create(self, on: connection) { builder in
            
            // 4. Use addProperties(to:) to add all the fields to the database.
            try addProperties(to: builder)
            
            // 5. Add a reference between the acronymID property on AcronymCategoryPivot and the id property on Acronym. This sets up the foreign key constraint. .cascade sets a cascade schema reference action when you delete the acronym. This means that the relationship is automatically removed instead of an error being thrown.
            builder.reference(from: \.acronymID, to: \Acronym.id, onUpdate: nil, onDelete: .cascade)
            
            // 6. Add a reference between the categoryID property on AcronymCategoryPivot and the id property on Category. This sets up the foreign key constraint. Also set the schema reference action for deletion when deleting the category.
            builder.reference(from: \.categoryID, to: \Category.id, onUpdate: nil, onDelete: .cascade)
        }
    }
}
