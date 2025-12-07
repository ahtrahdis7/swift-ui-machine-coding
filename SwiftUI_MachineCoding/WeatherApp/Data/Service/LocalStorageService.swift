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

//class LocalStorageService: LocalStorageServiceProtocol {
//    func saveCurrentWeather(_ weather: WeatherResponse, timestamp: Date) throws {
//        //
//    }
//    
//    func getCurrentWeather() throws -> WeatherCache? {
//        //
//    }
//    
//    func clearCache() throws {
//        //
//    }
//    
//    func isDataStale(maxAgeInMinutes: Int) -> Bool {
//        //
//    }
//}
