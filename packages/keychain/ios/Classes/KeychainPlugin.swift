import Flutter
import UIKit
import Security

public class KeychainPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "web5.keychain", binaryMessenger: registrar.messenger())
    let instance = KeymasterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as! Dictionary<String, Any>
      
    switch call.method {
    case "delete":
        guard let key = arguments["key"] as? String else {
            result(nil)
            return
        }
        
        let success = Keychain.deleteKeychainValue(key: key)
        result(success)
    case "fetch":
        guard let key = arguments["key"] as? String else {
            result(nil)
            return
        }
        
        let res = Keychain.fetchKeychainValue(key: key)
        result(res)
    case "set":
        guard let key = arguments["key"] as? String, let data = arguments["value"] as? String else {
            result(nil)
            return
        }
        
        let res = Keychain.fetchKeychainValue(key: key)
        
        if (res == nil) {
            let success = Keychain.setKeychainValue(key: key, value: data)
            result(success)
        } else {
            let success = Keychain.updateKeychainValue(key: key, value: data)
            result(success)
        }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

class Keychain {
    public static func deleteKeychainValue(key: String) -> Bool {
        let bundleID: String = Bundle.main.bundleIdentifier ?? "keymaster"
        let account = "\(bundleID).\(key)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
        ]
        
        if SecItemDelete(query as CFDictionary) == noErr {
            return true
        }
        
        return false
    }
    
    public static func fetchKeychainValue(key: String) -> String? {
        let bundleID: String = Bundle.main.bundleIdentifier ?? "keymaster"
        let account = "\(bundleID).\(key)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
        ]
        
        var item: CFTypeRef?
        
        if SecItemCopyMatching(query as CFDictionary, &item) == noErr {
            if let keychainItem = item as? [String: Any], let rawValue = keychainItem[kSecValueData as String] as? Data, let value = String(data: rawValue, encoding: .utf8) {
                return value
            }
            
            return nil
        }
        
        return nil
    }
    
    public static func setKeychainValue(key: String, value: String) -> Bool {
        let bundleID: String = Bundle.main.bundleIdentifier ?? "keymaster"
        let account = "\(bundleID).\(key)"
        
        let data = value.data(using: .utf8)!
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]
        
        let res = SecItemAdd(attributes as CFDictionary, nil)
        
        if res == noErr { return true }
        return false
    }
    
    public static func updateKeychainValue(key: String, value: String) -> Bool {
        let bundleID: String = Bundle.main.bundleIdentifier ?? "keymaster"
        let account = "\(bundleID).\(key)"
        
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
        ]
        
        let attributes: [String: Any] = [kSecValueData as String: data]
        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == noErr {
            return true
        }
        
        return false
    }
}