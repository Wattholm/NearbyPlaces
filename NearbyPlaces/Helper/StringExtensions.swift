//
//  StringExtensions.swift
//  NearbyPlaces
//
//  Created by KJEM on 12/01/2020.
//  Copyright © 2020 KJEM. All rights reserved.
//

import Foundation

extension String {
    func simpleDecrypt() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
