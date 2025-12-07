//
//  WeatherAppView.swift
//  SwiftUI_MachineCoding
//
//  Created by Sidhartha Mallick on 06/12/25.
//

import SwiftUI

struct WeatherAppView: View {
    @StateObject var viewModel = WeatherAppViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: getGradientColors()),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    if viewModel.loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding(.top, 100)
                    } else if let error = viewModel.error {
                        errorView(error)
                            .padding(.top, 100)
                    } else if let weather = viewModel.weatherInfo {
                        weatherContentView(weather)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
            
            TextField("Search city", text: $viewModel.searchCity)
                .focused($isSearchFocused)
                .foregroundColor(.white)
                .onSubmit {
                    viewModel.searchWeatherByCity(viewModel.searchCity)
                }
            
            if !viewModel.searchCity.isEmpty {
                Button(action: {
                    viewModel.searchCity = ""
                    viewModel.loadLocationWeather()
                    isSearchFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.2))
        )
    }
    
    // MARK: - Weather Content
    private func weatherContentView(_ weather: WeatherResponse) -> some View {
        VStack(spacing: 30) {
            // Location and time
            VStack(spacing: 8) {
                HStack {
                    if viewModel.isUsingLocation {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                    }
                    Text(weather.name)
                        .font(.system(size: 34, weight: .regular))
                        .foregroundColor(.white)
                }
                
                Text(weather.weather.first?.description.capitalized ?? "")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 40)
            
            // Temperature
            HStack(alignment: .top, spacing: 0) {
                Text(viewModel.temperature)
                    .font(.system(size: 100, weight: .thin))
                    .foregroundColor(.white)
                
                Text("°")
                    .font(.system(size: 100, weight: .thin))
                    .foregroundColor(.white)
                    .padding(.leading, -10)
            }
            
            // Feels like
            Text("Feels like \(Int(weather.main.feelsLike))°")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
                .frame(height: 40)
            
            // Additional details
            VStack(spacing: 20) {
                weatherDetailRow(
                    icon: "thermometer",
                    title: "High / Low",
                    value: "\(Int(weather.main.tempMax))° / \(Int(weather.main.tempMin))°"
                )
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                if let humidity = weather.main.humidity {
                    weatherDetailRow(
                        icon: "drop.fill",
                        title: "Humidity",
                        value: "\(humidity)%"
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                }
                
                if let wind = weather.wind, let speed = wind.speed {
                    weatherDetailRow(
                        icon: "wind",
                        title: "Wind",
                        value: String(format: "%.1f km/h", speed * 3.6)
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                }
                
                if let pressure = weather.main.pressure {
                    weatherDetailRow(
                        icon: "gauge",
                        title: "Pressure",
                        value: "\(pressure) hPa"
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                }
                
                if let visibility = weather.visibility {
                    weatherDetailRow(
                        icon: "eye",
                        title: "Visibility",
                        value: "\(visibility / 1000) km"
                    )
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Weather Detail Row
    private func weatherDetailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: WeatherError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.8))
            
            Text(error.localizedDescription)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if case .locationError = error {
                Button(action: {
                    viewModel.loadLocationWeather()
                }) {
                    Text("Retry")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.3))
                        )
                }
                .padding(.top, 10)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getGradientColors() -> [Color] {
        guard let weather = viewModel.weatherInfo,
              let condition = weather.weather.first?.main.lowercased() else {
            // Default gradient
            return [Color.blue.opacity(0.6), Color.blue.opacity(0.8)]
        }
        
        switch condition {
        case "clear":
            return [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.2, green: 0.5, blue: 0.9)]
        case "clouds":
            return [Color(red: 0.5, green: 0.6, blue: 0.7), Color(red: 0.4, green: 0.5, blue: 0.6)]
        case "rain":
            return [Color(red: 0.3, green: 0.4, blue: 0.5), Color(red: 0.2, green: 0.3, blue: 0.4)]
        case "thunderstorm":
            return [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)]
        case "snow":
            return [Color(red: 0.7, green: 0.8, blue: 0.9), Color(red: 0.6, green: 0.7, blue: 0.8)]
        case "mist", "fog":
            return [Color(red: 0.6, green: 0.6, blue: 0.7), Color(red: 0.5, green: 0.5, blue: 0.6)]
        default:
            return [Color.blue.opacity(0.6), Color.blue.opacity(0.8)]
        }
    }
}

#Preview {
    WeatherAppView()
}
