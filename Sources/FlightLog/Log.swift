//
//  Log.swift
//  
//
//  Created by Jerry on 2022/10/14.
//

import Foundation

public enum Log: UInt8 {
    
    case debug = 0x01
    case info = 0x02
    case warning = 0x04
    case error = 0x08

    var prefix: String {
        if self == .debug {
            return "🔍"
        }
        if self == .info {
            return "💬"
        }
        if self == .warning {
            return "⚠️"
        }
        return "❌"
    }

    public func write(
        _ content: String
    ) {
        if Self.ignorLevelValue & self.rawValue == 0 {
            if Log.outputMethod == .print {
                print("\(self.prefix) \(content)")
            } else {
                NSLog("\(self.prefix) \(content)")
            }
        }
    }
    
    static var ignorLevelValue: UInt8 = 0x0

    public static func setIngore(levels: [Log]) {
        ignorLevelValue = 0x0
        for level in levels {
            ignorLevelValue |= level.rawValue
        }
    }
    
    public static var outputMethod: OutputMethod = .print
    
    /// 记录日志
    ///
    /// debug 日志添加🔍前缀，且编译Flag中包含DEBUG标志是输出。
    /// info 日志添加💬前缀
    /// warning 日志添加⚠️前缀
    /// error 日志添加❌前缀
    ///
    /// - Parameter message: 日志内容
    /// - Parameter level: 日志等级
    /// - Parameter method: 日志输出方式
    
    /// 日志输出方式
    public enum OutputMethod {
        /// 通过pirnt() 方法输出日志
        case print
        
        /// 通过NSLog输出日志
        case nslog
    }
}
