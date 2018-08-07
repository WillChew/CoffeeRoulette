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
    
    var eventRecords : [CKRecord]!
    var recordIndex = 0
    let formatter = DateFormatter()
    var databaseManager: DatabaseManager!
    var currentLocation: CLLocationCoordinate2D!
    var locationManager = CLLocationManager()
    var coordinates:CLLocation!
    var cafePhoto: UIImage!
    var catchPhrase: String!
    
    
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
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }
        
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        
        mapView.showsUserLocation = true
        
        guard eventRecords.count > 0 else {
            titleLabel.text = "No events found at this time. Try again later, or create your own event!"
            timeLabel.text = ""
            tryAgainButton.isEnabled = false
            confirmButton.isEnabled = false
            return
        }

        for record in eventRecords {
            print(record["title"] as! String)
        }

        if eventRecords.count == 1 {
            tryAgainButton.isEnabled = false
        }
        
        eventRecords.shuffle()
        
        addAnnotation()
    }
    
    
    func addAnnotation() {
        let eventRecord = eventRecords[recordIndex]
        titleLabel.text = eventRecord["title"] as? String
        timeLabel.text = formatter.string(from: eventRecord["time"] as! Date)
        coordinates = eventRecord["location"] as! CLLocation
        createAnnotations(coordinates.coordinate)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        let identifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIView()
            annotationView?.markerTintColor = .brown
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location?.coordinate
        
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpanMake(0.01, 0.01))
        mapView.setRegion(coordinateRegion, animated: true)
        locationManager.stopUpdatingLocation()
    }
    
    @IBAction func tryAgainButtonTapped(_ sender: Any) {
//        mapView.removeAnnotations(mapView.annotations)
        // remove this
        recordIndex = (recordIndex + 1) % eventRecords!.count
        addAnnotation()
//        let eventRecord = eventRecords[recordIndex]
//        titleLabel.text = eventRecord["title"] as? String
//        timeLabel.text = formatter.string(from: eventRecord["time"] as! Date)
//        // set mapView to be location from EventRecord's location
//        coordinates = eventRecord["location"] as! CLLocation
//        print(coordinates.coordinate)
//        createAnnotations(coordinates.coordinate)
    }
    
    @IBAction func confirmButtonTapped(_ sender: Any) {

        let eventRecord = eventRecords![recordIndex]
        
        // generate random catchphrase
        catchPhrase = randomCatchPhrase()
        
        databaseManager.getUserID { (recordID, error) in
            if (error == nil) && (recordID != nil) {
                
                let guest = CKReference(recordID: recordID!, action: .none)
                
                eventRecord["guest"] = guest as CKReference
                
                eventRecord["catchPhrase"] = self.catchPhrase as NSString
                
                self.databaseManager.save(eventRecord: eventRecord) { [weak self] (record, error) in
                    if (error == nil) && (record != nil) {
                        //print(record!["guest"] as! NSString)
                        
                        // guest requests cafe photo
                        let photoRef = record!["cafePhotoRef"]
                        
                        let mapRequestManager = MapRequestManager()
                        
                        mapRequestManager.getPictureRequest(photoRef as? String) { [weak self] (photo) in
                            DispatchQueue.main.async {
                                self?.cafePhoto = photo
                                self?.performSegue(withIdentifier: "goToDetailScreenSegue", sender: self)
                            }
                        }
                        
                    }
                }
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailScreenSegue" {
            let detailViewController = segue.destination as! EventDetailsViewController
            let eventRecord = eventRecords![recordIndex]
            detailViewController.event = eventRecord
            detailViewController.guestStatus = "Your are a confirmed guest!"
            detailViewController.catchPhrase = "Your catchphrase is: \(catchPhrase!)"
            detailViewController.cafePicture = cafePhoto
            detailViewController.databaseManager = databaseManager
        }
    }
    
    //    private func constrainButtons() {
    //        tryAgainButton.translatesAutoresizingMaskIntoConstraints = false
    //        tryAgainButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
    //        tryAgainButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    //        tryAgainButton.widthAnchor.constraint(equalToConstant: self.view.frame.size.width/2).isActive = true
    //        tryAgainButton.heightAnchor.constraint(equalToConstant: 85).isActive = true
    //
    //        confirmButton.translatesAutoresizingMaskIntoConstraints = false
    //        confirmButton.leadingAnchor.constraint(equalTo: tryAgainButton.trailingAnchor).isActive = true
    //        confirmButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    //        confirmButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    //        confirmButton.heightAnchor.constraint(equalToConstant: tryAgainButton.frame.size.height).isActive = true
    //        confirmButton.widthAnchor.constraint(equalToConstant: self.view.frame.size.width/2).isActive = true
    //    }
    
    
    func createAnnotations(_ coordinates:CLLocationCoordinate2D){
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
    }
    
    func randomCatchPhrase() -> String {
        return "random123"
    }
    
}

