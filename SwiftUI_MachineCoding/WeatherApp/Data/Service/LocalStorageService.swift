//
//  LocalStorageService.swift.swift
//  SwiftUI_MachineCoding
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import Foundation

protocol LocalStorageServiceProtocol {
    func saveCurrentWeather(_ weather: WeatherResponse, timestamp: Date) throws
    func getCurrentWeather() throws -> WeatherCache?
    func clearCache() throws
    func isDataStale(maxAgeInMinutes: Int) -> Bool
}

class LocalStorageService: LocalStorageServiceProtocol {
    private let userDefaults: UserDefaults
    private let cacheKey = "weatherCache"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveCurrentWeather(_ weather: WeatherResponse, timestamp: Date) throws {
        let cache = WeatherCache(timestamp: timestamp, weatherResponse: weather)
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(cache)
            userDefaults.set(data, forKey: cacheKey)
        } catch {
            throw WeatherError.decodingError(error)
        }
    }
    
    func getCurrentWeather() throws -> WeatherCache? {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            let cache = try decoder.decode(WeatherCache.self, from: data)
            return cache
        } catch {
            throw WeatherError.decodingError(error)
        }
    }
    
    func clearCache() throws {
        userDefaults.removeObject(forKey: cacheKey)
    }
    
    func isDataStale(maxAgeInMinutes: Int) -> Bool {
        guard let cache = try? getCurrentWeather() else {
            return true
        }
        
        let maxAge = TimeInterval(maxAgeInMinutes * 60)
        let age = Date().timeIntervalSince(cache.timestamp)
        return age > maxAge
    }
}
