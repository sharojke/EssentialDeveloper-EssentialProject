import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(_ completion: @escaping (LoadFeedResult) -> Void)
}
