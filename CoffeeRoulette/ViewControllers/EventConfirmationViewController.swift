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
    var makeOwnButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tryAgainButton.layer.cornerRadius = tryAgainButton.frame.height / 2
        confirmButton.layer.cornerRadius = confirmButton.frame.height / 2
        confirmButton.backgroundColor = UIColor(red:0.10, green:0.74, blue:0.61, alpha:1.0)
        
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
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.numberOfLines = 0
            timeLabel.text = ""
            tryAgainButton.isHidden = true
            confirmButton.isHidden = true
            makeButton()
            makeOwnButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20).isActive = true
            return
        }

        for record in eventRecords {
            print(record["title"] as! String)
        }

        if eventRecords.count == 1 {
            tryAgainButton.isHidden = true
            
            makeButton()
            makeOwnButton.widthAnchor.constraint(equalTo: confirmButton.widthAnchor, multiplier: 1).isActive = true
            
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
        /*
         let eventRecord: CKRecord
         
         if (recordIndex == 0) {
         eventRecord = eventRecords![eventRecords!.count - 1]
         } else {
         eventRecord = eventRecords![recordIndex - 1]
         }
         */
        
        let eventRecord = eventRecords![recordIndex]
        
        databaseManager.getUserID { (recordID, error) in
            if (error == nil) && (recordID != nil) {
                
                let guest = CKReference(recordID: recordID!, action: .none)
                
                eventRecord["guest"] = guest as CKReference
                
                self.databaseManager.save(eventRecord: eventRecord) { [weak self] (record, error) in
                    if (error == nil) && (record != nil) {
                        //print(record!["guest"] as! NSString)
                        
                        // guest must request cafe photo
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
            
            /*
             let eventRecord: CKRecord
             
             if (recordIndex == 0) {
             eventRecord = eventRecords![eventRecords!.count - 1]
             } else {
             eventRecord = eventRecords![recordIndex - 1]
             }
             */
            
            let eventRecord = eventRecords![recordIndex]
            
            detailViewController.event = eventRecord
            
            detailViewController.guestStatus = "Your are a confirmed guest!"
            detailViewController.catchPhrase = "Your catchphrase is: petunia"
            
            detailViewController.cafePicture = cafePhoto
            
            //detailViewController.databaseManager = databaseManager
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
    
    func makeButton() {
        makeOwnButton = UIButton()
        makeOwnButton.frame = .zero
        self.view.addSubview(makeOwnButton)
        
        makeOwnButton.setTitle("Make your Own!", for: .normal)
        makeOwnButton.addTarget(self, action: #selector(customButtonAction), for: .touchUpInside)
        makeOwnButton.layer.cornerRadius = 35
        makeOwnButton.setTitleColor(UIColor(red:0.27, green:0.22, blue:0.14, alpha:1.0), for: .normal)
        makeOwnButton.titleLabel?.font = UIFont(name: "Noteworthy-Bold", size: 20)
        makeOwnButton.translatesAutoresizingMaskIntoConstraints = false
        makeOwnButton.heightAnchor.constraint(equalToConstant: 70).isActive = true
        makeOwnButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20).isActive = true
        makeOwnButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30).isActive = true
        makeOwnButton.backgroundColor = UIColor(red:0.75, green:0.63, blue:0.45, alpha:1.0)

    }
    
    @objc func customButtonAction(sender: UIButton!){
        let newEventVC = storyboard?.instantiateViewController(withIdentifier: "NewEventViewController")
        self.navigationController?.pushViewController(newEventVC!, animated: true)
        
    }
    
}

