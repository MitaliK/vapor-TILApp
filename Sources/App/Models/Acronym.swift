
import Vapor
import FluentSQLite

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    
    init(short: String, long: String) {
        self.short = short
        self.long = long
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

// Conform to Fluent model same as above extension
extension Acronym: SQLiteModel {}

// Conform Acronym to Migration for saving data to db
extension Acronym: Migration {}

// Conform Acronym to Content for converting data from Model to various formats using Content and Codable
extension Acronym: Content {}
