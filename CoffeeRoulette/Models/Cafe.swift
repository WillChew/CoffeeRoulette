//
//  Cafe.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-07-30.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class Cafe {
    var cafeName: String
    var location: CLLocationCoordinate2D
    var photo: UIImage?
    var photoRef: String?
    var rating: Double?
    
    init(cafeName: String, location: CLLocationCoordinate2D ) {
        self.cafeName = cafeName
        self.location = location
    }
    
}
