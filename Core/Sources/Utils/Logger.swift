//
//  Logger.swift
//  Core
//
//  Created by 노우영 on 7/4/25.
//  Copyright © 2025 Page. All rights reserved.
//

import Foundation
import os

public enum LogCategory: String {
    case general
    case network
    case auth
    case database
}

public struct Logger {

    static func log(_ message: String,
                    category: LogCategory = .general,
                    type: OSLogType = .default,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {

        let log = OSLog(
            subsystem: Bundle.main.bundleIdentifier ?? "com.page.app",
            category: category.rawValue
        )

        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        os_log("%{public}@ [%{public}@:%d] %{public}@",
               log: log,
               type: type,
               fileName,
               function,
               line,
               message)
        #endif
    }

    public static func debug(_ message: String,
                      category: LogCategory = .general,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        log(message, category: category, type: .debug, file: file, function: function, line: line)
    }

    public static func info(_ message: String,
                     category: LogCategory = .general,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        log(message, category: category, type: .info, file: file, function: function, line: line)
    }

    public static func error(_ message: String,
                      category: LogCategory = .general,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        log(message, category: category, type: .error, file: file, function: function, line: line)
    }
}
