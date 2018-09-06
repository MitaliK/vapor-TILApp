
import Vapor
import Leaf
import Fluent

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
        
        // Register the route for /categories/
        router.get("categories", use: allCategoriesHandler)
        
        // Register the route for /categories/<CATEGORY ID>
        router.get("categories", Category.parameter, use: categoryHandler)
        
        // Register a route at /acronyms/create that accepts GET requests and calls createAcronymHandler(_:)
        router.get("acronyms", "create", use: createAcronymHandler)
        
        // Register a route at /acronyms/create that accepts POST requests and calls createAcronymPostHandler(_:acronym:). This also decodes the request’s body to an Acronym
        router.post(CreateAcronymData.self, at: "acronyms", "create", use: createAcronymPOSTHandler)
        
        // Register a route at /acronyms/edit that accepts GET requests and calls editAcronymHandler(_:)
        router.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        
        // Register a route at /acronyms/edit that accepts POST requests and calls editAcronymPostHandler(_:acronym:)
        router.post("acronyms", Acronym.parameter, "edit", use: editAcronymPOSTHandler)
        
        // Register a route at /acronyms/<ACRONYM.ID>/delete to accept POST requests and call deleteAcronymHandler(_:).
        router.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
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
                let categories = try acronym.categories.query(on: req).all()
                let context = AcronymContext(title: acronym.short, acronym: acronym, user: user, categories: categories)
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
    
    // Define a route handler for the "All Categories" page that returns Future<View>
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        
        // Get the categories from database, Leaf will handle the future
        let categories = Category.query(on: req).all()
        
        // Create an AllCategoriesContext and render the allCategories.leaf template then result the result
        let context = AllCategoriesContext(title: "All Categories", categories: categories)
        return try req.view().render("allCategories", context)
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        
        // Get the category from the request’s parameters and unwrap the returned future.
        return try req.parameters.next(Category.self).flatMap(to: View.self, { category in
            
            // Create a query to get all the acronyms for the category. This is a Future<[Acronym]>
            let acronyms = try category.acronyms.query(on: req).all()
            
            // Create a context for the page.
            let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
            
            return try req.view().render("category", context)
        })
    }
    
    func createAcronymHandler(_ req: Request) throws -> Future<View> {
        
        // Create a context by passing a query to get all users
        let context = CreateAcronymContent(title: "Create An Acronym", users: User.query(on: req).all())
        
        // Render the page using the createAcronym.leaf template.
        return try req.view().render("createAcronym", context)
    }
    
    // Create route to handle POST request for create Acronym
    // Vapor automatically decodes the form data to an Acronym object.
    func createAcronymPOSTHandler(_ req: Request, data: CreateAcronymData) throws -> Future<Response> {
        
        // Create an Acronym object to save as it’s no longer passed into the route.
        let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)
        
        // Save the provided acronym and unwrap the returned future
        return acronym.save(on: req).flatMap(to: Response.self, { acronym in

            // Ensure that the ID has been set, otherwise throw a 500 Internal Server Error.
            guard let id = acronym.id else {
                throw Abort(.internalServerError)
            }

            // Define an array of futures to store the save operations.
            var categoriesSave: [Future<Void>] = []
            
            // Loop through all the categories provided to the request and add the results of Category.addCategory(_:to:on:) to the array.
            for category in data.categories ?? [] {
                try categoriesSave.append(Category.addCategory(category, to: acronym, on: req))
            }
            
            // Flatten the array to complete all the Fluent operations and transform the result to a Response. Redirect the page to the new acronym’s page.
            let redirect = req.redirect(to: "/acronyms/\(id)")
            return categoriesSave.flatten(on: req).transform(to: redirect)
        })
    }
    
    // Route handler to handle edit acronym
    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        
        // Get the acronym to edit from the request’s parameter and unwrap the future
        return try req.parameters.next(Acronym.self).flatMap(to: View.self, { acronym in
            
            // Create a context to edit the acronym, passing in all the users.
            let users = User.query(on: req).all()
            let categories = try acronym.categories.query(on: req).all()
            let context = EditAcronymContext(title: "Edit Acronym", acronym: acronym, users: users, categories: categories)
            
            // Render the page using the createAcronym.leaf template, the same template used for the create page.
            return try req.view().render("createAcronym", context)
        })
    }
    
    // Route handler to place a post request for edit acronym
    func editAcronymPOSTHandler(_ req: Request) throws -> Future<Response> {
        
        // Use the convenience form of flatMap to get the acronym from the request’s parameter, decode the incoming data and unwrap both results.
        return try flatMap(to: Response.self, req.parameters.next(Acronym.self), req.content.decode(CreateAcronymData.self)) { acronym, data in
                acronym.short = data.short
                acronym.long = data.long
                acronym.userID = data.userID
                    
                // 2
                return acronym.save(on: req).flatMap(to: Response.self) { savedAcronym in
                        guard let id = savedAcronym.id else {
                            throw Abort(.internalServerError)
                        }
                    
                        // 3
                        return try acronym.categories.query(on: req).all().flatMap(to: Response.self) { existingCategories in
                                // 4
                                let existingStringArray = existingCategories.map { $0.name }
                                
                                // 5
                                let existingSet = Set<String>(existingStringArray)
                                let newSet = Set<String>(data.categories ?? [])
                                
                                // 6
                                let categoriesToAdd = newSet.subtracting(existingSet)
                                let categoriesToRemove = existingSet.subtracting(newSet)
                                
                                // 7
                                var categoryResults: [Future<Void>] = []
                                // 8
                                for newCategory in categoriesToAdd {
                                    categoryResults.append(
                                        try Category.addCategory(newCategory, to: acronym, on: req))
                                }
                                
                                // 9
                                for categoryNameToRemove in categoriesToRemove {
                                    // 10
                                    let categoryToRemove = existingCategories.first {
                                        $0.name == categoryNameToRemove
                                    }
                                    // 11
                                    if let category = categoryToRemove {
                                        categoryResults.append(
                                            acronym.categories.detach(category, on: req))
                                    }
                                }
                                // 12
                                return categoryResults.flatten(on: req).transform(to: req.redirect(to: "/acronyms/\(id)"))
                        }
                }
        }
    }
    
    // Route handler for deleting acronym
    func deleteAcronymHandler(_ req: Request) throws -> Future<Response> {
        
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: req.redirect(to: "/"))
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
    let categories: Future<[Category]>
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

// Context for all Categories
struct AllCategoriesContext: Encodable {
    let title: String
    let categories: Future<[Category]>
}

// Context for getting acronyms of particular category
struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let acronyms: Future<[Acronym]>
}

// Context for creating Acronym
struct CreateAcronymContent: Encodable {
    let title: String
    // A future array of users to display in the form.
    let users: Future<[User]>
}

// Context for editing acronyms
struct EditAcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    // A future array of users to display in the form.
    let users: Future<[User]>
    let editing = true
    let categories: Future<[Category]>
}

// Context for adding Category to Acronym
// This takes the existing information required for an acronym and adds an optional array of Strings to represent the categories. This allows users to submit existing and new categories instead of only existing ones.
struct CreateAcronymData: Content {
    let userID: User.ID
    let short: String
    let long: String
    let categories: [String]?
}
