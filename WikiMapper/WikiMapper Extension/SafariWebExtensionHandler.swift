import SafariServices
import os.log
import Foundation

let SFExtensionMessageKey = "message"

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    
    private let userDefaults = UserDefaults(suiteName: "group.wikimapper.storage") ?? UserDefaults.standard
    
    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems[0] as! NSExtensionItem
        guard let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any] else {
            self.sendResponse(context: context, data: ["error": "Invalid message format"])
            return
        }
        
        os_log(.default, "WikiMapper: Received message from extension: %@", String(describing: message))
        
        guard let action = message["action"] as? String else {
            self.sendResponse(context: context, data: ["error": "Missing action"])
            return
        }
        
        switch action {
        case "set":
            handleSetStorage(message: message, context: context)
        case "get":
            handleGetStorage(message: message, context: context)
        case "remove":
            handleRemoveStorage(message: message, context: context)
        case "clear":
            handleClearStorage(context: context)
        case "getBytesInUse":
            handleGetBytesInUse(context: context)
        default:
            self.sendResponse(context: context, data: ["error": "Unknown action: \(action)"])
        }
    }
    
    private func handleSetStorage(message: [String: Any], context: NSExtensionContext) {
        guard let data = message["data"] as? [String: Any] else {
            self.sendResponse(context: context, data: ["error": "Missing data for set operation"])
            return
        }
        
        for (key, value) in data {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                userDefaults.set(jsonData, forKey: "wikimapper_\(key)")
                os_log(.default, "WikiMapper: Stored data for key: %@", key)
            } catch {
                os_log(.error, "WikiMapper: Failed to serialize data for key %@: %@", key, error.localizedDescription)
                self.sendResponse(context: context, data: ["error": "Failed to serialize data for key \(key)"])
                return
            }
        }
        
        userDefaults.synchronize()
        self.sendResponse(context: context, data: ["success": true])
    }
    
    private func handleGetStorage(message: [String: Any], context: NSExtensionContext) {
        let keys = message["keys"] as? [String]
        var result: [String: Any] = [:]
        
        if let keys = keys {
            // Get specific keys
            for key in keys {
                if let data = userDefaults.data(forKey: "wikimapper_\(key)") {
                    do {
                        let value = try JSONSerialization.jsonObject(with: data, options: [])
                        result[key] = value
                    } catch {
                        os_log(.error, "WikiMapper: Failed to deserialize data for key %@: %@", key, error.localizedDescription)
                    }
                }
            }
        } else {
            // Get all keys
            let allKeys = userDefaults.dictionaryRepresentation().keys
            for fullKey in allKeys {
                if fullKey.hasPrefix("wikimapper_") {
                    let key = String(fullKey.dropFirst("wikimapper_".count))
                    if let data = userDefaults.data(forKey: fullKey) {
                        do {
                            let value = try JSONSerialization.jsonObject(with: data, options: [])
                            result[key] = value
                        } catch {
                            os_log(.error, "WikiMapper: Failed to deserialize data for key %@: %@", key, error.localizedDescription)
                        }
                    }
                }
            }
        }
        
        self.sendResponse(context: context, data: ["result": result])
    }
    
    private func handleRemoveStorage(message: [String: Any], context: NSExtensionContext) {
        guard let keys = message["keys"] as? [String] else {
            self.sendResponse(context: context, data: ["error": "Missing keys for remove operation"])
            return
        }
        
        for key in keys {
            userDefaults.removeObject(forKey: "wikimapper_\(key)")
            os_log(.default, "WikiMapper: Removed data for key: %@", key)
        }
        
        userDefaults.synchronize()
        self.sendResponse(context: context, data: ["success": true])
    }
    
    private func handleClearStorage(context: NSExtensionContext) {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix("wikimapper_") {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        userDefaults.synchronize()
        os_log(.default, "WikiMapper: Cleared all storage")
        self.sendResponse(context: context, data: ["success": true])
    }
    
    private func handleGetBytesInUse(context: NSExtensionContext) {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        var totalBytes = 0
        
        for key in allKeys {
            if key.hasPrefix("wikimapper_") {
                if let data = userDefaults.data(forKey: key) {
                    totalBytes += data.count
                }
            }
        }
        
        self.sendResponse(context: context, data: ["bytesInUse": totalBytes])
    }
    
    private func sendResponse(context: NSExtensionContext, data: [String: Any]) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: data]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
