import Foundation

public struct LocalFeedItem: Equatable {
    public let id: UUID
    public let imageURL: URL
    public let description: String?
    public let location: String?
    
    public init(
        id: UUID,
        imageURL: URL,
        description: String? = nil,
        location: String? = nil
    ) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}
