import Fluent
import FluentMySQLDriver
import Vapor

// Called before your application initializes.
func configure(_ app: Application) throws {
    // Register providers first
    app.provider(FluentProvider())

    // Register middleware
    app.register(extension: MiddlewareConfiguration.self) { middlewares, app in
        // Serves files from `Public/` directory
        // middlewares.use(app.make(FileMiddleware.self))
    }
    
   /*app.databases.sqlite(
        configuration: .init(storage: .connection(.file(path: "db.sqlite"))),
        threadPool: app.make(),
        poolConfiguration: app.make(),
        logger: app.make(),
        on: app.make()
    )*/
    
    let url = URL(string: "mysql://user:password@localhost:3306/db")!
    
    app.databases.mysql(configuration: MySQLConfiguration(url: url)!, on: app.make())
    
    app.register(Migrations.self) { c in
        var migrations = Migrations()
        migrations.add(CreateOrder(), to: .mysql)
        migrations.add(CreateOrderItem(), to: .mysql)
        return migrations
    }
    
    app.register(JWTMiddleware.self) { container in
        return JWTMiddleware()
    }
    
    try routes(app)
}
