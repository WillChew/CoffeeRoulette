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
    var location: CLLocation
    var host: String?
    var guest: String?
    var catchPhrase: String?
    var eventID: String?
//    var cafe: Cafe
    
    
    init(title:String, time: Date, location: CLLocation ) {
        self.title = title
        self.time = time
        self.location = location
    }
    
    func createCKRecord() -> CKRecord {
        let event = CKRecord(recordType: "Event")
        event["title"] = self.title as NSString
        event["time"] = self.time as NSDate
        event["location"] = self.location
        return event
    }
    
    
}
