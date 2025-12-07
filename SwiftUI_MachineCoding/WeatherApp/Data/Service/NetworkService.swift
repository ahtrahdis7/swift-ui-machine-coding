//
//  NetworkService.swift
//  SwiftUI_MachineCoding
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import Foundation

protocol NetworkServiceProtocol {
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse
    func fetchCurrentWeatherByCity(_ cityName: String) async throws -> WeatherResponse
}

class NetworkService: NetworkServiceProtocol {
    private let apiKeyService: API_KeyServiceProtocol
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    init(apiKeyService: API_KeyServiceProtocol = API_KeyService()) {
        self.apiKeyService = apiKeyService
    }
    
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
        let apiKey = try apiKeyService.getAPIKey()
        let urlString = "\(baseURL)?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.networkError(NSError(domain: "Network", code: (response as? HTTPURLResponse)?.statusCode ?? 0))
        }
        
        do {
            let decoder = JSONDecoder()
            let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
            return weatherResponse
        } catch {
            throw WeatherError.decodingError(error)
        }
    }
    
    func fetchCurrentWeatherByCity(_ cityName: String) async throws -> WeatherResponse {
        let apiKey = try apiKeyService.getAPIKey()
        let encodedCityName = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cityName
        let urlString = "\(baseURL)?q=\(encodedCityName)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.networkError(NSError(domain: "Network", code: (response as? HTTPURLResponse)?.statusCode ?? 0))
        }
        
        do {
            let decoder = JSONDecoder()
            let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
            return weatherResponse
        } catch {
            throw WeatherError.decodingError(error)
        }
    }
}
