//
//  EventConfirmationViewController.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-07-26.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit
import MapKit
import CloudKit

class EventConfirmationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var eventRecords : [CKRecord]?
    var recordIndex = 0
    let formatter = DateFormatter()
    let databaseManager = DatabaseManager()
    var currentLocation: CLLocationCoordinate2D!
    var locationManager: CLLocationManager!
    let coordinates:CLLocationCoordinate2D = CLLocationCoordinate2DMake(43.6456, -79.3954)

    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tryAgainButton.layer.cornerRadius = tryAgainButton.frame.height / 2
        confirmButton.layer.cornerRadius = confirmButton.frame.height / 2
        
        
        mapView.delegate = self
        locationManager = CLLocationManager()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }
        
        createAnnotations(coordinates)
        
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        
        //Button Constraints
        constrainButtons()
        mapView.showsUserLocation = true
        
        
       
        
        if eventRecords != nil {
            for record in eventRecords! {
                print(record["title"] as! String)
            }
            if eventRecords!.count == 0 {
                titleLabel.text = "No events found at this time. Try again later, or create your own event!"
                timeLabel.text = ""
            } else if eventRecords!.count > 0 {
                eventRecords!.shuffle()
                let eventRecord = eventRecords![recordIndex]
                recordIndex = (recordIndex + 1) % eventRecords!.count
                titleLabel.text = eventRecord["title"] as? String
                timeLabel.text = formatter.string(from: eventRecord["time"] as! Date)
                // set mapView to be location from EventRecord's location
                
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location?.coordinate
        
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpanMake(0.05, 0.05))
        mapView.setRegion(coordinateRegion, animated: true)
        
    }

    @IBAction func tryAgainButtonTapped(_ sender: Any) {
        let eventRecord = eventRecords![recordIndex]
        recordIndex = (recordIndex + 1) % eventRecords!.count
        titleLabel.text = eventRecord["title"] as? String
        timeLabel.text = formatter.string(from: eventRecord["time"] as! Date)
        // set mapView to be location from EventRecord's location
        
        createAnnotations(coordinates)
    }
    
    @IBAction func confirmButtonTapped(_ sender: Any) {
        
        let eventRecord: CKRecord
        
        if (recordIndex == 0) {
            eventRecord = eventRecords![eventRecords!.count - 1]
        } else {
            eventRecord = eventRecords![recordIndex - 1]
        }
        
        eventRecord["guest"] = "DEF" as NSString
        databaseManager.save(eventRecord: eventRecord) { [weak self] (record, error) in
            if (error == nil) && (record != nil) {
                print(record!["guest"] as! NSString)
                
                DispatchQueue.main.async {
                    self?.performSegue(withIdentifier: "goToDetailScreenSegue", sender: self)
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailScreenSegue" {
            let detailViewController = segue.destination as! EventDetailsViewController
//            detailViewController.cafe = selectedCafe
            
            let eventRecord: CKRecord
            
            if (recordIndex == 0) {
                eventRecord = eventRecords![eventRecords!.count - 1]
            } else {
                eventRecord = eventRecords![recordIndex - 1]
            }
        
            detailViewController.eventTitle = eventRecord["title"] as? String
            detailViewController.eventTime = eventRecord["time"] as? Date
            detailViewController.guestStatus = "There is a guest!"
            detailViewController.catchPhrase = "Your catchphrase is: petunia"
            
        }
    }
    
    private func constrainButtons() {
        tryAgainButton.translatesAutoresizingMaskIntoConstraints = false
        tryAgainButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        tryAgainButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        tryAgainButton.widthAnchor.constraint(equalToConstant: self.view.frame.size.width/2).isActive = true
        tryAgainButton.heightAnchor.constraint(equalToConstant: 85).isActive = true
        
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.leadingAnchor.constraint(equalTo: tryAgainButton.trailingAnchor).isActive = true
        confirmButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        confirmButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        confirmButton.heightAnchor.constraint(equalToConstant: tryAgainButton.frame.size.height).isActive = true
        confirmButton.widthAnchor.constraint(equalToConstant: self.view.frame.size.width/2).isActive = true
    }
    
    
    func createAnnotations(_ coordinates:CLLocationCoordinate2D){
       mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
    }

}

