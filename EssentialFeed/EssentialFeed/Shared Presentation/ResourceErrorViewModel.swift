public struct ResourceErrorViewModel {
    static var noError: Self {
        return Self(message: nil)
    }

    public let message: String?
    
    static func error(message: String) -> Self {
        return Self(message: message)
    }
}
