import Foundation

public enum ImageCommentsMapper {
    public enum Error: Swift.Error {
        case invalidData
    }
    
    public static func map(
        _ data: Data,
        from response: HTTPURLResponse
    ) throws -> [ImageComment] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard isOK(response),
              let root = try? decoder.decode(Root.self, from: data) else {
            throw Error.invalidData
        }
        
        return root.comments
    }
    
    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        return (200...299).contains(response.statusCode)
    }
}

private extension ImageCommentsMapper {
    struct Root: Decodable {
        private let items: [Item]
        
        var comments: [ImageComment] {
            return items.map { item in
                ImageComment(
                    id: item.id,
                    message: item.message,
                    createdAt: item.created_at,
                    username: item.author.username
                )
            }
        }
    }
}

private extension ImageCommentsMapper.Root {
    private struct Item: Decodable {
        let id: UUID
        let message: String
        let created_at: Date
        let author: Author
    }
    
    private struct Author: Decodable {
        let username: String
    }
}
