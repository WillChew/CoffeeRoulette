//
//  NewEventViewController.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-07-26.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CloudKit

class NewEventViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate {
    
    var locationManager: CLLocationManager!
    var cafes = [Cafe]()
    var currentLocation: CLLocationCoordinate2D!
    var delta: CLLocationDegrees = 0.005
    var mapRequestManager: MapRequestManager!
    var selectedAnnotation: Annotations?
    var cafeSelectedCoordinates: CLLocationCoordinate2D!
    var datePickerView: UIDatePicker!
    var time: Date!
    var selectedCafe: Cafe!
    let formatter = DateFormatter()
    var databaseManager: DatabaseManager!
    var event: Event!
    var eventRecord: CKRecord?
    var userID: String?
    var longPressGesture: UILongPressGestureRecognizer!
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    
    @IBOutlet weak var cafeLabel: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        createCenterButton()

    }
      
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager = CLLocationManager()
        if databaseManager == nil {
            databaseManager = (UIApplication.shared.delegate as! AppDelegate).databaseManager
        }
        
        timeTextField.delegate = self
        mapView.delegate = self
        datePickerView = UIDatePicker.init()
        timeTextField.inputView = datePickerView
        self.timeTextField.delegate = self
        datePickerView.datePickerMode = .time
        locationManager.delegate = self
        
        
        mapRequestManager = MapRequestManager()
        if CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
            currentLocation = locationManager.location?.coordinate
            
            self.mapView.region = MKCoordinateRegionMake(currentLocation, MKCoordinateSpanMake(delta, delta))
            
        }
        
        mapRequest(currentLocation)
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTap(gesture:)))
        view.addGestureRecognizer(gestureRecognizer)
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 1.0
        longPressGesture.allowableMovement = 0
        
        mapView.addGestureRecognizer(longPressGesture)
        
        cafeLabel.isHidden = true
        saveButton.isEnabled = false
        formatter.timeStyle = .short
        
        databaseManager.getUserID { (recordID, error) in
            if (error == nil), let recordID = recordID {
                self.userID = recordID.recordName
            }
        }
        
    }
    
    //    override func viewWillDisappear(_ animated: Bool) {
    //        super.viewWillDisappear(animated)
    //        mapView.removeFromSuperview()
    //    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if currentLocation == nil {
            self.currentLocation = locations.first?.coordinate
            self.mapView.showsUserLocation = true
        }
        
        
        currentLocation = manager.location?.coordinate
        
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpanMake(delta, delta))
        mapView.setRegion(coordinateRegion, animated: true)
        
        
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
       
        self.selectedAnnotation = view.annotation as? Annotations
        
        if selectedAnnotation == nil { selectedCafe = nil;
            cafeLabel.text = "Your Current Location";
            saveButton.isEnabled = false
            return
        } else {
            
        cafeSelectedCoordinates = self.selectedAnnotation?.coordinate
        
         selectedCafe = Cafe(cafeName: (selectedAnnotation?.title)!, location: CLLocationCoordinate2DMake(cafeSelectedCoordinates.latitude, cafeSelectedCoordinates.longitude))
        
        selectedCafe.photoRef = self.selectedAnnotation?.photoRef
        
        cafeLabel.isHidden = false
        cafeLabel.text = selectedCafe.cafeName
        changeSaveButton()
        }
    }
    
    @IBAction func timeTextFieldSelected(_ sender: UITextField) {
        
        let calendar = Calendar.current
        let todayNow = Date()
        let todayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: todayNow)
        
        
        datePickerView.maximumDate = todayEnd
        datePickerView.minimumDate = todayNow
        // WHY CAN'T WE CHANGE THE BACKGROUND COLOR???
        sender.inputView? = datePickerView
        //sender.inputView?.backgroundColor = .clear
        datePickerView.backgroundColor = UIColor(red:0.75, green:0.63, blue:0.45, alpha:1.0)
        
        
        datePickerView.minuteInterval = 5
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(NewEventViewController.datePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    
    
    @objc func datePickerValueChanged(sender:UIDatePicker) {
        timeTextField.text = formatter.string(from: sender.date)
        time = sender.date
        print(#line, time)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailScreenSegue" {
            let detailViewController = segue.destination as! EventDetailsViewController
            detailViewController.cafe = selectedCafe 
            detailViewController.event = eventRecord
            detailViewController.guestStatus = "No guest yet"
            detailViewController.catchPhrase = "Your catchphrase is: ____"
            //detailViewController.databaseManager = databaseManager
        }
    }
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        print("create button clicked")
        
        // start activity indicator (let user know this could take a while)
        view.addSubview(activityIndicator)
        activityIndicator.frame(forAlignmentRect: CGRect(x: 0, y: 0, width: 100, height: 100))
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        
        // make a new event with title, time and cafe
        event = Event(title: titleTextField.text!, time: time, cafe: selectedCafe)
        
        // get cafe photo from photo reference
        
        // TODO: USE A PLACEHOLDER IF NO PHOTO REFERENCE/PHOTO
        guard let photoRef = selectedCafe.photoRef else { return }
        
        mapRequestManager.getPictureRequest(photoRef){ [weak self] (photo) in
            
            // add photo to selected cafe
            self?.selectedCafe.photo = photo
            
            // add photo to event
            self?.event.cafe.photo = photo
            
            self?.databaseManager.save(event: (self?.event!)!) { [weak self] (record, error) in
                
                if (error == nil), let record = record {
                    self?.eventRecord = record
                    
                    // save subscription to changes on my event (FIX THIS)
                    let subscription = CKQuerySubscription(recordType: "Event", predicate: NSPredicate(value: true), options: [.firesOnRecordUpdate])

                    let info = CKNotificationInfo()
                    let title = record["title"] as! String
                    info.title = title
                    info.alertBody = "Guest confirmed"
                    subscription.notificationInfo = info
                    
                    self?.databaseManager.save(subscription: subscription) { [weak self] (subscription, error) in
                        if ((error == nil) && (subscription != nil)) {
                            NSLog("subscription saved", subscription!.subscriptionID)
                            
                            DispatchQueue.main.async {
                                self?.activityIndicator.stopAnimating()
                                self?.activityIndicator.removeFromSuperview()
                                self?.performSegue(withIdentifier: "goToDetailScreenSegue", sender: self)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    // Gestures
    @objc func addAnnotation(gestureRecognizer: UILongPressGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        
        let newAnnotation = Annotations(title: "Selected Location", coordinate: CLLocationCoordinate2DMake(newCoordinates.latitude, newCoordinates.longitude), subtitle: "New Starting Point")
        mapView.addAnnotation(newAnnotation)
        longPressGesture.isEnabled = false
        longPressGesture.isEnabled = true

        self.mapRequest(newCoordinates)
        
    }
    
    @objc func backgroundTap(gesture: UITapGestureRecognizer) {
        timeTextField.resignFirstResponder()
        titleTextField.resignFirstResponder()
        mapView.isHidden = false
    }
    
    // Other Functions
    func changeSaveButton() {
        if timeTextField.text != "" && titleTextField.text != "" && selectedCafe != nil {
            saveButton.isEnabled = true
        }
    }
    
    func mapRequest(_ coordinates: CLLocationCoordinate2D) {
        
        mapRequestManager.getLocations(coordinates, radius: 500) { (mapArray) in
            
            for point in mapArray {
                let annotation = Annotations(title: point.cafeName, coordinate: CLLocationCoordinate2D(latitude: point.location.latitude, longitude: point.location.longitude), subtitle: "Rating: \(String(format:"%.1f", point.rating!))")
                annotation.photoRef = point.photoRef
                DispatchQueue.main.async {
                    self.mapView.addAnnotation(annotation)
                    
                    
                }
                self.locationManager.stopUpdatingLocation()
                
            }
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        let identifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIView()
            annotationView?.markerTintColor = .clear
            
            let markerImage = UIImage(named: "cup")
            //            let size = CGSize(width: 50, height: 50)
            UIGraphicsBeginImageContext((markerImage?.size)!)
            markerImage!.draw(in: CGRect(x: 0, y: 0, width: (markerImage?.size.width)!, height: (markerImage?.size.height)!))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
//            let markerImage = UIImage(named: "cup")
//            let size = CGSize(width: 50, height: 50)
//            UIGraphicsBeginImageContext(size)
//            markerImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
//            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            annotationView?.image = resizedImage
            
            
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    func createCenterButton() {
        let centerMapButton = UIButton()
        centerMapButton.frame = .zero
        self.mapView.addSubview(centerMapButton)
        centerMapButton.backgroundColor = .clear
        centerMapButton.translatesAutoresizingMaskIntoConstraints = false
        centerMapButton.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: -10).isActive = true
        centerMapButton.trailingAnchor.constraint(equalTo: self.mapView.trailingAnchor, constant: -10).isActive = true
        centerMapButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        centerMapButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        
        
        
        centerMapButton.setImage(UIImage(named: "center"), for: .normal)
        centerMapButton.addTarget(self, action: #selector(centerMap), for: .touchUpInside)
    }
    
    @objc func centerMap() {
        self.mapView.userTrackingMode = .follow
    }
    
}
