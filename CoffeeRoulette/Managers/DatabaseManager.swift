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
    let dbPrivate = CKContainer.default().privateCloudDatabase
    
    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
    
    init() {
        getAccountStatus()
    }
    
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
    
    func getEvents(completion: @escaping (([CKRecord], Error?)->()) ) {
        
        let query = CKQuery(recordType: "Event", predicate: NSPredicate(value: true))
        
        db.perform(query, inZoneWith: nil) { (records, error) in
            
            if let error = error { print(error.localizedDescription); return }
            
            guard let records = records else {
                completion([], error)
                return
            }
            
            completion(records, error)
        }
    }
    
    func getEventsNearMe(location: CLLocation, radius: Double, completion: @escaping (([CKRecord]?, Error?)->()) ) {
        
        guard self.accountStatus == .available else { return }
        
        self.getUserID { (recordID, error) in
            
            guard let recordID = recordID, error == nil else { return }
            
            let userPredicate = NSPredicate(format: "creatorUserRecordID != %@", recordID)
            //let guestPredicate =
            let timePredicate = NSPredicate(format: "time > %@", NSDate())
            let locationPredicate = NSPredicate(format: "distanceToLocation:fromLocation:(%K,%@) < %f", "location", location, radius)
            
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [userPredicate, timePredicate, locationPredicate])
            //let predicate = NSPredicate(value: true)
            
            let query = CKQuery(recordType: "Event", predicate: predicate)
            self.db.perform(query, inZoneWith: nil) { (records, error) in
                if let error = error { print(#line, error.localizedDescription); return}
                completion(records, error)
            }
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
    
    func save(subscription: CKSubscription, completion: @escaping ((CKSubscription?, Error?)->())){
        dbPrivate.save(subscription) { (subscription, error) in
            completion(subscription, error)
        }
    }
    
    
    func delete(subscription: CKSubscription, completion: @escaping ((String?, Error?) -> ())) {
        db.delete(withSubscriptionID: subscription.subscriptionID) { (subscriptionID, error) in
            completion(subscriptionID, error)
        }
    }
    
    func delete(event: CKRecord, completion: @escaping ((CKRecordID?, Error?) -> ())) {
        db.delete(withRecordID: event.recordID) { (recordID, error) in
            completion(recordID, error)
        }
    }
    
    
    func isUserInEvent(completion: @escaping ((CKRecord?, Error?)-> ())) {
        
        //        guard self.accountStatus == .available else { return }
        
        getUserID {[weak self](recordID, error) in
            
            guard let userRecordID = recordID, error == nil else { return }
            
            let userReference = CKReference(recordID: userRecordID, action: .none)
            
            let hostPredicate = NSPredicate(format: "creatorUserRecordID == %@ AND time > %@", userReference, Date() as NSDate)
            
            
            let guestPredicate = NSPredicate(format: "%K == %@ AND time > %@", "guest", userReference, Date() as NSDate)
            
            let query1 = CKQuery(recordType: "Event", predicate: hostPredicate)
            let query2 = CKQuery(recordType: "Event", predicate: guestPredicate)
            let operation1 = CKQueryOperation(query: query1)
            let operation2 = CKQueryOperation(query: query2)
            operation1.qualityOfService = .userInitiated
            
            operation2.qualityOfService = .userInitiated
            
            var hostCreatedRecord: CKRecord? = nil {
                didSet {
                    print(#line, "hostCreatedRecord was set")
                }
            }
            var guestInRecord: CKRecord? = nil {
                didSet {
                    print(#line, "guestInRecord was set")
                }
            }
            
            operation1.recordFetchedBlock = { record in
                hostCreatedRecord = record
            }
            operation1.queryCompletionBlock = { _, error in
                if let hostCreatedRecord = hostCreatedRecord {
                    completion(hostCreatedRecord, error)
                } else if let error = error {
                    print(#line, error.localizedDescription)
                } else {
                    self?.db.add(operation2)
                }
            }
            
            self?.db.add(operation1)
            
            
            operation2.recordFetchedBlock = { record in
                guestInRecord = record
            }
            operation2.queryCompletionBlock = { _, error in
                if let guestInRecord = guestInRecord {
                    completion(guestInRecord, error)
                } else {
                    print(#line, error?.localizedDescription ?? "No error message to print")
                    completion(nil, nil)
                }
            }
            
            
            //            self?.db.perform(query, inZoneWith: nil) { (records, error) in
            //                if let error = error { print(#line, error.localizedDescription); return}
            //                completion(records, error)
            //            }
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




















