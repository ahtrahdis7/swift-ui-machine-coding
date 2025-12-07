//
//  API_KeyService.swift
//  SwiftUI_MachineCoding
//
//  Created by Sidhartha Mallick on 07/12/25.
//

import Foundation
import Security

protocol API_KeyServiceProtocol {
    func getAPIKey() throws -> String
    func saveAPIKey(_ key: String) throws
    func hasAPIKey() -> Bool
}

class API_KeyService: API_KeyServiceProtocol {
    private let service = "com.weatherApp.apiKey"
    private let account = "openWeatherAPIKey"
    
    func getAPIKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw WeatherError.invalidAPIKey
        }
        
        return apiKey
    }
    
    func saveAPIKey(_ key: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw WeatherError.invalidAPIKey
        }
        
        // Delete existing key if any
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new key
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw WeatherError.invalidAPIKey
        }
    }
    
    func hasAPIKey() -> Bool {
        do {
            _ = try getAPIKey()
            return true
        } catch {
            return false
        }
    }
}
