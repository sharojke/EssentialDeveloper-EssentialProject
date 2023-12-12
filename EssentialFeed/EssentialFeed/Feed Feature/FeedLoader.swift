import Foundation

enum LoadFeedRequest {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(_ completion: () -> Void)
}
