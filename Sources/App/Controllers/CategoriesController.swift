
import Vapor

// MARK: - Define a new type CategoriesController that conforms to RouteCollection.
struct CategoriesController: RouteCollection {
    
    // MARK: - Implement boot(router:) as required by RouteCollection
    func boot(router: Router) throws {
        
        // MARK: - Categories route groups
        let categoriesRoute = router.grouped("api", "categories")
        
        // Register createHandler(_:user:) to handle a POST request to /api/categories. This uses the POST helper method to decode the request body into a User object.
        categoriesRoute.post(Category.self, use: createHandler)
        
        // Register getAllHandler(_:) to process GET requests to /api/categories/
        categoriesRoute.get(use: getAllHandler)
        
        // Register getHandler(_:) to process GET requests to /api/categories/<Category ID>.
        categoriesRoute.get(Category.parameter, use: getHandler)
        
        // HTTP GET request to /api/categories/<CATEGORY_ID>/acronyms to getAcronymsHandler(:_).
        categoriesRoute.get(Category.parameter, "acronyms", use: getAcronymsHandler)
    }
    
    // MARK: - Create Category.
    func createHandler(_ req: Request, category: Category) throws -> Future<Category> {
        // Save the decoded category from the request.
        return category.save(on: req)
    }
    
    // MARK: - Retrieve all Categories
    func getAllHandler(_ req: Request) throws -> Future<[Category]> {
        // Perform a Fluent query to retrieve all the categories from the database
        return Category.query(on: req).all()
    }
    
     // MARK: - Retrieve Category specified by request parameter
    func getHandler(_ req: Request) throws -> Future<Category> {
        // Return the category extracted from the request’s parameters
        return try req.parameters.next(Category.self)
    }
    
    // MARK: -  Getting Category's siblings
    // 1. Define a new route handler, getAcronymsHandler(_:), that returns Future<[Acronym]>.
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        
        // 2. Extract the category from the request’s parameters and unwrap the returned future.
        return try req.parameters.next(Category.self).flatMap(to: [Acronym].self, { (category) in
            
            // 3. Use the new computed property to get the acronyms. Then use a Fluent query to return all the acronyms.
            try category.acronyms.query(on: req).all()
        })
    }
}
