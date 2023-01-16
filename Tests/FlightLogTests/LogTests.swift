//
//  LogTests.swift
//
//
//  Created by Jerry on 2022/10/17.
//

@testable import FlightLog
import XCTest

final class LogTests: XCTestCase {
    private var originStdOutFileDescriptor: Int32 = STDOUT_FILENO
    private var originStdErrFileDescriptor: Int32 = STDERR_FILENO
    
    override func setUp() {
        self.originStdOutFileDescriptor = dup(STDOUT_FILENO)
        self.originStdErrFileDescriptor = dup(STDERR_FILENO)
    }
    
    override func tearDown() {
        dup2(self.originStdErrFileDescriptor, STDERR_FILENO)
        dup2(self.originStdOutFileDescriptor, STDOUT_FILENO)
        close(originStdOutFileDescriptor)
        close(originStdErrFileDescriptor)
        Log.setIngore(levels: [])
    }
    
    private func testLogWithPring(
        level: Log,
        content: String,
        expectedPrefix: String
    ) {
        let expectation = expectation(description: "Write to STDOUT")
        let pipe = Pipe.init()
        pipe.fileHandleForReading
            .readabilityHandler = { readHandle in
                expectation.fulfill()
                let msg = String.init(
                    data: readHandle.availableData,
                    encoding: .utf8
                )
                XCTAssertEqual("\(expectedPrefix) \(content)\n", msg)
        }
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        
        Log.outputMethod = .print
        level.write(content)
        waitForExpectations(timeout: 1)
    }
    
    func testLogDebugWithPrintMethod() {
        testLogWithPring(
            level: .debug,
            content: "Test_Print_MSg",
            expectedPrefix: "🔍"
        )
    }
    
    func testLogInfoWithPrintMethod() {
        testLogWithPring(
            level: .info,
            content: "Test_Print_MSg",
            expectedPrefix: "💬"
        )
    }
    
    func testLogWarningWithPrintMethod() {
        testLogWithPring(
            level: .warning,
            content: "Test_Print_MSg",
            expectedPrefix: "⚠️"
        )
    }

    func testLogErrorWithPrintMethod() {
        testLogWithPring(
            level: .error,
            content: "Test_Print_MSg",
            expectedPrefix: "❌"
        )
    }
    
    private func testLogWithNSLog(
        level: Log,
        content: String,
        expectedPrefix: String
    ) {
        let expectation = expectation(description: "Write to STDOUT")
        let pipe = Pipe.init()
        let origin: Int32 = dup(STDERR_FILENO)
        pipe.fileHandleForReading
            .readabilityHandler = { readHandle in
                dup2(origin, STDERR_FILENO)
                expectation.fulfill()
                let msg = String.init(
                    data: readHandle.availableData,
                    encoding: .utf8
                )
                XCTAssertTrue(msg?.hasSuffix("\(expectedPrefix) \(content)\n") ?? false)
                XCTAssertNotEqual("\(expectedPrefix) \(content)\n", msg)
        }
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        
        Log.outputMethod = .nslog
        level.write(content)
        waitForExpectations(timeout: 1)
    }

    func testLogDebugWithNSLogMethod() {
        testLogWithNSLog(
            level: .debug,
            content: "Test_Print_MSg",
            expectedPrefix: "🔍"
        )
    }

    func testLogInfoWithNSLogMethod() {
        testLogWithNSLog(
            level: .info,
            content: "Test_Print_MSg",
            expectedPrefix: "💬"
        )
    }

    func testLogWarningWithNSLogMethod() {
        testLogWithNSLog(
            level: .warning,
            content: "Test_Print_MSg",
            expectedPrefix: "⚠️"
        )
    }

    func testLogErrorWithNSLogMethod() {
        testLogWithNSLog(
            level: .error,
            content: "Test_Print_MSg",
            expectedPrefix: "❌"
        )
    }

    private func testLogIngoreLevel(
        level: Log,
        ignorLevels: [Log],
        content: String,
        method: Log.OutputMethod
    ) {
        let testMsg = content
        let expectation = expectation(description: "Write to STDOUT")
        expectation.isInverted = true
        let pipe = Pipe.init()
        let originStdErr: Int32 = dup(STDERR_FILENO)
        let originStdOut: Int32 = dup(STDOUT_FILENO)
        pipe.fileHandleForReading
            .readabilityHandler = { readHandle in
                if method == .nslog {
                    dup2(originStdErr, STDERR_FILENO)
                }
                if method == .print {
                    dup2(originStdOut, STDOUT_FILENO)
                }
                expectation.fulfill()
            
                _ = readHandle.readDataToEndOfFile()
        }

        if method == .print {
            dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        }
        if method == .nslog {
            dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        }

        Log.outputMethod = method
        Log.setIngore(levels: ignorLevels)
        level.write(testMsg)
        waitForExpectations(timeout: 1)
    }

    func testLogDebugIngoreLevel() {
        testLogIngoreLevel(
            level: .debug,
            ignorLevels: [.debug, .error, .info, .warning],
            content: "Test Log",
            method: .nslog
        )
        testLogIngoreLevel(
            level: .debug,
            ignorLevels: [.debug, .error, .info, .warning],
            content: "Test Log",
            method: .print
        )
    }

    func testLogInfoIngoreLevel() {
        testLogIngoreLevel(
            level: .info,
            ignorLevels: [.debug, .error, .info, .warning],
            content: "Test Log",
            method: .nslog
        )
        testLogIngoreLevel(
            level: .info,
            ignorLevels: [.debug, .error, .info, .warning],
            content: "Test Log",
            method: .print
        )
    }

    func testErrorInfoIngoreLevel() {
        testLogIngoreLevel(
            level: .error,
            ignorLevels: [.debug, .error, .info, .warning],
            content: "Test Log",
            method: .nslog
        )
        testLogIngoreLevel(
            level: .error,
            ignorLevels: [.debug, .error, .info, .warning],
            content: "Test Log",
            method: .print
        )
    }

    func testLogWarningIngoreLevel() {
        testLogIngoreLevel(
            level: .warning,
            ignorLevels: [.debug, .error, .info, .warning],
            content: "Test Log",
            method: .nslog
        )
        testLogIngoreLevel(
            level: .warning,
            ignorLevels: [.debug, .error, .info, .warning],
            content: "Test Log",
            method: .print
        )
    }
}
