//
//  DatabaseManager.swift
//  CoffeeRoulette
//
//  Created by Erik Goossens on 2018-07-31.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import Foundation
import CloudKit

class DatabaseManager {
    let db = CKContainer.default().publicCloudDatabase
    
    func save(eventRecord: CKRecord, completion: @escaping ((CKRecord?, Error?)->()) ) {
        db.save(eventRecord) { (record, error) in
            if let error = error { print(#line, error.localizedDescription); return}
            completion(record, error)
        }
    }
    
    func save(event: Event, completion: @escaping ((CKRecord?, Error?)->()) ) {
        let eventCKRecord = event.createCKRecord()
        db.save(eventCKRecord) { (record, error) in
            if let error = error { print(#line, error.localizedDescription); return}
            completion(record, error)
        }
    }
    
    func getEvents(completion: @escaping (([CKRecord]?, Error?)->()) ) {
        let query = CKQuery(recordType: "Event", predicate: NSPredicate(value: true))
        db.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error { print(#line, error.localizedDescription); return}
            completion(records, error)
        }
        
        
    }
}

