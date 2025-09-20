import Foundation
import CoreLocation
import MapKit
import Combine
import FirebaseFirestore

class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    var coordinatesPublisher = PassthroughSubject<CLLocationCoordinate2D, Error>()
    var deniedLocationAccessPublisher = PassthroughSubject<Void, Never>()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestLocationPermission() {
        print("🔍 Requesting location permission. Current status: \(locationManager.authorizationStatus.rawValue)")
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("📍 Location permission not determined, requesting authorization")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 Location permission granted, getting current location immediately")
            // Request one-time location update for immediate centering
            locationManager.requestLocation()
            // Also start continuous updates
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("📍 Location permission denied or restricted")
            deniedLocationAccessPublisher.send()
        @unknown default:
            print("📍 Unknown location authorization status")
            break
        }
    }
    
    func requestLocationPermissionForPosting() {
        requestLocationPermission()
    }
    
    func startLocationUpdates() {
        print("Starting location updates...")
        print("Current authorization status: \(authorizationStatus.rawValue)")
        print("Location manager authorization status: \(locationManager.authorizationStatus.rawValue)")
        
        // Check both the stored status and the current manager status
        let currentStatus = locationManager.authorizationStatus
        guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
            print("Location permission not granted, cannot start updates")
            print("Current status: \(currentStatus.rawValue)")
            return
        }
        
        print("Location permission granted, starting location manager...")
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func calculateDistance(from location1: CLLocation, to location2: CLLocation) -> CLLocationDistance {
        return location1.distance(from: location2)
    }
    
    func calculateDistance(from location1: CLLocation, to geoPoint: GeoPoint) -> CLLocationDistance {
        let location2 = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        return calculateDistance(from: location1, to: location2)
    }
    
    func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Location manager did update locations: \(locations.count) locations")
        guard let location = locations.last else { 
            print("No valid location found in locations array")
            return 
        }
        print("Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocation = location
        coordinatesPublisher.send(location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
        coordinatesPublisher.send(completion: .failure(error))
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 Location authorization changed to: \(manager.authorizationStatus.rawValue)")
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 Location authorized, getting current location immediately")
            // Request one-time location update for immediate centering
            manager.requestLocation()
            // Also start continuous updates
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("📍 Location denied/restricted, stopping updates")
            manager.stopUpdatingLocation()
            deniedLocationAccessPublisher.send()
        case .notDetermined:
            print("📍 Location status not determined")
            break
        @unknown default:
            print("📍 Unknown location authorization status")
            break
        }
    }
}
