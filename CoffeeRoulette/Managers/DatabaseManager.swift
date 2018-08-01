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
    
    init() {
        getAccountStatus()
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
    
    func getUserID(completion: @escaping ((CKRecordID?, Error?)->Void)) {
        if (accountStatus == .available) {
            container.fetchUserRecordID() { (recordID, error) in
                completion(recordID, error)
            }
        }
    }
}




// alert view upon errors saving to cloud database
/*
 else {
 let ac = UIAlertController(title: "Error", message: "There was a problem submitting your suggestion: \(error!.localizedDescription)", preferredStyle: .alert)
 ac.addAction(UIAlertAction(title: "OK", style: .default))
 self.present(ac, animated: true)
 */




















