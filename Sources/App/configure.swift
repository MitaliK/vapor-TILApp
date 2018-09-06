import FluentPostgreSQL
import Vapor
import Leaf

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    // Register the FluentPostgreSQL as a service to allow the application to interact with PostgreSQL via Fluent.
    try services.register(FluentPostgreSQLProvider())
    
    // Register Leaf as a service for templating
    try services.register(LeafProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // 1. Create a DatabasesConfig to configure the database
    var databases = DatabasesConfig()
    
    // 2. Use Environment.get(_:) to fetch environment variables set by Vapor Cloud.
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "vapor"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    
    let databaseName: String
    let databasePort: Int
    // 3. If you’re running in the .testing environment, set the database name and port to different values.
    if (env == .testing) {
        databaseName = "vapor-test"
        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 5433
        } else {
            databasePort = 5433
        }
    } else {
        databaseName = Environment.get("DATABASE_DB") ?? "vapor"
        databasePort = 5432
    }
    
    // 4. Use the properties to create a new PostgreSQLDatabaseConfig
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: hostname,
        // 5. Configure the database port in the PostgreSQLDatabaseConfig.
        port: databasePort,
        username: username,
        database: databaseName,
        password: password)
    
    // 4 Create a PostgreSQLDatabase using the configuration
    let database = PostgreSQLDatabase(config: databaseConfig)
    
    // 5 Add the database object to the DatabasesConfig using the default .psql identifier.
    databases.add(database: database, as: .psql)
    
    // 6 Register DatabasesConfig with the services
    services.register(databases)

    /// Configure migrations
    // Create a MigrationConfig type which tells the application which database to use for each model
    var migrations = MigrationConfig()
    // As Acronym and User conforms to Migration, you can tell Fluent to create the table for respective classes when the application starts.
    // Because you’re linking the acronym’s userID property to the User table, you must create the User table first.
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    migrations.add(model: AcronymCategoryPivot.self, database: .psql)
    services.register(migrations)
    
    // 1. Create a CommandConfig with the default configuration.
    var commandConfig = CommandConfig.default()
    
    // 2. Add the Fluent commands to your CommandConfig. This adds both the revert command with the identifier revert and the migrate command with the identifier migrate
    commandConfig.useFluentCommands()
    
    // 3. Register the commandConfig as a service.
    services.register(commandConfig)
    
    // Configure for Leaf
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
}
