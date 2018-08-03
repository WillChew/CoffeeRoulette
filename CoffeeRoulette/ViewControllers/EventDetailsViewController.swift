//
//  EventDetailsViewController.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-07-26.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit
import CloudKit
import MapKit

class EventDetailsViewController: UIViewController {
    
    var databaseManager: DatabaseManager!
    
    var event: CKRecord?
    
    var cafe: Cafe?
    var eventTime: Date?
    var eventLocation: String?
    var cafePicture: UIImage?
    
    var guestStatus: String?
    var catchPhrase: String?
    
    
    //CURRENT LOCATION HARDCODED PLACEHOLDER VALUES TO CENTER MAP
    let latitude = 43.6456
    let longitude = -79.3954
    let name = "Quantum"
    
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var cafeImageView: UIImageView!
    
    @IBOutlet weak var guestStatusLabel: UILabel!
    @IBOutlet weak var catchPhraseLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // host and guest both pass event record
        guard let event = event else { return }
        
        if cafePicture != nil {
            cafeImageView.image = cafePicture
        } else {
            // host passes selected cafe (with photo)
            cafeImageView.image = cafe?.photo
        }
        
        
        let date = event["time"] as? Date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
    
        titleLabel.text = event["title"] as? String
        timeLabel.text = formatter.string(from: date!)
        locationLabel.text = eventLocation
        
    }
    
    override func viewDidLayoutSubviews() {
        guestStatusLabel.text = guestStatus!
        guestStatusLabel.sizeToFit()
        catchPhraseLabel.text = catchPhrase!
        catchPhraseLabel.sizeToFit()
    }

    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        databaseManager.delete(event: event!) { (recordID, error) in
            if ((error == nil) && (recordID != nil)) {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "goToMainScreen", sender: self)
                }
            }
        }  
    }
    
    //Get directions
    @IBAction func directionsButtonPressed(_ sender: UIButton) {
        
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, 1000, 1000)
        let placeMarker = MKPlacemark(coordinate: coordinates)
        let mapItem = MKMapItem(placemark: placeMarker)
        mapItem.name = name
        mapItem.openInMaps(launchOptions:[
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center)
            ] as [String : Any])
    }
}
