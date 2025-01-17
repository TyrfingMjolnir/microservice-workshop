import Fluent
import FluentMySQLDriver
import Vapor
import SendGrid
import JWTKit

// Called before your application initializes.
func configure(_ app: Application) throws {
    // Register providers first
    app.provider(FluentProvider())
    
    let jwksString = """
{
  "keys": [
    {
      "kty": "RSA",
      "d": "BGSH12mVZbAlYny1C9KlswOORGsz0odL_NmvU-6mA_nNxXKz6nQIK6Il6L8VPYa9dZb1HwkFRDdyWqLYmjrTlQZievU9VLvmWaUlKXyIwOiXF3vqmzQy_luR-lE5v05pOqUgPhnPrQtGPvSuQpAYLFSJCX9YLJdmI0LA-0G_AvVnSjjSBnmvwZEKfHsZSRRC_cDOk8pm4A3iEMQv1_3xdwZ5GeKtkuAdNi9T31lMNlnKj-A5hZq6rfwiAWdxvCPqg44EyCKhj6c6sm2aM0qqKYb3sYMkYRmZh4GzaX8yQB3roQG-FLZ18VRm9q9YPuFavOL_L_NC8JG2Z6use4DbsQ",
      "e": "AQAB",
      "use": "sig",
      "kid": "backend",
      "alg": "RS256",
      "n": "ghZ4Eb-LT2tcCfWI6Szxu25kLQ3LOADA-KydgxASz_jMb5IHxMQIwMKFXe5qQ8lIG1lFhdu2G51GdXA8vaY148UtYt_COUnQSYOfIhcp7WpPXXhu83vqjET78CzkLsDI8VmF-9d8dHvtSVUqXfkk83kLOYmBcEamMWICUJj1yTiipqknuDZSMfIccXdhWEXr8gpl1cVZ5G2QZVNpFl1wGJ2UvwbQx6t9M6LDD9c9pqKc2-1X7pNLb-UekxhYzJHeRko288REN8AR7czaMQtZrB2hTEJAVixUu6KPGfSHxp49K2Hy2a1UC0nlohcrJ0ERfgMJ6oZ_n_kYeLx6nHeimw"
    }
  ]
}
"""
    let jwks:JWKS = try JSONDecoder().decode(JWKS.self, from: jwksString.data(using: .utf8)!)
    
    app.register(JWTSigner.self) { container in
        let key:RSAKey = RSAKey(modulus: jwks.keys.first!.modulus!, exponent: jwks.keys.first!.exponent!, privateExponent: jwks.keys.first!.privateExponent!)!
        return JWTSigner.rs256(key: key)
    }
    
    app.register(JWTMiddleware.self) { container in
        return JWTMiddleware()
    }
    
    app.register(SendGridConfig.self) { container in
        return SendGridConfig(apiKey: "asdfasdf")
    }
    
    app.provider(SendGridProvider())

    // Register middleware
    app.register(extension: MiddlewareConfiguration.self) { middlewares, app in
        // Serves files from `Public/` directory
        middlewares.use(app.make(ErrorMiddleware.self))
    }
    
    let url = URL(string: "mysql://user:password@localhost:3308/db")!
    
    app.register(request: Databases.self) { _ in
        return app.make()
    }
    
    app.register(request: Database.self) { container in
        guard let database = container.make(Databases.self).database(.mysql) else {
            throw Abort(.internalServerError, reason: "No databases registered with the `mysql` identifier.")
        }
        return database
    }
    app.databases.mysql(configuration: MySQLConfiguration(url: url)!, on: app.make())
    
    app.register(Migrations.self) { c in
        var migrations = Migrations()
        migrations.add(CreateUser(), to: .mysql)
        migrations.add(CreateAddress(), to: .mysql)
        return migrations
    }
    

    
    try routes(app)
}
