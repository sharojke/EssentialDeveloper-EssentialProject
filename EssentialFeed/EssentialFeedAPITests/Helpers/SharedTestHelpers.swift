import EssentialFeed
import Foundation

// swiftlint:disable force_unwrapping

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

func anyData() -> Data {
    return Data("any data".utf8)
}

func uniqueFeed() -> [FeedImage] {
    return [
        FeedImage(
            id: UUID(),
            url: anyURL(),
            description: "any",
            location: "any"
        )
    ]
}

// swiftlint:enable force_unwrapping
