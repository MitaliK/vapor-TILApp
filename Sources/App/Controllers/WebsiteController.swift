
import Vapor
import Leaf


// 1. Declare a new WebsiteController type that conforms to RouteCollection.
struct WebsiteController: RouteCollection {
    
    // 2. Boot function
    func boot(router: Router) throws {
        
        // 3. Register indexHandler(_:) to process GET requests to the router’s root path, i.e., a request to /.
        router.get(use: indexHandler)
        
        // This registers the acronymHandler route for /acronyms/<ACRONYM ID>
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
        
        // This registers the route for /users/<USER ID>, like the API
        router.get("users", User.parameter, use: userHandler)
        
        // This registers the route for /users/
        router.get("users", use: allUsersHandler)
    }
    
    // 4. Implement indexHandler(_:) that returns Future<View>
    func indexHandler(_ req: Request) throws -> Future<View> {
        // 1. Use a Fluent query to get all the acronyms from the database.
        return Acronym.query(on: req).all().flatMap(to: View.self, { acronyms in
            
            // 2.
            let acronymData = acronyms.isEmpty ? nil: acronyms
            
            // 3. Create an IndexContext containing the desired title.
            let content = IndexContent(title2: "HomePage", acronyms: acronymData)
            
            // 4. Render the index template and return the result
            return try req.view().render("index", content)
        })
    }
    
    // Route handler for acronym
    // Declare a new route handler, acronymHandler(_:), that returns Future<View>.
    func acronymHandler(_ req: Request) throws -> Future<View> {
        
        // 1. Extract the acronym from the request’s parameters and unwrap the result.
        return try req.parameters.next(Acronym.self).flatMap(to: View.self, { acronym in
            
            // 2. Get the user for acronym and unwrap the result
            return acronym.user.get(on: req).flatMap(to: View.self, { user in
                
                // 3. Create an AcronymContext that contains the appropriate details and render the page using the acronym.leaf template.
                let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
                return try req.view().render("acronym", context)
            })
        })
    }
    
    // 1 Define the route handler for the user page that returns Future<View>.
    func userHandler(_ req: Request) throws -> Future<View> {
        
        // 2 Get the user from the request’s parameters and unwrap the future.
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            
            // 3 Get the user’s acronyms using the computed property and unwrap the future.
            return try user.acronyms.query(on: req).all().flatMap(to: View.self) { acronyms in
                
                // 4 Create a UserContext, then render the user.leaf template, returning the result. In this case, you’re not setting the acronyms array to nil if it’s empty. This is not required as you’re checking the count in template
                    let context = UserContext(title: user.name,user: user, acronyms: acronyms)
                    return try req.view().render("user", context)
            }
        }
    }
    
    // 1. Define a route handler for the “All Users” page that returns Future<View>.
    func allUsersHandler(_ req: Request) throws -> Future<View> {
        
        // 2. Get the users from the database and unwrap the future
        return User.query(on: req).all().flatMap(to: View.self, { users in
            
            // 3. Create an AllUsersContext and render the allUsers.leaf template, then return the result.
            let context = AllUsersContext(title: "All Users", users: users)

            return try req.view().render("allUsers", context)
        })
    }
}

// Leaf uses Codable to handle Data
// As data only flows to Leaf, you only need to conform to Encodable.
struct IndexContent: Encodable {
    let title2: String
    let acronyms: [Acronym]?
}

// Details of acronyms
struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
}

// This context contains inform about acronym and its user
struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}

// This context contains a title and an array of users.
struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}
