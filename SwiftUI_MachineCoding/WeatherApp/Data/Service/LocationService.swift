//
//  LocationService.swift
//  SwiftUI_MachineCoding
//
//  Created by Sidhartha Mallick on 07/12/25.
//

import Foundation
import CoreLocation

protocol LocationServiceProtocol {
    func requestLocationPermission() async -> Bool
    func getCurrentLocation() async throws -> (latitude: Double, longitude: Double)
    var authorizationStatus: CLAuthorizationStatus { get }
}

class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<(latitude: Double, longitude: Double), Error>?
    private var permissionContinuation: CheckedContinuation<Bool, Never>?
    
    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() async -> Bool {
        // Check current authorization status
        let currentStatus = locationManager.authorizationStatus
        
        switch currentStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            // Request permission and wait for response
            return await withCheckedContinuation { continuation in
                self.permissionContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }
        @unknown default:
            return false
        }
    }
    
    func getCurrentLocation() async throws -> (latitude: Double, longitude: Double) {
        // Check authorization first
        let hasPermission = await requestLocationPermission()
        guard hasPermission else {
            throw WeatherError.locationError(NSError(
                domain: "LocationService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Location permission denied"]
            ))
        }
        
        // Request location
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            locationContinuation?.resume(throwing: WeatherError.locationError(NSError(
                domain: "LocationService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No location data received"]
            )))
            locationContinuation = nil
            return
        }
        
        let coordinates = (latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        locationContinuation?.resume(returning: coordinates)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: WeatherError.locationError(error))
        locationContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Handle permission continuation if waiting
        if let continuation = permissionContinuation {
            let status = manager.authorizationStatus
            let granted = (status == .authorizedWhenInUse || status == .authorizedAlways)
            continuation.resume(returning: granted)
            permissionContinuation = nil
        }
    }
}
