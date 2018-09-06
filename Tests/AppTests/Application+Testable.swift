
import Vapor
import App
import FluentPostgreSQL

extension Application {
    
    // MARK: - Allows you to create a testable Application object.
    static func testable(envArgs: [String]? = nil) throws -> Application {
        
        // Create an Application, as in main.swift. This creates an entire Application object but doesn’t start running the application. This helps ensure you configure your real application correctly as your test calls the same App.configure(_:_:_:). Note, you’re using the .testing environment here.
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        
        if let environmentArgs = envArgs {
            env.arguments = environmentArgs
        }
        
        try App.configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        try App.boot(app)
        
        return app
    }
    
    // MARK: - Rest database
    static func reset() throws {
        // Reset the database
        // 1. Set the arguments the Application should execute.
        let revertEnvironmentAgrs = ["vapor", "revert", "--all", "-y"]
        
        // 2. Set up the services, configuration and testing environment. Set the arguments in the environment.
        try Application.testable(envArgs: revertEnvironmentAgrs).asyncRun().wait()
        
        // 3. Set the arguments the Application should execute.
        let migrationEnvironmentAgrs = ["vapor", "migrate", "-y"]
        
        // 4. Call asyncRun() which starts the application and execute the migrate command.
        try Application.testable(envArgs: migrationEnvironmentAgrs).asyncRun().wait()
    }
    
    // 1. Define a method that sends a request to a path and returns a Response. Allow the HTTP method and headers to be set; Also allow an optional, generic Content to be provided for the body.
    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: T? = nil) throws -> Response where T:Content {

        // 2. Create a responder, request and wrapped request as before.
        let responder = try self.make(Responder.self)
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        let wrappedRequest = Request(http: request, using: self)
        
        // 3. If the test contains a body, encode the body into the request’s content.
        if let body = body {
            // Using Vapor’s encode(_:) allows you to take advantage of any custom encoders you set.
            try wrappedRequest.content.encode(body)
        }
        
        // 4. Send the request and return the response.
        return try responder.respond(to: wrappedRequest).wait()
    }
    
    // 5. Define a convenience method that sends a request to a path without a body.
    func sendRequest(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init()) throws -> Response {
        
        // 6. Create an EmptyContent to satisfy the compiler for a body parameter.
        let emptyContent: EmptyContent? = nil
        
        // 7. Use the method created previously to send the request.
        return try sendRequest(to: path, method: method, headers: headers, body: emptyContent)
    }
    
    // 8. Define a method that sends a request to a path and accepts a generic Content type. This convenience method allows you to send a request when you don’t care about the response.
    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders, data: T) throws where T: Content {
        
        // 9. Use the method created previously to send the request and ignore the response
        _ = try self.sendRequest(to: path, method: method,headers: headers, body: data)
    }
    
    // 1. Define a generic method that accepts a Content type and Decodable type to get a response to a request.
    func getResponse<C, T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), data: C? = nil, decodeTo type: T.Type) throws -> T where C: Content, T: Decodable {
       
        // 2. Use the method created above to send the request.
        let response = try self.sendRequest(to: path, method: method, headers: headers, body: data)
        
        // 3. Decode the response body to the generic type and return the result.
        return try response.content.decode(type).wait()
    }
    
    // 4. Define a generic convenience method that accepts a Decodable type to get a response to a request without providing a body.
    func getResponse<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), decodeTo type: T.Type ) throws -> T where T: Decodable {
        
        // 5. Create an empty Content to satisfy the compiler.
        let emptyContent: EmptyContent? = nil
        
        // 6. Use the previous method to get the response to the request
        return try self.getResponse(to: path, method: method, headers: headers, data: emptyContent, decodeTo: type)
    }
}

// This defines an empty Content type to use when there’s no body to send in a request. Since you can’t define nil for a generic type, EmptyContent allows you to provide an type to satisfy the compiler.
struct EmptyContent: Content {}
