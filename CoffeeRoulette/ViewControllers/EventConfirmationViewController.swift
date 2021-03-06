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
import ChameleonFramework

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
    var makeOwnButton: UIButton!
    var selectedCafe: CKRecord!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        mapView.delegate = self
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }
        
        
        mapView.showsUserLocation = true
        
        guard eventRecords.count > 0 else {
            titleLabel.text = "No events found at this time. Try again later, or create your own event!"
            titleLabel.textColor = UIColor.white
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.numberOfLines = 0
            timeLabel.text = ""
            tryAgainButton.isHidden = true
            confirmButton.isHidden = true
            makeButton()
            makeOwnButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: 0).isActive = true
            makeOwnButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 0).isActive = true
            makeOwnButton.alpha = 0.0
            UIView.animate(withDuration: 1.2, delay: 0.1, options: [], animations: {
                self.makeOwnButton.alpha = 1.0
            }, completion: nil)
            return
        }
        
        for record in eventRecords {
            print(record["title"] as! String)
            selectedCafe = record
        }
        
        if eventRecords.count == 1 {
            tryAgainButton.isHidden = true
            
            makeButton()
            makeOwnButton.widthAnchor.constraint(equalTo: confirmButton.widthAnchor, multiplier: 1).isActive = true
            makeOwnButton.heightAnchor.constraint(equalTo: confirmButton.heightAnchor, multiplier: 1).isActive = true
            
        }
        
        eventRecords.shuffle()
        

        addAnnotation()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
        
    }
    
    func addAnnotation() {
        formatter.timeStyle = .short
        formatter.dateStyle = .medium

        let eventRecord = eventRecords[recordIndex]
        titleLabel.text = eventRecord["title"] as? String
        timeLabel.text = formatter.string(from: eventRecord["time"] as! Date)
        print(formatter.string(from: eventRecord["time"] as! Date))
        coordinates = eventRecord["location"] as? CLLocation
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
            annotationView?.markerTintColor = UIColor(red:0.04, green:0.73, blue:0.71, alpha:1)
            
            
            
            
        } else {
            annotationView?.annotation = annotation
            
        }
        return annotationView
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location?.coordinate
        
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(coordinateRegion, animated: true)
        locationManager.stopUpdatingLocation()
    }
    
    @IBAction func tryAgainButtonTapped(_ sender: Any) {
        
        
        recordIndex = (recordIndex + 1) % eventRecords!.count
        addAnnotation()
        
    }
    
    @IBAction func confirmButtonTapped(_ sender: Any) {
        
        let eventRecord = eventRecords![recordIndex]
        
        // generate random catchphrase
        catchPhrase = randomCatchPhrase()
        
        databaseManager.getUserID { (recordID, error) in
            if (error == nil) && (recordID != nil) {
                
                let guest = CKRecord.Reference(recordID: recordID!, action: .none)
                
                eventRecord["guest"] = guest as CKRecord.Reference
                
                eventRecord["catchPhrase"] = self.catchPhrase as NSString
                
                self.databaseManager.save(eventRecord: eventRecord) { [weak self] (record, error) in
                    if (error == nil) && (record != nil) {
                        let predicate = NSPredicate(format: "recordID = %@", (record?.recordID)!)
                        let subscription = CKQuerySubscription(recordType: "Event", predicate: predicate, options: [.firesOnRecordDeletion, .firesOnce])
                        
                        let info = CKSubscription.NotificationInfo()
                        let title = record!["title"] as! String
                        info.title = title
                        info.alertBody = "Host Cancelled"
                        info.soundName = "default"
                        subscription.notificationInfo = info
                        
                        self?.databaseManager.save(subscription: subscription, completion: { (subscription, error) in
                            print("Subscription saved")
                        })
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
            detailViewController.guestStatus = "You are a confirmed guest!"
            detailViewController.catchPhrase = "Your catchphrase is: \(catchPhrase!)"
            detailViewController.cafePicture = cafePhoto
            detailViewController.databaseManager = databaseManager
        }
    }
    
    
    func createAnnotations(_ coordinates:CLLocationCoordinate2D){
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
        annotation.title = selectedCafe["cafeName"]
        annotation.subtitle = selectedCafe["cafeAddress"]
        
    }
    
    
    func randomCatchPhrase() -> String {
        let catchphraseArray  = ["\nWhat’s your favorite way to waste time?", "\nWhat’s the worst movie you have seen recently?", "\nWhat is the silliest fear you have?", "\nWhat flavor of ice cream do you wish existed?", "\nWhat would you rate 10 / 10?", "\nWhat is the most impressive thing you know how to do?", "\nWhat is the strangest thing you have come across?", "\nWhat gets you fired up?"]
        let randomNumber = arc4random_uniform(UInt32(catchphraseArray.count))
        
        return catchphraseArray[Int(randomNumber)]
    }
    
    func makeButton() {
        makeOwnButton = UIButton()
        self.view.addSubview(makeOwnButton)
        makeOwnButton.layer.masksToBounds = true
        makeOwnButton.layer.cornerRadius = 15
        
        
        makeOwnButton.setTitle("Make Your Own!", for: .normal)
        makeOwnButton.addTarget(self, action: #selector(customButtonAction), for: .touchUpInside)
        makeOwnButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 21)
        makeOwnButton.setTitleColor(.black, for: .normal)
        
        
        makeOwnButton.translatesAutoresizingMaskIntoConstraints = false
        makeOwnButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        makeOwnButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20).isActive = true
        makeOwnButton.bottomAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 0).isActive = true
        makeOwnButton.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 20).isActive = true
        makeOwnButton.backgroundColor = UIColor(red:0.96, green:0.96, blue:0.86, alpha:1.0)
        
        
        makeOwnButton.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        makeOwnButton.layer.borderWidth = 2.5
        makeOwnButton.setTitleColor(UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0), for: .normal)
        makeOwnButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        
        tryAgainButton.layer.cornerRadius = 15
        confirmButton.layer.cornerRadius = 15
        confirmButton.backgroundColor = UIColor(red:0.10, green:0.74, blue:0.61, alpha:1.0)

        tryAgainButton.layer.masksToBounds = true
        tryAgainButton.layer.cornerRadius = tryAgainButton.frame.height / 4
        tryAgainButton.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        tryAgainButton.layer.borderWidth = 2.5
        tryAgainButton.setTitleColor(UIColor.black, for: .normal)
        tryAgainButton.backgroundColor = UIColor(red:0.96, green:0.96, blue:0.86, alpha:1.0)
        tryAgainButton.alpha = 0.0
        UIView.animate(withDuration: 1.2, delay: 0.1, options: [], animations: {
            self.tryAgainButton.alpha = 1.0
        }, completion: nil)
        
        confirmButton.layer.masksToBounds = true
        confirmButton.layer.cornerRadius = confirmButton.frame.height / 4
        confirmButton.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        confirmButton.layer.borderWidth = 2.5
        confirmButton.setTitleColor(UIColor.black, for: .normal)
        confirmButton.backgroundColor = UIColor(red:0.75, green:0.63, blue:0.45, alpha:1.0)
        confirmButton.alpha = 0.0
        UIView.animate(withDuration: 1.2, delay: 0.3, options: [], animations: {
            self.confirmButton.alpha = 1.0
        }, completion: nil)
        
        
    }
    
    @objc func customButtonAction(sender: UIButton!){
        let newEventVC = storyboard?.instantiateViewController(withIdentifier: "NewEventViewController")
        self.navigationController?.pushViewController(newEventVC!, animated: true)
        
        
    }
    
    fileprivate func setupView() {
        let nav = self.navigationController?.navigationBar
        nav?.tintColor = UIColor.white
        nav?.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        self.view.backgroundColor = UIColor(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.view.frame, andColors: [UIColor.black, UIColor(red:0.3, green:0.3, blue:0.3, alpha:1.0)])
        
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        timeLabel.textColor = UIColor.white
        timeLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        
        
        
        mapView.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        mapView.layer.borderWidth = 2.5
    }
    
 
    
}
