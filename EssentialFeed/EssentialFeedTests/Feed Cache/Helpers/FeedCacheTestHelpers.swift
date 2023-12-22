import EssentialFeed
import Foundation

// swiftlint:disable force_unwrapping

func uniqueImage() -> FeedImage {
    return FeedImage(
        id: UUID(),
        url: anyURL()
    )
}

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let items = [uniqueImage(), uniqueImage()]
    let localItems = items.map { feedItem in
        LocalFeedImage(
            id: feedItem.id,
            url: feedItem.url,
            description: feedItem.description,
            location: feedItem.location
        )
    }
    return (items, localItems)
}

// MARK: - Used for policy

extension Date {
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
    
    func minusFeedCacheMaxAge() -> Self {
        return self.adding(days: -feedCacheMaxAgeInDays)
    }
    
    private func adding(days: Int) -> Self {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

// MARK: - Just a reusable helper method

extension Date {
    func adding(seconds: TimeInterval) -> Self {
        return self + seconds
    }
}

// swiftlint:enable force_unwrapping
