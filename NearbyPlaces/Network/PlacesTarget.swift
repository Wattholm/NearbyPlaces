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
import SwiftyJSON

// Sample /discover/explore request:
// Docs: https://developer.here.com/documentation/examples/rest/places/explore-places-bounding-box
// https://places.ls.hereapi.com/places/v1/discover/explore?in=14.549492597593515%2C121.09929026115793%3Br%3D1000&size=10&apiKey=H6XyiCT0w1t9GgTjqhRXxDMrVj9h78ya3NuxlwM7XUs

// Sample /browse:
// returns results in order of proximity
// https://places.ls.hereapi.com/places/v1/browse?in=14.549534985687469%2C121.09939593737253&apiKey=H6XyiCT0w1t9GgTjqhRXxDMrVj9h78ya3NuxlwM7XUs

public enum Places {
    static private let apiKey = "a0RqYTI1MFRHdnlUUW9HdnFsTnVWREh5Yy12QlpwaENjakhfd2pUVGRWZw==".simpleDecrypt()!

    case explore(lat: Double, lon: Double, radius: Int, category: String?, size: Int)
    case browse(lat: Double, lon: Double, radius: Int, category: String?, size: Int)
}

extension Places: TargetType {

    public var baseURL: URL {
        return URL(string: "https://places.ls.hereapi.com/places/v1")!
    }
    
    public var path: String {
        switch self {
        case .explore:
            return "/discover/explore"
        case .browse:
            return "/browse"
        }
        
    }
    
    public var method: Moya.Method {
        switch self {
        case .explore: return .get
        case .browse: return .get
        }
    }
    
    public var sampleData: Data {
        if let path = Bundle.main.path(forResource: "SampleData", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                return data
            } catch {
                print("Error getting sample data")
                return Data()
            }
        } else {
            print("Error locating stub file data")
            return Data()
        }
    }
    
    public var task: Task {
        switch self {
        case .explore(let lat, let lon, let radius, let category, let size):
            
            if let cat = category {
                return .requestParameters(
                    parameters: [
                        "in": "\(lat),\(lon);r=\(radius)",
                        "cat": cat,
                        "size": size,
                        "apikey": Places.apiKey
                    ],
                    encoding: URLEncoding.default)
            } else {
                return .requestParameters(
                    parameters: [
                        "in": "\(lat),\(lon);r=\(radius)",
                        "size": size,
                        "apikey": Places.apiKey
                    ],
                    encoding: URLEncoding.default)
            }
        case .browse(let lat, let lon, let radius, let category, let size):
            
            if let cat = category {
                return .requestParameters(
                    parameters: [
                        "at": "\(lat),\(lon);r=\(radius)",
                        "cat": cat,
                        "size": size,
                        "apikey": Places.apiKey
                    ],
                    encoding: URLEncoding.default)
            } else {
                return .requestParameters(
                    parameters: [
                        "at": "\(lat),\(lon);r=\(radius)",
                        "size": size,
                        "apikey": Places.apiKey
                    ],
                    encoding: URLEncoding.default)
            }
        }
    }
    
    public var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
}
