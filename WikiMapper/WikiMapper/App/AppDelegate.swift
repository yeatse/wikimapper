//
//  AppDelegate.swift
//  WikiMapper (macOS)
//
//  Created by Yeatse on 2025/7/20.
//

#if os(macOS)
import Foundation
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
#endif
