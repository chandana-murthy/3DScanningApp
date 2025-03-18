//
//  LocationManager.swift
//  DataFlor
//
//  Created by Chandana Murthy on 08.06.22.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var lastLocation: CLLocation?
    var locationString: String?
    var coordinateString: String?
    var lastHeading: CLLocationDirection?

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
        locationManager?.startUpdatingHeading()
    }

    var userLatitude: String {
        return String(format: "%.5f", lastLocation?.coordinate.latitude ?? 0)
    }

    var userLongitude: String {
        return String(format: "%.5f", lastLocation?.coordinate.longitude ?? 0)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        coordinateString = "lat: \(userLatitude),\nlong: \(userLongitude)"
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            if error != nil {
                print("error in reverseGeocode")
            }
            guard let allPlacemarks = placemarks else {
                return
            }
            if allPlacemarks.count > 0 {
                let placemark = allPlacemarks[0]
                self?.locationString = ""
                if let locality = placemark.locality {
                    self?.locationString = locality
                    if let country = placemark.country {
                        self?.locationString = "\(locality),\n\(country)"
                    }
                } else if let country = placemark.country {
                    self?.locationString = country
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        lastHeading = newHeading.magneticHeading
    }

    func stopUpdatingLocation() {
        self.locationManager?.stopUpdatingLocation()
        self.locationManager?.stopUpdatingHeading()
        self.locationManager?.delegate = nil
        self.locationManager = nil
        self.lastLocation = nil
    }
}
