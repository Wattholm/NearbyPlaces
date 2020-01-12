//
//  PlacesTarget.swift
//  NearbyPlaces
//
//  Created by KJEM on 12/01/2020.
//  Copyright © 2020 KJEM. All rights reserved.
//

import Foundation
import MapKit
import Moya

let yellowCabLocation = CLLocationCoordinate2DMake(14.577820, 121.085870)

// Sample explore request:
// Docs: https://developer.here.com/documentation/examples/rest/places/explore-places-bounding-box
// https://places.ls.hereapi.com/places/v1/discover/explore?in=14.549492597593515%2C121.09929026115793%3Br%3D1000&size=10&apiKey=H6XyiCT0w1t9GgTjqhRXxDMrVj9h78ya3NuxlwM7XUs

public enum Places {
    static private let apiKey = "H6XyiCT0w1t9GgTjqhRXxDMrVj9h78ya3NuxlwM7XUs"
    
    case explore(lat: Double, lon: Double, radius: Int, size: Int)
}

extension Places: TargetType {

    public var baseURL: URL {
        return URL(string: "https://places.ls.hereapi.com/places/v1")!
    }
    
    public var path: String {
        switch self {
        case .explore:
            return "/discover/explore"
        }
        
    }
    
    public var method: Moya.Method {
        switch self {
        case .explore: return .get
        }
    }
    
    public var sampleData: Data {
        return Data()
    }
    
    public var task: Task {
        switch self {
        case .explore(let lat, let lon, let radius, let size):
            return .requestParameters(
                parameters: [
                    "in": "\(lat)%2C\(lon)%3Br%3D\(radius)",
                    "apikey": Places.apiKey,
                    "size": size
                ],
                encoding: URLEncoding.default)
        }
    }
    
    public var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
}
