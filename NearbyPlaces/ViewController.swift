//
//  ViewController.swift
//  NearbyPlaces
//
//  Created by KJEM on 11/01/2020.
//  Copyright © 2020 KJEM. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import MapKit
import Moya
import SwiftyJSON

class ViewController: UIViewController {
    
    var locationManager: CLLocationManager?
    var locationCheckTimer: Timer?
    var zoomInTimer: Timer?
    let provider: MoyaProvider = MoyaProvider<Places>()
    
    // MARK: - View State
    private var state: State = .loading {
      didSet {
        switch state {
        case .ready: break
        case .loading: break
        case .error: break
        }
      }
    }

    // Search Results
    private var queryJson: JSON? {
        didSet {
            print(self.queryJson!)
        }
    }
    
    // Places JSON Array
    private var items: [JSON]?
    
    private var selectedPin: MKPointAnnotation?
    
    // MARK: IB Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var infoLabel: UILabel!
    
    
    // MARK: IB Actions
    @IBAction func zoomIn(_ sender: UIBarButtonItem) {
        updateUserLocation()
    }
    
    @IBAction func changeMapType(_ sender: UIBarButtonItem) {
        if mapView.mapType == MKMapType.standard {
            mapView.mapType = MKMapType.satellite
        } else {
            mapView.mapType = MKMapType.standard
        }
        print("changeMapType(): \(mapView.mapType)")
    }
    
    @IBAction func searchNearbyPlaces(_ sender: UIBarButtonItem) {
        print("searchNearbyPlaces()")
        browse()
    }
    
    override func viewDidLoad() {
        print("viewDidLoad()")
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        
        if locationCheckTimer == nil {
            locationCheckTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkLocationAlert), userInfo: nil, repeats: true)
            locationCheckTimer?.tolerance = 0.2
        }
        
                
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()

        mapView.delegate = self
        
        infoLabel.layer.borderWidth = 2
        infoLabel.layer.borderColor = UIColor.gray.cgColor
        infoLabel.layer.cornerRadius = 8
        infoLabel.adjustsFontSizeToFitWidth = true

    }
    
}

extension ViewController {
  enum State {
    case loading
    case ready
    case error
  }
        
    private func explore() {
        if let userLocation = mapView.userLocation.location?.coordinate {
            
            provider.request(Places.explore(lat: userLocation.latitude, lon: userLocation.longitude, radius: PlacesConstants.searchRadius, category: PlacesConstants.defaultCategory, size: PlacesConstants.maxResultSize)) { [weak self] (result) in
                
                guard let self = self else { return }
                
                switch result {
                case .success(let moyaResponse):
                    do {
                        
                        let data = moyaResponse.data
                        
                        self.queryJson = try JSON(data: data)
                        
                        self.state = .ready
                        
                    } catch(let err) {
                        self.state = .error
                        print(err.localizedDescription)
                    }
                case .failure(let err):
                    // 5
                    self.state = .error
                    print(err.errorDescription as Any)
                }
            }
        }
    }

    private func browse() {
        print("browse()")
        if let userLocation = mapView.userLocation.location?.coordinate {
            
            let target: Places = .browse(lat: userLocation.latitude, lon: userLocation.longitude, radius: PlacesConstants.searchRadius, category: PlacesConstants.defaultCategory, size: PlacesConstants.maxResultSize)

            provider.request(target) { [weak self] (result) in
                
                guard let self = self else { return }
                
                switch result {
                case .success(let moyaResponse):
                    do {
                        
                        let data = moyaResponse.data
                        
                        self.queryJson = try JSON(data: data)
                        
                        self.annotateResults()
                        
                        self.state = .ready
                        
                    } catch(let err) {
                        self.state = .error
                        print(err.localizedDescription)
                    }
                case .failure(let err):
                    // 5
                    self.state = .error
                    print(err.errorDescription as Any)
                }
            }
        }
    }

    private func annotateResults() {
        print("\nannotateResults()")
        
        guard let json = queryJson else {
            print("Response data is nil")
            return
        }
        guard json["results"]["items"].exists() else {
            print("No results from query")
            return
        }
        
        guard let items = json["results"]["items"].array else {
            print("Array of results not retrieved")
            return
        }
        
        self.items = items
        
        print("Total Results: \(items.count)")
        
        for item in items {
            let pinLocation = CLLocationCoordinate2DMake(item["position"][0].double!,item["position"][1].double!)
            let pin = MKPointAnnotation()
            pin.coordinate = pinLocation
            pin.title = item["title"].string ?? ""
            self.mapView.addAnnotation(pin)
        }
    }
    
    private func getPinInfoString(for pin: MKPointAnnotation, from items: [JSON]) -> String {
        guard let title = pin.title else {return ""}
        var distance: Int = 0
        var infoString: String
        
        // Find the element in the places array that matches the point annotation
        for item in items {
            if pin.coordinate.latitude == item["position"][0].double! && pin.coordinate.longitude == item["position"][1].double! {
                distance = item["distance"].int!
            }
        }
                
        if UIApplication.shared.statusBarOrientation.isLandscape {
            infoString = "\(title) is \(distance)m away"
        } else {
            infoString = "\(title)\n\(distance)m away"
        }

        return infoString
    }
    
    @objc private func updateUserLocation() {
        print("updateUserLocation()")
        if let userLocation = mapView.userLocation.location?.coordinate {
            let region = MKCoordinateRegion(
                center: userLocation, latitudinalMeters: PlacesConstants.zoomRadius, longitudinalMeters: PlacesConstants.zoomRadius)
            mapView.setRegion(region, animated: true)
            zoomInTimer?.invalidate()
            zoomInTimer = nil
        }

    }
    
    @objc private func checkLocationAlert() {
        print("checkLocationAlert()")
        guard let locationManager = locationManager else {return}
        guard CLLocationManager.locationServicesEnabled() else {return}

        // if self.navigationController?.visibleViewController is UIAlertController {}

        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            mapView.showsUserLocation = true
            locationCheckTimer?.invalidate()
            locationCheckTimer = nil
            if zoomInTimer == nil {
                zoomInTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateUserLocation), userInfo: nil, repeats: true)
                zoomInTimer?.tolerance = 0.2
            }
            print("Location Permissions check has completed.")
        }
        
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] context in
            guard let self = self else {return}
            guard let items = self.items else {return}
            guard let pin = self.selectedPin else {return}
            
            self.infoLabel.text = self.getPinInfoString(for: pin, from: items)
        })
    }
    
    @objc func willEnterForeground() {
        checkLocationAlert()
    }

}

extension ViewController: CLLocationManagerDelegate {
    
    /*
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("mapView(:didupdate:)")
        print("Map center: \(mapView.centerCoordinate)")
    }*/

    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print("locationManager(didChangeAuthorizationStatus..)")
        
        if (status == CLAuthorizationStatus.denied) {
            print("User has denied access to location services. App will not function properly")
        } else if (status == CLAuthorizationStatus.authorizedAlways) {
            print("User has granted permanent location access")
            mapView.showsUserLocation = true
        } else if (status == CLAuthorizationStatus.authorizedWhenInUse) {
            print("User has granted 'when in use' location access")
            mapView.showsUserLocation = true
        }
    }

}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let items = self.items else {return}

        guard let pin = view.annotation else {
            print("Annotation is missing")
            return
        }
        
        guard let title: String = pin.title ?? "", title != "" else {
            print("Annotation lacks a title")
            return
        }
        
        selectedPin = pin as? MKPointAnnotation
        
        if let myPin = selectedPin {
            let infoString = self.getPinInfoString(for: myPin, from: items)
            
            infoLabel.text = infoString
            
            let utterance = AVSpeechUtterance(string: infoString.replacingOccurrences(of: "\n", with: " is "))
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            utterance.rate = 0.4

            let synthesizer = AVSpeechSynthesizer()
            synthesizer.speak(utterance)
        }

    }
}

