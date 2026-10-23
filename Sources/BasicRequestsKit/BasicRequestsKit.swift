import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public typealias URLDataResponse = (data: Data, response: URLResponse)

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public enum NetworkingError: Error, Sendable {
    case invalidResponse
    case invalidURL
    case statusCode(code: Int, body: Data)
}

public protocol URLDataProvider: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLDataProvider {
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}

public enum ResponseValidator {
    public nonisolated static func validate(requestResponse: URLDataResponse, statusCodes: ClosedRange<Int> = 200...299) throws -> Data {
        guard let statusCode = (requestResponse.response as? HTTPURLResponse)?.statusCode else {
            throw NetworkingError.invalidResponse
        }
        
        guard statusCodes.contains(statusCode) else {
            throw NetworkingError.statusCode(code: statusCode, body: requestResponse.data)
        }
        
        return requestResponse.data
    }
}

public enum HTTPRequestBuilder {
    public static func make(url: URL, method: HTTPMethod = .get, headers: [String: String]? = [:], body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        
        if body != nil && request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        request.httpBody = body
        return request
    }
}

public final class RequestsController: Sendable {
    private let session: any URLDataProvider
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    public init(session: any URLDataProvider = URLSession.shared, decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }(), encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }
    
    public func decode<T: Decodable & Sendable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
    
    public func encode<T: Encodable & Sendable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }

    public func fetch(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        return try ResponseValidator.validate(requestResponse: (data, response))
    }
}

public actor RequestsActor {
    private let session: any URLDataProvider
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var bearerToken: String?
    
    public init(session: any URLDataProvider = URLSession.shared, decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }(), encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }(), bearerToken: String? = nil) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.bearerToken = bearerToken
    }
    
    public func updateBearerToken(_ token: String?) {
        bearerToken = token
    }
    
    public func decode<T: Decodable & Sendable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
    
    public func encode<T: Encodable & Sendable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }
    
    public func fetch(_ request: URLRequest) async throws -> Data {
        var authorizedRequest = request
        
        if let bearerToken {
            authorizedRequest.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: authorizedRequest)
        return try ResponseValidator.validate(requestResponse: (data, response))
    }
}
