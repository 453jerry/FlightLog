//
//  FileHandleFactory.swift
//  
//
//  Created by Jerry on 2022/10/11.
//

import Foundation

class FileHandleFactory {
    func create(forWritingAtPath path: String) -> FileHandle? {
        FileHandle.init(forWritingAtPath: path)
    }
}
