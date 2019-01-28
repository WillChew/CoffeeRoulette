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
import ChameleonFramework

class NewEventViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate {
    
    var locationManager: CLLocationManager!
    var cafes = [Cafe]()
    var currentLocation: CLLocationCoordinate2D!
    var delta: CLLocationDegrees = 0.0129654
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
    var activityIndicator = UIActivityIndicatorView(style: .gray)
    
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cafeLabel: UILabel!
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
        
        setupView()
        locationManager = CLLocationManager()
        if databaseManager == nil {
            databaseManager = (UIApplication.shared.delegate as! AppDelegate).databaseManager
        }
        
        
        timeTextField.delegate = self
        mapView.delegate = self
        
        self.timeTextField.delegate = self
        datePickerView.datePickerMode = .time
        locationManager.delegate = self
        
        
       
        
        
        mapRequestManager = MapRequestManager()
        if CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
            currentLocation = locationManager.location?.coordinate
            
            self.mapView.region = MKCoordinateRegion.init(center: currentLocation, span: MKCoordinateSpan.init(latitudeDelta: delta, longitudeDelta: delta))
            
        }
        
        mapRequest(currentLocation)
       
        
        databaseManager.getUserID { (recordID, error) in
            if (error == nil), let recordID = recordID {
                self.userID = recordID.recordName
            }
        }
        
    }
    
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if currentLocation == nil {
            self.currentLocation = locations.first?.coordinate
            self.mapView.showsUserLocation = true
        }
        
        
        currentLocation = manager.location?.coordinate
        
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan.init(latitudeDelta: delta, longitudeDelta: delta))
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
            selectedCafe.address = self.selectedAnnotation?.address
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
        sender.inputView? = datePickerView
        datePickerView.backgroundColor = UIColor(red:0.75, green:0.63, blue:0.45, alpha:1.0)
        
        
        datePickerView.minuteInterval = 5
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(NewEventViewController.datePickerValueChanged), for: UIControl.Event.valueChanged)
    }
    

    

    
    
    @IBAction func saveButtonPressed(_ sender: UIButton!) {
        print("create button clicked")
        
        // start activity indicator (let user know this could take a while)
        view.addSubview(activityIndicator)
        activityIndicator.frame(forAlignmentRect: CGRect(x: 0, y: 0, width: 100, height: 100))
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        
        // make a new event with title, time and cafe
        event = Event(title: titleTextField.text!, time: time, cafe: selectedCafe)
        
        event.catchPhrase = ""
        
        // get cafe photo from photo reference
        
        guard let photoRef = selectedCafe.photoRef else { return }
        
        mapRequestManager.getPictureRequest(photoRef){ [weak self] (photo) in
            
            // add photo to selected cafe
            self?.selectedCafe.photo = photo
            
            // add photo to event
            self?.event.cafe.photo = photo
            
            self?.databaseManager.save(event: (self?.event!)!) { [weak self] (record, error) in
                
                if (error == nil), let record = record {
                    self?.eventRecord = record
                    
                    // save subscription to changes on my event (guest confirmation)
                    let predicate = NSPredicate(format: "recordID = %@", record.recordID)
                    
                    let subscription = CKQuerySubscription(recordType: "Event", predicate: predicate, options: [.firesOnRecordUpdate, .firesOnce])
                    
                    let subscriptionDelete = CKQuerySubscription(recordType: "Event", predicate: predicate, options: [.firesOnRecordDeletion, .firesOnce])
                    
                    
                    
                    let info = CKSubscription.NotificationInfo()
                    let title = record["title"] as! String
                    info.title = title
                    info.alertBody = "Guest Confirmed. Open app for more info"
                    info.soundName = "default"
                    subscription.notificationInfo = info
                    
                    let infoDelete = CKSubscription.NotificationInfo()
                    infoDelete.title = title
                    infoDelete.alertBody = "Guest Cancelled. Open app to create new event. Press Cancel on old event if necessary"
                    infoDelete.soundName = "default"
                    subscriptionDelete.notificationInfo = infoDelete
                    
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
                    self?.databaseManager.save(subscription: subscriptionDelete, completion: { (subscription, error) in
                        NSLog("subscription saved", subscription!.subscriptionID)
                    })
                }
            }
        }
    }
    
    
    //MARK: Gestures
    @objc func addAnnotation(gestureRecognizer: UILongPressGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        
        self.mapRequest(newCoordinates)
        longPressGesture.isEnabled = false
        longPressGesture.isEnabled = true
        
        
        
    }
    
    @objc func backgroundTap(gesture: UITapGestureRecognizer) {
        timeTextField.resignFirstResponder()
        titleTextField.resignFirstResponder()
        mapView.isHidden = false
    }
    
    //MARK: Other Functions
    
    @objc func datePickerValueChanged(sender:UIDatePicker) {
        timeTextField.text = formatter.string(from: sender.date)
        time = sender.date
        print(#line, time)
    }
    
    func setupView(){
        datePickerView = UIDatePicker.init()
        timeTextField.inputView = datePickerView
        let nav = self.navigationController?.navigationBar
        nav?.tintColor = UIColor.white
        nav?.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name:"HelveticaNeue", size: 21)!]
        
        self.view.backgroundColor = UIColor(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.view.frame, andColors: [UIColor.black, UIColor(red:0.3, green:0.3, blue:0.3, alpha:1.0)])
        
        timeTextField.layer.masksToBounds = true
        timeTextField.layer.cornerRadius = timeTextField.frame.height / 4
        timeTextField.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        timeTextField.layer.borderWidth = 2.0
        
        
        titleTextField.layer.masksToBounds = true
        titleTextField.layer.cornerRadius = titleTextField.frame.height / 4
        titleTextField.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        titleTextField.layer.borderWidth = 2.0
        
        
        saveButton.backgroundColor = UIColor(red:0.75, green:0.63, blue:0.45, alpha:1.0)
        saveButton.layer.cornerRadius = saveButton.frame.height / 4
        saveButton.layer.borderWidth = 2.5
        saveButton.setTitleColor(UIColor.black, for: .normal)
        saveButton.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        mapView.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        mapView.layer.borderWidth = 2.5
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTap(gesture:)))
        view.addGestureRecognizer(gestureRecognizer)
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 0.5
        
        
        mapView.addGestureRecognizer(longPressGesture)
        
        cafeLabel.isHidden = true
        saveButton.isEnabled = false
        formatter.timeStyle = .short
    }
    
    
    func changeSaveButton() {
        if timeTextField.text != "" && titleTextField.text != "" && selectedCafe != nil {
            saveButton.isEnabled = true
        }
    }
    
    func mapRequest(_ coordinates: CLLocationCoordinate2D) {
        
        mapRequestManager.getLocations(coordinates, radius: 500) { (mapArray) in
            
            for point in mapArray {
                guard let address = point.address else { return }
                let annotation = Annotations(title: point.cafeName, coordinate: CLLocationCoordinate2D(latitude: point.location.latitude, longitude: point.location.longitude), subtitle: "Location: \(address)")
                annotation.photoRef = point.photoRef
                annotation.address = point.address
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
            
            let markerImage = UIImage(named: "Icon-App-40x40")
            UIGraphicsBeginImageContext((markerImage?.size)!)
            markerImage!.draw(in: CGRect(x: 0, y: 0, width: (markerImage?.size.width)!, height: (markerImage?.size.height)!))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
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
        centerMapButton.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: -15).isActive = true
        centerMapButton.trailingAnchor.constraint(equalTo: self.mapView.trailingAnchor, constant: -15).isActive = true
        centerMapButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        centerMapButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        centerMapButton.setImage(UIImage(named: "marker"), for: .normal)
        centerMapButton.addTarget(self, action: #selector(centerMap), for: .touchUpInside)
    }
    
    @objc func centerMap() {
        self.mapView.userTrackingMode = .follow
        mapRequest(currentLocation)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailScreenSegue" {
            let detailViewController = segue.destination as! EventDetailsViewController
            detailViewController.cafe = selectedCafe
            detailViewController.event = eventRecord
            detailViewController.guestStatus = "No guest yet"
            detailViewController.catchPhrase = ""
            detailViewController.databaseManager = databaseManager
        }
    }
    
}
