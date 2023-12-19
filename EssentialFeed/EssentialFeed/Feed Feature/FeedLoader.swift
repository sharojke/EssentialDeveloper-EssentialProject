import Foundation

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(_ completion: @escaping (LoadFeedResult) -> Void)
}
