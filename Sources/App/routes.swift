import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // MARK: - Register RouteCollection
    // 1. Create a new AcronymsController.
    let acronymsController = AcronymsController()
    // 2. Register the new type with the router to ensure the controller’s routes get registered.
    try router.register(collection: acronymsController)
}
