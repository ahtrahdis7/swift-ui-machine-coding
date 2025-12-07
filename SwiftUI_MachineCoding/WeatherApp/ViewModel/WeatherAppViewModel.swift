//
//  WeatherAppViewModel.swift
//  SwiftUI_MachineCoding
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import Combine
import Foundation

protocol WeatherAppViewModelProtocol: ObservableObject {}

@MainActor
class WeatherAppViewModel: WeatherAppViewModelProtocol {
    @Published var temperature: String = ""
    @Published var loading = true
    @Published var error: WeatherError?
    @Published var searchCity: String = ""
    @Published var weatherInfo: WeatherResponse?
    @Published var isUsingLocation: Bool = true
    
    private let repository: WeatherAppRepositoryProtocol
    private let locationService: LocationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentLocationSubscription: AnyCancellable?
    private var currentCitySubscription: AnyCancellable?
    
    init(repository: WeatherAppRepositoryProtocol, locationService: LocationServiceProtocol) {
        self.repository = repository
        self.locationService = locationService
        loadLocationWeather()
    }
    
    convenience init() {
        self.init(repository: WeatherAppRepository(), locationService: LocationService())
    }
    
    func loadLocationWeather() {
        // Cancel any existing subscriptions
        currentLocationSubscription?.cancel()
        currentCitySubscription?.cancel()
        isUsingLocation = true
        loading = true
        error = nil
        
        Task {
            let permissionStatus = await locationService.requestLocationPermission()
            if permissionStatus {
                do {
                    let (lat, long) = try await locationService.getCurrentLocation()
                    currentLocationSubscription = repository.getCurrentWeather(latitude: lat, longitude: long, forceRefresh: true)
                        .sink(receiveCompletion: { [weak self] completion in
                            guard let self = self else { return }
                            switch completion {
                            case .finished:
                                break
                            case .failure(let failure):
                                self.error = .networkError(NSError(domain: failure.localizedDescription, code: 101))
                                self.loading = false
                            }
                        }) { [weak self] weatherInfo in
                            guard let self = self else { return }
                            self.weatherInfo = weatherInfo
                            self.temperature = "\(Int(weatherInfo.main.temp))"
                            self.loading = false
                        }
                } catch {
                    self.error = .locationError(error)
                    self.loading = false
                }
            } else {
                error = .locationError(NSError(domain: "Location", code: 100))
                loading = false
            }
        }
    }
    
    func searchWeatherByCity(_ cityName: String) {
        guard !cityName.trimmingCharacters(in: .whitespaces).isEmpty else {
            // If empty, switch back to location
            loadLocationWeather()
            return
        }
        
        // Cancel location subscription
        currentLocationSubscription?.cancel()
        currentCitySubscription?.cancel()
        isUsingLocation = false
        loading = true
        error = nil
        
        currentCitySubscription = repository.getCurrentWeatherByCity(cityName, forceRefresh: true)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    break
                case .failure(let failure):
                    self.error = .networkError(NSError(domain: failure.localizedDescription, code: 101))
                    self.loading = false
                }
            }) { [weak self] weatherInfo in
                guard let self = self else { return }
                self.weatherInfo = weatherInfo
                self.temperature = "\(Int(weatherInfo.main.temp))"
                self.loading = false
            }
    }
    
    deinit {
        cancellables.removeAll()
        currentLocationSubscription?.cancel()
        currentCitySubscription?.cancel()
    }
}
