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
        self.rootPath = ""
    }
    
    
    public func record() -> String? {
        return ""
    }
}
