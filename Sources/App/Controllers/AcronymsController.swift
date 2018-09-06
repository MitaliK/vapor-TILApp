
import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    
    // MARK: - RouteCollection
    func boot(router: Router) throws {
        
        // MARK: - Route Groups
        // creates a new route group for the path /api/acronyms.
        let acronymsRoutes = router.grouped("api", "acronyms")
        acronymsRoutes.get(use: getAllHandler)
        
        // 1. Register createHandler(_:) to process POST requests to /api/acronyms.
        // The function signature now has an Acronym as a parameter. This is the decoded acronym from the request, so you don’t have to decode the data yourself.
        acronymsRoutes.post(Acronym.self, use: createHandler)
        
        // 2. Register getHandler(_:) to process GET requests to /api/acronyms/<ACRONYM ID>.
        acronymsRoutes.get(Acronym.parameter, use:  getHandler)
        
        // 3. Register updateHandler(:_) to process PUT requests to /api/acronyms/<ACRONYM ID>.
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        
        // 4. Register deleteHandler(:_) to process DELETE requests to /api/acronyms/<ACRONYM ID>.
        acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        
        // 5. Register searchHandler(:_) to process GET requests to /api/acronyms/search.
        acronymsRoutes.get("search", use: searchHandler)
        
        // 6. Register getFirstHandler(:_) to process GET requests to /api/acronyms/first.
        acronymsRoutes.get("first", use: getFirstHandler)
        
        // 7. Register sortedHandler(:_) to process GET requests to /api/acronyms/sorted.
        acronymsRoutes.get("sorted", use: sortedHandler)
        
        // 8. GET request to /api/acronyms/<ACRONYM ID>/user to getUserHandler(_:).
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        
        // 9. HTTP POST request to /api/acronyms/<ACRONYM_ID>/categories/<CATEGORY_ID> to addCategoriesHandler(_:)
        acronymsRoutes.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        
        // 10. HTTP GET request to /api/acronyms/<ACRONYM_ID>/categories to getCategoriesHandler(:_).
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)
        
        // 11. HTTP DELETE request to /api/acronyms/<ACRONYM_ID>/categories/<CATEGORY_ID> to removeCategoriesHandler(_:).
        acronymsRoutes.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
    }
    
    // MARK: - Retrieve all records
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    // MARK: - Create new record
    func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
        // 1. Save the model using Fluent. This returns Future<Acronym> as it returns the model once it’s saved.
        return acronym.save(on: req)
    }
    
    // MARK: - Retrieve single record
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        // 1. Extract the acronym from the request using the parameter function. This function performs all the work necessary to get the acronym from the database. It also handles the error cases when the acronym does not exist
        return try req.parameters.next(Acronym.self)
        
        /* the parameters must be fetched in the order they appear in the path.
         For example GET /posts/:post_id/comments/:comment_id must be fetched in this order:
         let post = try req.parameters.next(Post.self)
         let comment = try req.parameters.next(Comment.self) */
    }
    
    // MARK: - Update records
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        // 1. Use flatMap(to:_:_:), the dual future form of flatMap, to wait for both the parameter extraction and content decoding to complete. This provides both the acronym from the database and acronym from the request body to the closure.
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self), { (acronym, updateAcronym) in
            
            // 2. Update the acronym’s properties with the new values.
            acronym.short = updateAcronym.short
            acronym.long = updateAcronym.long
            acronym.userID = updateAcronym.userID
            
            // 3. Save the acronym and return the result
            return acronym.save(on: req)
            // Saves the model, calling either create(...) or update(...) depending on whether the model already has an ID.
            // Returns Future containing the saved model.
        })
    }
    
    // MARK: - Delete record
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        // 1. Extract the acronym to delete from the request’s parameters.
        return try req.parameters.next(Acronym.self)
            
            // 2. Delete the acronym using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future.
            .delete(on: req)
            
            // 3. Transform the result into a 204 No Content response. This tells the client the request has successfully completed
            .transform(to: HTTPStatus.noContent)
    }
    
    // MARK: - Search records
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        // 1. Retrieve the search term from the URL query string. You can do this with any Codable object by calling req.query.decode(_:)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        // 2. Use filter(_:) to find all acronyms whose short property matches the searchTerm. Because this uses key paths, the compiler can enforce type-safety on the properties and filter terms.
        // return Acronym.query(on: req).filter(\.short == searchTerm).all()
        // search multiple terms
        // 3. Create a filter group using the .or relation.
        return Acronym.query(on: req).group(.or, closure: { (or) in
            
            // 4. Add a filter to the group to filter for acronyms whose short property matches the search term.
            or.filter(\.short == searchTerm)
            
            // 5. Add a filter to the group to filter for acronyms whose long property matches the search term.
            or.filter(\.long == searchTerm)
        }).all()
    }
    
    // MARK: - Retrieve First element
    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        // 1. Perform a query to get the first acronym. Use the map(to:) function to unwrap the result of the query.
        // first() returns A Future containing the first result, if one exists.
        return Acronym.query(on: req).first().map(to: Acronym.self, { (acronym) in
            
            // 2. Ensure an acronym exists. first() returns an optional as there may be no acronyms in the database. Throw a 404 Not Found error if no acronym is returned.
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            
            // 3. Return the first acronym.
            return acronym
        })
    }
    
    // MARK: - Sorted records
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        // 1. Create a query for Acronym and use sort(_:_:) to perform the sort. This function takes the field to sort on and the direction to sort in. Finally use all() to return all the results of the query.
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }
    
    // MARK: - Getting Acronym's Parent
    // 1. Define a new route handler, getUserHandler(_:), that returns Future<User>.
    func getUserHandler(_ req: Request) throws -> Future<User> {
        
        // 2. Fetch the acronym specified in the request’s parameters and unwrap the returned future.
        return try req.parameters.next(Acronym.self).flatMap(to: User.self, { (acronym) in
            
            // 3. Use the new computed property created above to get the acronym’s owner.
            acronym.user.get(on: req)
        })
    }
    
    // MARK: - Creating Acronym's Sibling
    // 1. Define a new route handler, addCategoriesHandler(_:), that returns a Future<HTTPStatus>.
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        
        // 2. Use flatMap(to:_:_:) to extract both the acronym and category from the request’s parameters.
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self), { (acronym, category) in
            
            // 3. Use attach(_:on:) to set up the relationship between acronym and category. This creates a pivot model and saves it in the database. Transform the result into a 201 Created response.
            // Attaches the model to this relationship.
            return acronym.categories.attach(category, on: req).transform(to: .created)
        })
    }
    
    // MARK: - Getting Acronym's siblings
    // 1. Defines route handler getCategoriesHandler(_:) returning Future<[Category]>.
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        
        // 2. Extract the acronym from the request’s parameters and unwrap the returned future.
        return try req.parameters.next(Acronym.self).flatMap(to: [Category].self, { (acronym) in
            
            // 3. Use the new computed property to get the categories. Then use a Fluent query to return all the categories.
            try acronym.categories.query(on: req).all()
        })
    }
    
    // MARK: - Removing sibling relationship
    // 1. Define a new route handler, removeCategoriesHandler(_:), that returns a Future<HTTPStatus>.
    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        
        // 2. Use flatMap(to:_:_:) to extract both the acronym and category from the request’s parameters
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self), { (acronym, category) in
            
            // 3. Use detach(_:on:) to remove the relationship between acronym and category. This finds the pivot model in the database and deletes it. Transform the result into a 204 No Content response.
            return acronym.categories.detach(category, on: req).transform(to: .noContent)
        })
    }
}
