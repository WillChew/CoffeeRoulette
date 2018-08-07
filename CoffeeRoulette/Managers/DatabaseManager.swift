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

    func getEvent(recordID: CKRecordID, completion: @escaping ((CKRecord?, Error?)->()) ) {
        
        let predicate = NSPredicate(format: "recordID = %@", recordID)
        
        let query = CKQuery(recordType: "Event", predicate: predicate)
        
        db.perform(query, inZoneWith: nil) { (records, error) in
            
            if let error = error { print(error.localizedDescription); return }
            
            guard let records = records, let record = records.first else {
                completion(nil, error)
                return
            }
            
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
            
            // user is not the host of the event
            let hostPredicate = NSPredicate(format: "creatorUserRecordID != %@", recordID)
            
            // the event has no confirmed guest
            let guestPredicate = NSPredicate(format: "catchPhrase == %@", "")
            
            // the event is in the future
            let timePredicate = NSPredicate(format: "time > %@", NSDate())
            
            // the event is near the user
            let locationPredicate = NSPredicate(format: "distanceToLocation:fromLocation:(%K,%@) < %f", "location", location, radius)
            
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [hostPredicate, guestPredicate, timePredicate, locationPredicate])
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
        db.save(subscription) { (subscription, error) in
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
            
            let nowMinus5Minutes = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            
            let hostPredicate = NSPredicate(format: "creatorUserRecordID == %@ AND time > %@", userReference, nowMinus5Minutes as NSDate)
            
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
            
            /*
            self?.db.perform(query, inZoneWith: nil) { (records, error) in
                if let error = error { print(#line, error.localizedDescription); return}
                completion(records, error)
            }
            */
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

extension DatabaseManager {
    func fetchAllSubscriptions() {
        let publicFetchSubcriptions = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        db.add(publicFetchSubcriptions)
        let privateFetchSubcriptions = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        db.add(privateFetchSubcriptions)
        publicFetchSubcriptions.fetchSubscriptionCompletionBlock = {dict, error in
            print(#line, dict ?? "no public subscriptions")
//            self.deleteSubscriptions(dict: dict, isPublic: true)
        }
        privateFetchSubcriptions.fetchSubscriptionCompletionBlock = {dict, error in
            print(#line, dict ?? "no private subscriptions")
//            self.deleteSubscriptions(dict: dict, isPublic: false)
        }
    }
    
    func deleteSubscriptions(dict: Dictionary<String, CKSubscription>?, isPublic: Bool) {
        guard let dict = dict else { return }
        var subIds = [String]()
        for d in dict {
            // delete subscription
            subIds.append(d.value.subscriptionID)
        }
        let deletionOperation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: subIds)
        isPublic ? db.add(deletionOperation) : dbPrivate.add(deletionOperation)
        deletionOperation.modifySubscriptionsCompletionBlock = {subs, ids, err in
            print(#line, subs?.count ?? 0)
            print(#line, ids ?? "no ids")
            print(#line, err ?? "no error")
            
        }
    }
}




















