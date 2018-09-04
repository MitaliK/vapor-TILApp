
import Vapor

// MARK: - Define a new type UsersController that conforms to RouteCollection.
struct UsersController: RouteCollection {
 
    // MARK: - Implement boot(router:) as required by RouteCollection
    func boot(router: Router) throws {
        
        // MARK: - User route groups
        let usersRoute = router.grouped("api", "users")
        
        // Register createHandler(_:user:) to handle a POST request to /api/users. This uses the POST helper method to decode the request body into a User object.
        usersRoute.post(User.self, use: createHandler)
        
        // Register getAllHandler(_:) to process GET requests to /api/users/
        usersRoute.get(use: getAllHandler)
        
        // Register getHandler(_:) to process GET requests to /api/users/<USER ID>.
        usersRoute.get(User.parameter, use: getHandler)
        
        // Register GET request to /api/users/<USER ID>/acronyms to getAcronymsHandler(_:)
        usersRoute.get(User.parameter, "acronyms", use: getAcronymHandler)
    }
    
    // MARK: - Create user.
    func createHandler(_ req: Request, user: User) throws -> Future<User> {
        // Save the decoded user from the request.
        return user.save(on: req)
    }
    
    // MARK: - Retrieve Users
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    
    // MARK: - Retrieve User specified by request parameter
    func getHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(User.self)
    }
    
    // MARK: - Retrieve Acronyms for specifc user
    // 1. Define a new route handler, getAcronymsHandler(_:), that returns Future<[Acronym]>.
    func getAcronymHandler(_ req: Request) throws -> Future<[Acronym]> {
        
        // 2. Fetch the user specified in the request’s parameters and unwrap the returned future.
        return try req.parameters.next(User.self).flatMap(to: [Acronym].self, { (user) in
            
            // 3. Use the new computed property created in User.swift to get the acronyms using a Fluent query to return all the acronyms.
            try user.acronyms.query(on: req).all()
        })
    }
    
}
