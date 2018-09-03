import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    // Register the FluentPostgreSQL as a service to allow the application to interact with PostgreSQL via Fluent.
    try services.register(FluentPostgreSQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // 1 Create a DatabasesConfig to configure the database
    var databases = DatabasesConfig()
    
    // 2 Use Environment.get(_:) to fetch environment variables set by Vapor Cloud.
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "vapor"
    let databaseName = Environment.get("DATABASE_DB") ?? "vapor"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    
    // 3 Use the properties to create a new PostgreSQLDatabaseConfig
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: hostname,
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
    // As Acronym conforms to Migration, you can tell Fluent to create the table when the application starts.
    migrations.add(model: Acronym.self, database: .psql)
    services.register(migrations)
}
