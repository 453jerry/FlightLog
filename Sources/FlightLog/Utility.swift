//
//  Utility.swift
//
//
//  Created by Jerry on 2022/9/20.
//

import Foundation

extension Date {
    func toISO6801String() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HHmmssZ"
        return dateFormatter.string(from: self)
    }
}

extension LogRecorder {
    /// Get the start time of current process
    ///
    /// - Returns: The start time of current process
    public static func getProcessStartDate() -> Date {
        let pid = ProcessInfo.processInfo.processIdentifier
        var mib = [ CTL_KERN, KERN_PROC, KERN_PROC_PID, pid ]
        var proc = kinfo_proc.init()
        var size = MemoryLayout<kinfo_proc>.size
        sysctl(&mib, 4, &proc, &size, nil, 0)
        
        return Date.init(
            timeIntervalSince1970: TimeInterval(proc.kp_proc.p_starttime.tv_sec)
        )
    }
}
