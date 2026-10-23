# BasicRequestsKit

A basic Swift HTTP networking package with built on URLSession and async/await for a variety of Apple Platforms.

Use `RequestsController` for requests without bearer token auth, or `RequestsActor` for bearer token authentication.

## Requirements

- Swift 6.2 or later
- iOS 15+, macOS 12+, watchOS 8+, tvOS 15+, or visionOS 1+


### RequestsController

```swift
import Foundation
import BasicRequestsKit

struct PhotoModel: Codable, Sendable, Identifiable {
    let id: Int
    let tags: String
    let previewURL: URL
}

struct PhotoService {
    func fetchPhoto() async throws -> [PhotoModel] {
        let controller = RequestsController()
        
        guard let url = URL(string: "https://example.com/photos") else {
            throw NetworkingError.invalidURL
        }
        
        let request = HTTPRequestBuilder.make(url: url)
        let data = try await controller.fetch(request)
        
        return try actor.decode([PhotoModel] , from: data)
    }
}

### RequestsActor

```swift
import Foundation
import BasicRequestsKit

struct Profile: Codable, Sendable {
    let id: Int
    let name: String
}

struct ProfileService {
    private let actor: RequestsActor

    func updateToken(_ token: String?) async {
        await actor.updateBearerToken(token)
    }
    
    func getPhotos(searchTerm: String?, page: Int) async throws -> [PhotoModel] {
         guard let url = URL(string: "https://example.com/photos") else {
            throw NetworkingError.invalidURL
        }

        
        let request = HTTPRequestBuilder.make(url: components.url!)
        let data = try await actor.fetch(request)
	return try actor.decode(Profile.self, from: data)        
    }
}

```

## License

BasicRequestsKit is available under the MIT license. See the LICENSE file for more info.
