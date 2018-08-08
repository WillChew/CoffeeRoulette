//
//  Annotations.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-07-30.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class Annotations: NSObject, MKAnnotation {
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var photoRef: String?
    var subtitle: String?
    var address: String?
    
    init(title: String, coordinate: CLLocationCoordinate2D, subtitle: String) {
        self.title = title
        self.coordinate = coordinate
        self.subtitle = subtitle
    }
}
