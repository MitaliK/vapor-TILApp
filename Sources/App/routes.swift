import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    // MARK: - CREATE
    // 1 Register a new route at /api/acronyms that accepts a POST request and returns Future<Acronym>. It returns the acronym once it’s saved.
    router.post("api", "acronyms") { req -> Future<Acronym> in
        
        // 2 Decode the request’s JSON into an Acronym model using Codable. This returns a Future<Acronym> so it uses a flatMap(to:) to extract the acronym when the decoding is complete.
        return try req.content.decode(Acronym.self).flatMap(to: Acronym.self) { acronym in
            
            // 3 Save the model using Fluent. This returns Future<Acronym> as it returns the model once it’s saved.
            return acronym.save(on: req)
        }
    }
    
    // MARK: - RETRIEVE ALL
    // 1. Register a new route handler for the request which returns Future<[Acronym]>, a future array of Acronyms.
    router.get("api", "acronyms") { (req) -> Future<[Acronym]> in
        // 2. Perform a query to get all the acronyms
        // all() is equivalent to SELECT * FROM Acronyms;
        return Acronym.query(on: req).all()
    }
    
    // MARK: - RETRIEVE SINGLE RECORD
    // 1. Register a route at /api/acronyms/<ID> to handle a GET request. The route takes the acronym’s id property as the final path segment. This returns Future<Acronym>.
    router.get("api", "acronyms", Acronym.parameter) { (req) -> Future<Acronym> in
        
        // 2. Extract the acronym from the request using the parameter function. This function performs all the work necessary to get the acronym from the database. It also handles the error cases when the acronym does not exist
        return try req.parameters.next(Acronym.self)
        
        /* the parameters must be fetched in the order they appear in the path.
         For example GET /posts/:post_id/comments/:comment_id must be fetched in this order:
         let post = try req.parameters.next(Post.self)
         let comment = try req.parameters.next(Comment.self) */
    }
    
    // MARK: - UPDATE
    // 1. Register a route for a PUT request to /api/acronyms/<ID> that returns Future<Acronym>.
    router.put("api", "acronyms", Acronym.parameter) { (req) -> Future<Acronym> in
     
        // 2. Use flatMap(to:_:_:), the dual future form of flatMap, to wait for both the parameter extraction and content decoding to complete. This provides both the acronym from the database and acronym from the request body to the closure.
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self), { (acronym, updateAcronym) in
            
            // 3. Update the acronym’s properties with the new values.
            acronym.short = updateAcronym.short
            acronym.long = updateAcronym.long
            
            // 4. Save the acronym and return the result
            return acronym.save(on: req)
            // Saves the model, calling either create(...) or update(...) depending on whether the model already has an ID.
            // Returns Future containing the saved model.
        })
    }
    
    // MARK: - DELETE
    // 1. Register a route for a DELETE request to /api/acronyms/<ID> that returns Future<HTTPStatus>.
    router.delete("api", "acronyms", Acronym.parameter) { (req) -> Future<HTTPStatus> in
        
        // 2. Extract the acronym to delete from the request’s parameters.
        return try req.parameters.next(Acronym.self)
            
            // 3. Delete the acronym using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future.
            .delete(on: req)
            
            // 4. Transform the result into a 204 No Content response. This tells the client the request has successfully completed
            .transform(to: HTTPStatus.noContent)
    }
    
    // MARK: - FILTER / SEARCH
    // 1. Register a new route handler for /api/acronyms/search that returns Future<[Acronym]>.
    router.get("api", "acronyms", "search") { (req) -> Future<[Acronym]> in
        
        // 2. Retrieve the search term from the URL query string. You can do this with any Codable object by calling req.query.decode(_:)
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        // 3. Use filter(_:) to find all acronyms whose short property matches the searchTerm. Because this uses key paths, the compiler can enforce type-safety on the properties and filter terms.
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
    
    // MARK: - Retuen First Result
    // 1. Register a new HTTP GET route for /api/acronyms/first that returns Future<Acronym>.
    router.get("api", "acronyms", "first") { (req) -> Future<Acronym> in
        
        // 2. Perform a query to get the first acronym. Use the map(to:) function to unwrap the result of the query.
        // first() returns A Future containing the first result, if one exists.
        return Acronym.query(on: req).first().map(to: Acronym.self, { (acronym) in
            
            // 3. Ensure an acronym exists. first() returns an optional as there may be no acronyms in the database. Throw a 404 Not Found error if no acronym is returned.
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            
            // 4. Return the first acronym.
            return acronym
        })
    }
    
    // MARK: - SORT RECORDS
    // 1. Register a new HTTP GET route for /api/acronyms/sorted that returns Future<[Acronym]>.
    router.get("api", "acronyms", "sorted") { (req) -> Future<[Acronym]> in
        
        // 2. Create a query for Acronym and use sort(_:_:) to perform the sort. This function takes the field to sort on and the direction to sort in. Finally use all() to return all the results of the query.
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }
}
