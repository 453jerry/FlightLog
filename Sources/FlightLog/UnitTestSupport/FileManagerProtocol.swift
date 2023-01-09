//
//  FileManagerProtocol.swift
//  
//
//  Created by Jerry on 2022/10/11.
//

import Foundation

// swiftlint: disable discouraged_optional_collection
protocol FileManagerProtocol {
    func createDirectory(
        atPath path: String,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws

    func createFile(
        atPath path: String,
        contents data: Data?,
        attributes attr: [FileAttributeKey: Any]?
    ) -> Bool
}

extension FileManager: FileManagerProtocol {}
