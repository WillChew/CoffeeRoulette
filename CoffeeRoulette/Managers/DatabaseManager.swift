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
    
    let container = CKContainer.default()
    let db = CKContainer.default().publicCloudDatabase
    
    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
    private(set) var userID: CKRecordID?
    
    init() {
        getAccountStatus()
        if (self.accountStatus == .available) {
            getUserID()
        }
    }
    
//    func getUserID( completion: @escaping ((CKRecordID?, Error?)->()) ) {
//        container.accountStatus { (accountStatus, error) in
//            if accountStatus == .available {
//                self.container.fetchUserRecordID(completionHandler: { (recordID, error) in
//                    if (error == nil && recordID != nil) {
//                        completion(recordID, error)
//                    }
//                })
//            }
//        }
//    }
//    func getAccountStatus(completion: @escaping ((CKAccountStatus?, Error?)->()) ) {
//        container.acc
//        completion(container.acc)
//    }
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
    
    private func getAccountStatus() {
        container.accountStatus { [unowned self] (accountStatus, error) in
            
            if let error = error {
                print(error)
            } else {
                self.accountStatus = accountStatus
            }
        }
    }
    
    private func getUserID() {
        if (accountStatus == .available) {
            
            container.fetchUserRecordID { [unowned self] (recordID, error) in
                
                if let error = error {
                    print(error)
                } else {
                    self.userID = recordID
                }
            }
        }
    }
}


























