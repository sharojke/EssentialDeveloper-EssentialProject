import EssentialFeed
import XCTest

final class FeedLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Feed"
        let bundle = EssentialFeed.bundle
        
        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }
}
