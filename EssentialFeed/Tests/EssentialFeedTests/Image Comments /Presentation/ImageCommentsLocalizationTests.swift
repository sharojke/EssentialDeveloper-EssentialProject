import EssentialFeed
import XCTest

final class ImageCommentsLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "ImageComments"
        let bundle = EssentialFeed.bundle
        
        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }
}
