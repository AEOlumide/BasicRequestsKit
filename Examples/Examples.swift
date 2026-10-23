//
//  File.swift
//  BasicRequestsKit
//
//  Created by Adedayo Olumide on 10/22/26.
//

import Foundation
import NetworkingKit

struct PhotoModel: Codable, Sendable, Identifiable {
    let id: Int
    let tags: String
    let previewURL: URL
}

struct PhotoDTO: Decodable, Sendable {
    let hits: [PhotoModel]
}

protocol PhotoServiceProtocol: Sendable {
    func getPhoto(searchTerm: String?, page: Int) async throws -> [PhotoModel]
}


struct PhotoService: PhotoServiceProtocol {
    private let controller: RequestsController
    private let apiKey: String
    
    init(controller: any RequestsController, apiKey: String) {
        self.controller = controller
        self.apiKey = apiKey
    }
    
    func getPhoto(searchTerm: String?, page: Int) async throws -> [PhotoModel] {
        guard var components = URLComponents(string: "https://api.example.com/photos") else { throw NetworkingError.invalidURL }
        
        var query: [URLQueryItem] = [
            .init(name: "key", value: apiKey),
            .init(name: "image_type", value: "photo"),
            .init(name: "page", value: String(page)),
            .init(name: "per_page", value: "20")
        ]
        
        if let searchTerm, !searchTerm.isEmpty {
            query.append(.init(name: "q", value: searchTerm))
        }
        
        components.queryItems = query
        
        guard let url = components.url else { throw NetworkingError.invalidURL }
        
        let request = HTTPRequestBuilder.make(url: url)
        let data = try await controller.fetch(request)
        let dto = try controller.decode(PhotoDTO.self, from: data)
        
        return dto.hits
    }
}

protocol AuthPhotoServiceProtocol: PhotoServiceProtocol {
    func updateToken(_ token: String?) async
}

struct AuthenticatedPhotoService: AuthPhotoServiceProtocol {
    private let actor: RequestsActor
    
    init(actor: RequestsActor) {
        self.actor = actor
    }
    
    func updateToken(_ token: String?) async {
        await actor.updateBearerToken(token)
    }
    
    func getPhotos(searchTerm: String?, page: Int) async throws -> [PhotoModel] {
        var components = URLComponents(
            string: "https://api.example.com/photos"
        )!
        
        components.queryItems = [
            .init(name: "page", value: String(page))
        ]
        
        let request = HTTPRequestBuilder.make(url: components.url!)
        let data = try await actor.fetch(request)
        let dto = try actor.decode(PhotoDTO.self, from: data)
        
        return dto.hits
    }
}


@MainActor
@Observable
final class PhotoViewModel {
    private let service: any PhotoServiceProtocol
    private let actorService: any AuthPhotoServiceProtocol
    private(set) var photos: [PhotoModel] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var searchTerm = ""
    
    init(service: any PhotoServiceProtocol, actorService: any AuthPhotoServiceProtocol) {
        self.service = service
        self.actorService = actorService
    }
    
    func fetchPhotos() async {
        guard !isLoading else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            async let feed = service.getPhoto(searchTerm: "Carnival", page: 1)
            async let userPhotos = service.getPhoto(searchTerm: "Backyard", page: 1)
            
            let (photos, userPhotos) = try await (photos, userPhotos)
            
            try Task.checkCancellation()
            
            self.photos = feed + userPhotos
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            
            errorMessage = error.localizedDescription
        }
    }
    
    func login(token: String) async {
        await actorService.updateToken(token)
    }
    
    func logout() async {
        await privateService.updateToken(nil)
    }
}
