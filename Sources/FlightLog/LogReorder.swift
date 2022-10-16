//
//  LogRecorder.swift
//  
//
//  Created by Jerry Huang on 2022/9/16.
//

import Foundation

public class LogRecorder {
    public static let shared = LogRecorder()
    
    public let rootPath: String
    
    init(mainBundle: Bundle = Bundle.main) {
        // swiftlint:disable force_unwrapping
        let cachesPath = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory, .userDomainMask, true
        ).first!
        self.rootPath =
        "\(cachesPath)/\(mainBundle.bundleIdentifier!)/FlightLog"
    }
    
    var fileHandleFactory = FileHandleFactory.init()
    var fileManager: FileManagerProtocol = FileManager.default
    var logFilePath: String?
    
    public func record() -> String? {
        if let logFilePath = self.logFilePath {
            return logFilePath
        }

        let logName: String = LogRecorder.getProcessStartDate().toISO6801String()
        let directoryPath = "\(self.rootPath)/\(logName)"
        let filePath: String = "\(directoryPath)/\(logName).log"

        try? self.fileManager.createDirectory(
            atPath: directoryPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        _ = self.fileManager.createFile(
            atPath: filePath,
            contents: nil,
            attributes: nil
        )
        guard let logFileHandle = self.fileHandleFactory.create(
            forWritingAtPath: filePath
        ) else {
            return nil
        }

        if #available(iOS 13.4, macOS 10.15.4, *) {
            _ = try? logFileHandle.seekToEnd()
        } else {
            logFileHandle.seekToEndOfFile()
        }

        let header =
        "============= FlightLog.LogRecorder \(logName) =============\n"
        if let data = header.data(using: .utf8) {
            if #available(iOS 13.4, macOS 10.15.4, *) {
                try? logFileHandle.write(contentsOf: data)
            } else {
                logFileHandle.write(data)
            }
        }

        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
        dup2(logFileHandle.fileDescriptor, STDOUT_FILENO)
        dup2(logFileHandle.fileDescriptor, STDERR_FILENO)

        self.logFilePath = filePath
        return filePath
    }
}
