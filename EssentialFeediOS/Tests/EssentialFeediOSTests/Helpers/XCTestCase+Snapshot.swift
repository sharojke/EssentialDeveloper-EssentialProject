import XCTest

extension XCTestCase {
    func record(
        snapshot: UIImage,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let snapshotURL = makeSnapshotURL(named: name, file: file)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)
        
        do {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try snapshotData?.write(to: snapshotURL)
            XCTFail(
                "Record succeeded! Use `assert` to compare the snapshot from now on.",
                file: file,
                line: line
            )
        } catch {
            XCTFail(
                "Failed to record a snapshot with an error \(error)",
                file: file,
                line: line
            )
        }
    }
    
    func assert(
        snapshot: UIImage,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let snapshotURL = makeSnapshotURL(named: name, file: file)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)
        guard let storedSnapshotData = try? Data(contentsOf: snapshotURL) else {
            XCTFail(
                "Failed to load stored snapshot at URL \(snapshotURL). Use the record method to store the snapshot before asserting",
                file: file,
                line: line
            )
            return
        }
        guard storedSnapshotData != snapshotData else { return }
        
        let temporarySnapshotURL = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        ).appendingPathComponent(snapshotURL.lastPathComponent)
        try? snapshotData?.write(to: temporarySnapshotURL)
        
        XCTFail(
            "New snapshot does not match stored snapshot. New snapshot URL: \(temporarySnapshotURL). Stored snapshot URL: \(snapshotURL)",
            file: file,
            line: line
        )
    }
    
    func makeSnapshotData(
        for snapshot: UIImage,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Data? {
        guard let data = snapshot.pngData() else {
            XCTFail(
                "Expected to generate PNG data representation form snapshot",
                file: file,
                line: line
            )
            return nil
        }
        
        return data
    }
    
    private func makeSnapshotURL(named name: String, file: StaticString) -> URL {
        let snapshotsFolderURL = URL(fileURLWithPath: String(describing: file))
            .deletingLastPathComponent()
            .appendingPathComponent("snapshots", isDirectory: true)
        return snapshotsFolderURL
            .appendingPathComponent("\(name).png")
    }
}
