//
//  Event.swift
//  CoffeeRoulette
//
//  Created by Erik Goossens on 2018-07-31.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import Foundation
import CloudKit

class Event {
    var title: String
    var time: Date
    var location: CLLocation?
    var cafe: Cafe!
    var host: String?
    var guest: String?
    var catchPhrase: String?

    
    init(title:String, time: Date, cafe: Cafe) {
        self.title = title
        self.time = time
        self.cafe = cafe
    }
    
    func createCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Event")
        record["title"] = self.title as NSString
        record["time"] = self.time as NSDate
        record["location"] = CLLocation(latitude: self.cafe.location.latitude, longitude: self.cafe.location.longitude)
        record["cafeName"] = self.cafe.cafeName as NSString
        record["cafePhotoRef"] = self.cafe.photoRef! as NSString
        record["cafeAddress"] = self.cafe.address! as NSString
        record["catchPhrase"] = self.catchPhrase! as NSString

        return record
    }
    
    
}
