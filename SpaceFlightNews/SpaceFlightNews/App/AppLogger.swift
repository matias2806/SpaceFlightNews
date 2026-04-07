// App/AppLogger.swift
// Centralized logger using os.Logger (Console.app compatible).
// Never use print() directly — always go through AppLogger.
// Logs appear in Xcode console and Console.app filtered by subsystem.

import OSLog

enum AppLogger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.SpaceFlightNews"

    private static let networkLogger  = Logger(subsystem: subsystem, category: "Network")
    private static let uiLogger       = Logger(subsystem: subsystem, category: "UI")
    private static let generalLogger  = Logger(subsystem: subsystem, category: "General")

    // MARK: - Network

    static func networkError(_ error: AppError, context: String = #function) {
        networkLogger.error("[\(context)] \(error.debugDescription)")
    }

    static func networkInfo(_ message: String, context: String = #function) {
        networkLogger.info("[\(context)] \(message)")
    }

    // MARK: - UI

    static func uiError(_ error: AppError, context: String = #function) {
        uiLogger.error("[\(context)] \(error.debugDescription)")
    }

    // MARK: - General

    static func debug(_ message: String, context: String = #function) {
        generalLogger.debug("[\(context)] \(message)")
    }

    static func info(_ message: String, context: String = #function) {
        generalLogger.info("[\(context)] \(message)")
    }
}
