import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    func load(_ completion: @escaping (LoadFeedResult) -> Void)
}
