import CoreData
import XCTest

extension NSEntityDescription {
    func verify(
        attribute name: String,
        hasType type: NSAttributeType,
        isOptional: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let attribute = attributesByName[name] else {
            return XCTFail(
                "Missing expected attribute \(name)",
                file: file,
                line: line
            )
        }

        guard let property = propertiesByName[name] else {
            return XCTFail(
                "Missing expected property \(name)",
                file: file,
                line: line
            )
        }

        XCTAssertEqual(
            attribute.attributeType,
            type,
            "attributeType",
            file: file,
            line: line
        )
        XCTAssertEqual(
            property.isOptional,
            isOptional,
            "isOptional",
            file: file,
            line: line
        )
    }
}
