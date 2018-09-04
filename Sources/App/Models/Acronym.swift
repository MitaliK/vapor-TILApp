
import Vapor
import FluentPostgreSQL

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    var userID: User.ID
    
    init(short: String, long: String, userID: User.ID) {
        self.short = short
        self.long = long
        self.userID = userID
    }
}

// Conform to Fluent Model
//extension Acronym: Model {
//    // 1 Tell Fluent what database to use for this model
//    typealias Database = SQLiteDatabase
//
//    // 2 Tell Fluent what type the ID is.
//    typealias ID = Int
//
//    // 3  Tell Fluent the key path of the model’s ID property.
//    public static var idKey: IDKey = \Acronym.id
//}

// MARK: - Conform to Fluent model same as above extension
extension Acronym: PostgreSQLModel {}

// MARK: - Conform Acronym to Content for converting data from Model to various formats using Content and Codable
extension Acronym: Content {}

// MARK: - Conform Acronym to Parameter
extension Acronym: Parameter {}

// MARK: - Getting Acroym's Parent
extension Acronym {
    // 1. Add a computed property to Acronym to get the User object of the acronym’s owner. This returns Fluent’s generic Parent type.
    var user : Parent<Acronym, User> {
        // 2. Use Fluent’s parent(_:) function to retrieve the parent. This takes the key path of the user reference on the acronym.
        return parent(\.userID)
    }
}

// MARK: - Conform Acronym to Migration for saving data to db
extension Acronym: Migration {
    
    //1. Implement prepare(on:) as required by Migration. This overrides the default implementation.
    // Runs this migration’s changes on the database. This is usually creating a table, or updating an existing one.
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        
        // 2. Create the table for Acronym in the database.
        return Database.create(self, on: connection) { builder in
            
            // 4. Use addProperties(to:) to add all the fields to the database. This means you don’t need to add each column manually.
            // Automatically adds SchemaFields for each of this Models properties.
            try addProperties(to: builder)
            
            // 5. Add a reference between the userID property on Acronym and the id property on User
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}
