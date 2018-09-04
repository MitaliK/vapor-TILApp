
import Foundation
import Vapor
import FluentPostgreSQL

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    
    init(name: String, username: String) {
        self.name = name
        self.username = username
    }
}

// MARK: - Conform user to Fluent's PostgreSQL Model
extension User: PostgreSQLUUIDModel {}

// MARK: - Conform User to Migration for saving data to db
extension User: Migration {}

// MARK: - Conform User to Content for converting data from Model to various formats using Content and Codable
extension User: Content {}

// MARK: - Conform User to Parameter
extension User: Parameter {}

// MARK: - Getting User's acronyms
extension User {
    
    // 1. Add a computed property to User to get a user’s acronyms. This returns Fluent’s generic Children type.
    var acronyms: Children<User, Acronym> {
        
        // 2. Use Fluent’s children(_:) function to retrieve the children. This takes the key path of the user reference on the acronym.
        return children(\.userID)
    }
}



