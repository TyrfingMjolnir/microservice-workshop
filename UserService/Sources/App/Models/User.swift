import FluentMySQL
import Validation
import Crypto
import Vapor
import JWTMiddleware

final class User: MySQLModel, Migration, Validatable, BasicJWTAuthenticatable {
    static let entity: String = "users"
    
    var id: Int?
    var firstname: String?
    var lastname: String?
    var email: String
    var password: String
    var deletedAt: Date?
    var createdAt: Date?
    var updatedAt: Date?
    
    init(_ email: String) throws {
        self.email = email
        self.password = ""
    }
    
    convenience init(_ email: String, _ firstName: String? = nil, _ lastName: String? = nil, _ password: String)throws {
        try self.init(email)
        
        self.firstname = firstName
        self.lastname = lastName
        self.password = try BCryptDigest().hash(password)
    }

    func addresses(on connection: DatabaseConnectable)throws -> QueryBuilder<Address.Database, Address> {
        return try Address.query(on: connection).filter(\.userId == self.requireID())
    }
    
    func response(on request: Request)throws -> Future<UserSuccessResponse> {
        return try self.addresses(on: request).all().map(to: UserSuccessResponse.self) { addresses in
            let user = UserResponse(user: self, addresses: addresses)
            return UserSuccessResponse(user: user)
        }
    }
    
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.password, .ascii && .count(6...))
        try validations.add(\.email, .email)
        return validations
    }
    
    static var usernameKey: WritableKeyPath<User, String> {
        return \.email
    }
    
    func accessToken(on request: Request) throws -> Future<Payload> {
        return Future.map(on: request) { try Payload(user: self) }
    }
    
    static var deletedAtKey: WritableKeyPath<User, Date?>? { return \.deletedAt }
    static var updatedAtKey: WritableKeyPath<User, Date?>? { return \.updatedAt }
    static var createdAtKey: WritableKeyPath<User, Date?>? { return \.createdAt }
}

