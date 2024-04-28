extension HTTPURLResponse {
    private static let OK_200 = 200
    
    var isOK: Bool {
        return statusCode == Self.OK_200
    }
}
