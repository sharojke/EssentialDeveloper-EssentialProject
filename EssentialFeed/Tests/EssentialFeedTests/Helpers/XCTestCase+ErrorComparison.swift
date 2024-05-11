import XCTest

extension XCTestCase {
    func compare(
        error error1: NSError?,
        with error2: NSError?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            error1?.domain,
            error2?.domain,
            file: file,
            line: line
        )
        XCTAssertEqual(
            error1?.code,
            error2?.code,
            file: file,
            line: line
        )
    }
}
