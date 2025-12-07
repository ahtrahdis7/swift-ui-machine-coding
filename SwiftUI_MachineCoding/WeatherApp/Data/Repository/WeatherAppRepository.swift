//
//  WeatherAppRepository.swift
//  SwiftUI_MachineCoding
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import Combine
import Foundation

protocol WeatherAppRepositoryProtocol {
    func getCurrentWeather(latitude: Double, longitude: Double, forceRefresh: Bool) -> AnyPublisher<WeatherResponse, Error>
    func getCurrentWeatherByCity(_ cityName: String, forceRefresh: Bool) -> AnyPublisher<WeatherResponse, Error>
}

class WeatherAppRepository: WeatherAppRepositoryProtocol {
    private var timers: [AnyCancellable] = []
    func getCurrentWeatherByCity(_ cityName: String, forceRefresh: Bool) -> AnyPublisher<WeatherResponse, any Error> {
        // Create a subject that will emit values
        let subject = PassthroughSubject<WeatherResponse, Error>()
        
        // Emit initial value immediately
        subject.send(generateRandomWeatherResponse(cityName: cityName))
        
        // Create timer that emits every 3 seconds
        // Using a weak reference to avoid retain cycles
        var timerCancellable: AnyCancellable?
        timerCancellable = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                let weatherData = self.generateRandomWeatherResponse(cityName: cityName)
                subject.send(weatherData)
            })
        
        // Store timer to keep it alive
        if let timer = timerCancellable {
            timers.append(timer)
        }
        
        // Cancel timer when subscription is cancelled
        return subject
            .handleEvents(receiveCancel: {
                timerCancellable?.cancel()
            })
            .eraseToAnyPublisher()
    }
    
    func getCurrentWeather(latitude: Double, longitude: Double, forceRefresh: Bool) -> AnyPublisher<WeatherResponse, any Error> {
        // Create a subject that will emit values
        let subject = PassthroughSubject<WeatherResponse, Error>()
        
        // Emit initial value immediately
        subject.send(generateRandomWeatherResponse(latitude: latitude, longitude: longitude))
        
        // Create timer that emits every 3 seconds
        // Using a weak reference to avoid retain cycles
        var timerCancellable: AnyCancellable?
        timerCancellable = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                let weatherData = self.generateRandomWeatherResponse(latitude: latitude, longitude: longitude)
                subject.send(weatherData)
            })
        
        // Store timer to keep it alive
        if let timer = timerCancellable {
            timers.append(timer)
        }
        
        // Cancel timer when subscription is cancelled
        return subject
            .handleEvents(receiveCancel: {
                timerCancellable?.cancel()
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func generateRandomWeatherResponse(cityName: String? = nil, latitude: Double? = nil, longitude: Double? = nil) -> WeatherResponse {
        let randomLat = latitude ?? Double.random(in: -90...90)
        let randomLon = longitude ?? Double.random(in: -180...180)
        
        // Random weather conditions
        let weatherConditions = [
            ("Clear", "clear sky", "01d"),
            ("Clouds", "few clouds", "02d"),
            ("Clouds", "scattered clouds", "03d"),
            ("Clouds", "broken clouds", "04d"),
            ("Rain", "light rain", "10d"),
            ("Rain", "moderate rain", "10d"),
            ("Thunderstorm", "thunderstorm", "11d"),
            ("Snow", "light snow", "13d"),
            ("Mist", "mist", "50d")
        ]
        
        let randomCondition = weatherConditions.randomElement()!
        let temp = Double.random(in: -10...40) // Temperature in Celsius
        let feelsLike = temp + Double.random(in: -5...5)
        let tempMin = temp - Double.random(in: 2...8)
        let tempMax = temp + Double.random(in: 2...8)
        
        return WeatherResponse(
            coord: Coord(lon: randomLon, lat: randomLat),
            weather: [
                Weather(
                    id: Int.random(in: 200...804),
                    main: randomCondition.0,
                    description: randomCondition.1,
                    icon: randomCondition.2
                )
            ],
            base: "stations",
            main: Main(
                temp: temp,
                feelsLike: feelsLike,
                tempMin: tempMin,
                tempMax: tempMax,
                pressure: Int.random(in: 980...1050),
                humidity: Int.random(in: 30...90),
                seaLevel: nil,
                grndLevel: nil
            ),
            visibility: Int.random(in: 1000...10000),
            wind: Wind(
                speed: Double.random(in: 0...20),
                deg: Int.random(in: 0...360),
                gust: Double.random(in: 0...30)
            ),
            clouds: Clouds(all: Int.random(in: 0...100)),
            dt: Int(Date().timeIntervalSince1970),
            sys: Sys(
                type: 1,
                id: Int.random(in: 1000...9999),
                country: ["US", "GB", "IN", "CA", "AU", "DE", "FR", "JP"].randomElement(),
                sunrise: Int(Date().timeIntervalSince1970) - Int.random(in: 0...3600),
                sunset: Int(Date().timeIntervalSince1970) + Int.random(in: 0...3600)
            ),
            timezone: Int.random(in: -43200...43200),
            id: Int.random(in: 100000...999999),
            name: cityName ?? ["New York", "London", "Tokyo", "Sydney", "Paris", "Berlin", "Mumbai", "Toronto"].randomElement()!,
            cod: 200
        )
    }
}
