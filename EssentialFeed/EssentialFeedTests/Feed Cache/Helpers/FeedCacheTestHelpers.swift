import EssentialFeed
import Foundation

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
}
