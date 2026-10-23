import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import BasicRequestsKit

private struct MockSession: URLDataProvider {
    let statusCode: Int
    let data: Data

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }
}

private struct Item: Codable, Sendable, Equatable {
    let id: Int
}

@Suite("BasicRequestsKit")
struct BasicRequestsTests {
    @Test func classReturnsData() async throws {
        let data = Data("hello".utf8)
        let controller = RequestsController(session: MockSession(statusCode: 200, data: data))
        let request = URLRequest(url: URL(string: "https://test.com")!)
        #expect(try await controller.fetch(request) == data)
    }

    @Test func actorReturnsData() async throws {
        let data = Data("hello".utf8)
        let actor = RequestsActor(session: MockSession(statusCode: 200, data: data))
        let request = URLRequest(url: URL(string: "https://test.com")!)
        #expect(try await actor.fetch(request) == data)
    }

    @Test func classReturnsNotFound() async throws {
        let controller = RequestsController(session: MockSession(statusCode: 404, data: Data()))
        do {
            _ = try await controller.fetch(URLRequest(url: URL(string: "https://test.com")!))
            Issue.record("Expected a 404 error")
        } catch NetworkingError.statusCode(let code, _) {
            #expect(code == 404)
        }
    }

    @Test func actorReturnsNotFound() async throws {
        let actor = RequestsActor(session: MockSession(statusCode: 404, data: Data()))
        do {
            _ = try await actor.fetch(URLRequest(url: URL(string: "https://test.com")!))
            Issue.record("Expected a 404 error")
        } catch NetworkingError.statusCode(let code, _) {
            #expect(code == 404)
        }
    }

    @Test func packageValidatorIsAccessibleFromPackageTestTarget() throws {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil)!
        let data = Data()
        #expect(try ResponseValidator.validate(requestResponse: (data, response)) == data)
    }
}
