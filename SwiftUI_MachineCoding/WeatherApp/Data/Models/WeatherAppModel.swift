//
//  WeatherAppModel.swift
//  SwiftUI_MachineCoding
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import Foundation

// MARK: - WeatherCache
/// Cache model for storing weather data in UserDefaults
struct WeatherCache: Codable {
    let timestamp: Date
    let weatherResponse: WeatherResponse
    
    init(timestamp: Date = Date(), weatherResponse: WeatherResponse) {
        self.timestamp = timestamp
        self.weatherResponse = weatherResponse
    }
}

// MARK: - WeatherResponse
/// Response model matching OpenWeatherMap Current Weather API
struct WeatherResponse: Codable {
    let coord: Coord
    let weather: [Weather]
    let base: String
    let main: Main
    let visibility: Int?
    let wind: Wind?
    let clouds: Clouds?
    let dt: Int
    let sys: Sys
    let timezone: Int?
    let id: Int?
    let name: String
    let cod: Int?
}

// MARK: - Coord
struct Coord: Codable {
    let lon: Double
    let lat: Double
}

// MARK: - Weather
struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

// MARK: - Main
struct Main: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int?
    let humidity: Int?
    let seaLevel: Int?
    let grndLevel: Int?
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
    }
}

// MARK: - Wind
struct Wind: Codable {
    let speed: Double?
    let deg: Int?
    let gust: Double?
}

// MARK: - Clouds
struct Clouds: Codable {
    let all: Int
}

// MARK: - Sys
struct Sys: Codable {
    let type: Int?
    let id: Int?
    let country: String?
    let sunrise: Int?
    let sunset: Int?
}

// MARK: - WeatherError
enum WeatherError: Error, LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case invalidAPIKey
    case cacheNotFound
    case locationError(Error)
    case invalidResponse
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidAPIKey:
            return "Invalid API key"
        case .cacheNotFound:
            return "No cached weather data found"
        case .locationError(let error):
            return "Location error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
