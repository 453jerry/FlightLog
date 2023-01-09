//
//  LogRecorderTests.swift
//
//
//  Created by Jerry on 2022/10/3.
//

@testable import FlightLog
import XCTest

final class LogRecorderTests: XCTestCase {

    private var originStdOutFileDescriptor: Int32 = STDOUT_FILENO
    private var originStdErrFileDescriptor: Int32 = STDERR_FILENO
    private var testRecorder = LogRecorder.shared
    
    override func setUp() {
        self.originStdOutFileDescriptor = dup(STDOUT_FILENO)
        self.originStdErrFileDescriptor = dup(STDERR_FILENO)
        self.testRecorder = LogRecorder.init()
        self.testRecorder.fileHandleFactory = StubFileHandleFactory.init()
        self.testRecorder.fileManager = StubFileManager.init()
    }
    
    override func tearDown() {
        dup2(self.originStdErrFileDescriptor, STDERR_FILENO)
        dup2(self.originStdOutFileDescriptor, STDOUT_FILENO)
        close(originStdOutFileDescriptor)
        close(originStdErrFileDescriptor)
        
        try? FileManager.default.removeItem(
            atPath: testRecorder.rootPath
        )
        
        testRecorder = LogRecorder.shared
    }
    
    // swiftlint: disable force_unwrapping
    func testRootDirecotry() {
        let stubBundle = FakeBundle.init(fakeBundleID: "test_bundle_id")
        self.testRecorder = LogRecorder.init(mainBundle: stubBundle)
        
        let rootPaht = testRecorder.rootPath
        
        let cachesPath = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory, .userDomainMask, true
        ).first!
        let expected = "\(cachesPath)/\(stubBundle.bundleIdentifier!)/FlightLog"
        XCTAssertEqual(rootPaht, expected)
    }
    
    func testRecord_ReturnLogPath() {
        let logPath = self.testRecorder.record()

        let logName = LogRecorder.getProcessStartDate().toISO6801String()
        XCTAssertEqual(
            logPath,
            "\(self.testRecorder.rootPath)/\(logName)/\(logName).log"
        )
    }

    func testRecord_CreateLogFileAtLogPath() {
        class MockFileManager: StubFileManager {
            var createLogExpectation: XCTestExpectation
            
            init(createLogExpectation: XCTestExpectation) {
                self.createLogExpectation = createLogExpectation
            }
            
            var pathOfCreatedFile: String?
            // swiftlint: disable discouraged_optional_collection
            override func createFile(
                atPath path: String,
                contents data: Data?,
                attributes attr: [FileAttributeKey: Any]?
            ) -> Bool {
                self.pathOfCreatedFile = path
                self.createLogExpectation.fulfill()
                return false
            }
        }
        let mockFileManager = MockFileManager.init(
            createLogExpectation: expectation(description: "Create log file")
        )
        mockFileManager.createLogExpectation.expectedFulfillmentCount = 1
        self.testRecorder.fileManager = mockFileManager

        let logPath = self.testRecorder.record()
        
        waitForExpectations(timeout: 0)
        XCTAssertEqual(logPath, mockFileManager.pathOfCreatedFile)
    }
    
    func testRecord_ReturnNilWhenCreateLogFileHandleFailed() {
        class StubFileHandleFacotry: FileHandleFactory {
            override func create(forWritingAtPath path: String) -> FileHandle? {
                nil
            }
        }
        self.testRecorder.fileHandleFactory = StubFileHandleFacotry()

        let logPath = self.testRecorder.record()
        
        XCTAssertNil(logPath)
    }
    
    func testRecord_CreateFileHandleAtLogPath() {
        class MockFileHandleFacotry: StubFileHandleFactory {
            var pathOfFileHandle: String?

            override func create(forWritingAtPath path: String) -> FileHandle? {
                self.pathOfFileHandle = path
                return super.create(forWritingAtPath: path)
            }
        }
        let mockFileHandleFactory = MockFileHandleFacotry()
        self.testRecorder.fileHandleFactory = mockFileHandleFactory

        let logPath = self.testRecorder.record()
        
        XCTAssertEqual(logPath, mockFileHandleFactory.pathOfFileHandle)
    }
    
    func testRecord_WriteHeader() {
        let mockFileHandleFactory = MockFileHandleFactory()
        mockFileHandleFactory.writeExpectation = expectation(
            description: "Wirte log header"
        )
        mockFileHandleFactory.writeExpectation?.expectedFulfillmentCount = 1
        self.testRecorder.fileHandleFactory = mockFileHandleFactory
        
        _ = self.testRecorder.record()
        
        waitForExpectations(timeout: 0)
        let logName = LogRecorder.getProcessStartDate().toISO6801String()
        XCTAssertEqual(
            mockFileHandleFactory.writedString,
            "============= FlightLog.LogRecorder \(logName) =============\n"
        )
    }
    
    func testNSLog_WriteLogToFile() {
        let mockFileHandleFactory = MockFileHandleFactory()
        self.testRecorder.fileHandleFactory = mockFileHandleFactory
        _ = self.testRecorder.record()
        
        NSLog("Test_NSLog")
        
        XCTAssertTrue(
            mockFileHandleFactory.writedString.hasSuffix("Test_NSLog\n")
        )
    }
    
    func testPrint_WriteLogToFile() {
        let mockFileHandleFactory = MockFileHandleFactory()
        self.testRecorder.fileHandleFactory = mockFileHandleFactory
        _ = self.testRecorder.record()
        
        print("Test_Print")
        
        sleep(1)
        XCTAssertTrue(
            mockFileHandleFactory.writedString.hasSuffix("Test_Print\n")
        )
    }
    
    private class FakeBundle: Bundle {
        init(fakeBundleID: String) {
            self.bundleID = fakeBundleID
            super.init(path: Self.main.bundlePath)!
        }
        
        var bundleID: String = ""
        override var bundleIdentifier: String? {
            self.bundleID
        }
    }
    
    private class StubFileHandleFactory: FileHandleFactory {
        let stdOutFileHandle: FileHandle

        override init() {
            let stdOutFd = dup(FileHandle.standardOutput.fileDescriptor)
            self.stdOutFileHandle = FileHandle(fileDescriptor: stdOutFd)
        }
        
        deinit {
            close(self.stdOutFileHandle.fileDescriptor)
        }
        
        override func create(
            forWritingAtPath path: String
        ) -> FileHandle? {
            self.stdOutFileHandle
        }
    }
    
    private class MockFileHandleFactory: StubFileHandleFactory {
        private let pipe = Pipe()
        
        var writedString: String = ""
        var writeExpectation: XCTestExpectation?

        override func create(forWritingAtPath path: String) -> FileHandle? {
            let handle = super.create(forWritingAtPath: path)
            self.pipe.fileHandleForReading
                .readabilityHandler = { [weak self] readHandle in
                let data = readHandle.availableData
                if #available(iOS 13.4, macOS 10.15.4, *) {
                    try? handle?.write(contentsOf: data)
                } else {
                    handle?.write(data)
                }
                self?.writedString += String.init(
                    data: data,
                    encoding: .utf8
                ) ?? ""
            }
            self.writeExpectation?.fulfill()
            return pipe.fileHandleForWriting
        }
    }
    
    // swiftlint: disable discouraged_optional_collection
    private class StubFileManager: FileManagerProtocol {
        func createFile(
            atPath path: String,
            contents data: Data?,
            attributes attr: [FileAttributeKey: Any]?
        ) -> Bool { true }
        
        func createDirectory(
            atPath path: String,
            withIntermediateDirectories createIntermediates: Bool,
            attributes: [FileAttributeKey: Any]?
        ) throws { }
    }
}
