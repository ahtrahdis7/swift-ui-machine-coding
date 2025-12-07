//
//  NetworkService.swift
//  SwiftUI_MachineCoding
//
//  Created by Sidhartha Mallick on 06/12/25.
//

protocol NetworkServiceProtocol {
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse
}

//class NetworkService: NetworkServiceProtocol {
//    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
//        //
//    }
//}
