//
//  PlacesAPI.swift
//  NearbyPlaces
//
//  Created by KJEM on 11/01/2020.
//  Copyright © 2020 KJEM. All rights reserved.
//

import Foundation

struct PlacesConstants {
    static let searchRadius: Int = 5000
    static let zoomRadius: Double = 5000
    static let maxResultSize: Int = 10
    static let defaultCategory: String? = nil
    
    //Acceptable Category IDs:
    //"sights-museums" // top level category
        //"theatre-music-culture"
        //"landmark-attraction"
        //"amusement-holiday-park"
        //"mall"
        //"museum"
        //"hotel"
    
    
    /*
    Places Category System
    100 - Eat and Drink
    200 - Going Out-Entertainment
    300 - Sights and Museums
    350 - Natural and Geographical
    400 - Transport
    500 - Accommodations
    550 - Leisure and Outdoor
    600 - Shopping
    700 - Business and Services
    800 - Facilities
    900 - Areas and Buildings
     */
}
