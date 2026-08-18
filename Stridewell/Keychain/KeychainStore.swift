//
//  KeychainStore.swift
//  Stridewell
//

import Foundation
import Security

enum KeychainStore {

    private static let service = "app.stridewell"

    // MARK: - Token

    @discardableResult
    static func saveToken(_ token: String) -> Bool {
        delete(key: "jwt")
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "jwt",
            kSecValueData:   data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func loadToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "jwt",
            kSecReturnData:  kCFBooleanTrue as Any,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    @discardableResult
    static func deleteToken() -> Bool {
        delete(key: "jwt")
    }

    // MARK: - Refresh Token

    @discardableResult
    static func saveRefreshToken(_ token: String) -> Bool {
        delete(key: "refresh_token")
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "refresh_token",
            kSecValueData:   data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func loadRefreshToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "refresh_token",
            kSecReturnData:  kCFBooleanTrue as Any,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    @discardableResult
    static func deleteRefreshToken() -> Bool {
        delete(key: "refresh_token")
    }

    // MARK: - Access Token Expiry

    @discardableResult
    static func saveAccessTokenExpiry(_ expiresAtEpochSeconds: Int) -> Bool {
        delete(key: "access_token_expires_at")
        let data = Data(String(expiresAtEpochSeconds).utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "access_token_expires_at",
            kSecValueData:   data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func loadAccessTokenExpiry() -> Int? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "access_token_expires_at",
            kSecReturnData:  kCFBooleanTrue as Any,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8),
              let expiresAt = Int(string)
        else { return nil }
        return expiresAt
    }

    @discardableResult
    static func deleteAccessTokenExpiry() -> Bool {
        delete(key: "access_token_expires_at")
    }

    // MARK: - User ID

    @discardableResult
    static func saveUserId(_ userId: String) -> Bool {
        delete(key: "user_id")
        let data = Data(userId.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "user_id",
            kSecValueData:   data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func loadUserId() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "user_id",
            kSecReturnData:  kCFBooleanTrue as Any,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    @discardableResult
    static func deleteUserId() -> Bool {
        delete(key: "user_id")
    }

    // MARK: - Clear all

    static func clearAll() {
        deleteToken()
        deleteRefreshToken()
        deleteAccessTokenExpiry()
        deleteUserId()
    }

    // MARK: - Private

    @discardableResult
    private static func delete(key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
