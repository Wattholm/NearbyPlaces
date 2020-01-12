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
    
    @IBOutlet weak var mapView: MKMapView!
    
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
    }
        
    /*
    func getTransitETA() {
        let request = MKDirections.Request()
        let source = MKMapItem(placemark:
          MKPlacemark(coordinate:CLLocationCoordinate2D(latitude: 40.748384,
               longitude: -73.985479), addressDictionary: nil))
        source.name = "Empire State Building"
        request.source = source

        let destination = MKMapItem(placemark:
          MKPlacemark(coordinate:CLLocationCoordinate2D(latitude: 40.643351,
               longitude: -73.788969), addressDictionary: nil))
        destination.name = "JFK Airport"
        request.destination = destination

        request.transportType = MKDirectionsTransportType.transit

        let directions = MKDirections(request: request)
        directions.calculateETA {
           (response, error) -> Void in
            if error == nil {
                if let estimate = response {
                    print("Estimated Travel time \(round(estimate.expectedTravelTime / 60)) mins")
                    print("Departing at \(estimate.expectedDepartureDate)")
                    print("Arriving at \(estimate.expectedArrivalDate)")
                }
            }
        }
    }*/

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
            
            provider.request(Places.browse(lat: userLocation.latitude, lon: userLocation.longitude, radius: PlacesConstants.searchRadius, category: PlacesConstants.defaultCategory, size: PlacesConstants.maxResultSize)) { [weak self] (result) in
                
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
        
        print("Total Results: \(items.count)")
        
        for item in items {
            let pinLocation = CLLocationCoordinate2DMake(item["position"][0].double!,item["position"][1].double!)
            let pin = MKPointAnnotation()
            pin.coordinate = pinLocation
            pin.title = item["title"].string ?? ""
            self.mapView.addAnnotation(pin)
        }
    }
    
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("mapView(:didupdate:)")
        //mapView.centerCoordinate = userLocation.location!.coordinate
        print(mapView.centerCoordinate)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pin = view.annotation else {
            print("Annotation is missing")
            return
        }
        
        guard let title: String = pin.title ?? "", title != "" else {
            print("Annotation lacks a title")
            return
        }
        
        let utterance = AVSpeechUtterance(string: title)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.4

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)

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
