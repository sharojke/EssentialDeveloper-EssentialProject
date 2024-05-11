import EssentialFeed
import XCTest

private final class DummyView: ResourceView {
    func display(_ viewModel: Any) {}
}

final class SharedLocalizationTests: XCTestCase {
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "Shared"
        let bundle = EssentialFeed.bundle
        
        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }
}
