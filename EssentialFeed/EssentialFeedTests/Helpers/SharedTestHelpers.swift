import Foundation

// swiftlint:disable force_unwrapping

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

// swiftlint:enable force_unwrapping
