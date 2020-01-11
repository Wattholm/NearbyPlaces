//
//  ViewController.swift
//  NearbyPlaces
//
//  Created by KJEM on 11/01/2020.
//  Copyright © 2020 KJEM. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func zoomIn(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func changeMapType(_ sender: UIBarButtonItem) {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
        
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
    }

}

extension ViewController: MKMapViewDelegate {
    
}
