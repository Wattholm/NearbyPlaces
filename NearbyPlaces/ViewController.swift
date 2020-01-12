//
//  ViewController.swift
//  NearbyPlaces
//
//  Created by KJEM on 11/01/2020.
//  Copyright © 2020 KJEM. All rights reserved.
//

import UIKit
import AVFoundation
import MapKit
import Moya
import SwiftyJSON

class ViewController: UIViewController {
        
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
        print("zoomIn()")

        if let userLocation = mapView.userLocation.location?.coordinate {
            
            let region = MKCoordinateRegion(
                center: userLocation, latitudinalMeters: PlacesConstants.zoomRadius, longitudinalMeters: PlacesConstants.zoomRadius)
            
            mapView.setRegion(region, animated: true)
        }
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
        super.viewDidLoad()
                
        mapView.delegate = self

        mapView.showsUserLocation = true
        
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
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] context in
            guard let self = self else {return}
            guard let items = self.items else {return}
            guard let pin = self.selectedPin else {return}
            
            self.infoLabel.text = self.getPinInfoString(for: pin, from: items)
        })
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("mapView(:didupdate:)")
        //mapView.centerCoordinate = userLocation.location!.coordinate
        print(mapView.centerCoordinate)
    }
    
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

extension ViewController: CLLocationManagerDelegate {
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.denied) {
            // The user denied authorization
        } else if (status == CLAuthorizationStatus.authorizedAlways) {
            // The user accepted authorization
        } else if (status == CLAuthorizationStatus.authorizedWhenInUse) {
            
        }
    }
}
