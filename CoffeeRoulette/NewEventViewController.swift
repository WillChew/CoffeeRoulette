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

class NewEventViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate {
    
    var locationManager: CLLocationManager!
    var cafes = [Cafe]()
    var currentLocation: CLLocationCoordinate2D!
    var delta: CLLocationDegrees = 0.006
    var mapRequestManager: MapRequestManager!
    var selectedAnnotation: Annotations?
    var cafeSelectedCoordinates: CLLocationCoordinate2D!
    var datePickerView: UIDatePicker!
    var time: TimeInterval!
    var selectedCafe: Cafe!
    
    
    @IBOutlet weak var cafeLabel: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeTextField.delegate = self
        mapView.delegate = self
        datePickerView = UIDatePicker.init()
        timeTextField.inputView = datePickerView
        datePickerView.datePickerMode = .time
        
        
        mapRequestManager = MapRequestManager()
        locationManager = CLLocationManager()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
            
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTap(gesture:)))
            view.addGestureRecognizer(gestureRecognizer)
            
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(gestureRecognizer:)))
            longPressGesture.minimumPressDuration = 1.0
            
            mapView.addGestureRecognizer(longPressGesture)
            
        }
        cafeLabel.isHidden = true
        saveButton.isEnabled = false
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mapView.removeFromSuperview()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location?.coordinate
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpanMake(delta, delta))
        self.mapView.setRegion(coordinateRegion, animated: true)
        self.mapView.showsUserLocation = true
        
        mapRequest(currentLocation)

        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.selectedAnnotation = view.annotation as? Annotations
        cafeSelectedCoordinates = self.selectedAnnotation?.coordinate
        
        selectedCafe = Cafe(cafeName: (selectedAnnotation?.title)!, location: CLLocationCoordinate2DMake(cafeSelectedCoordinates.latitude, cafeSelectedCoordinates.longitude))
        selectedCafe.photoRef = self.selectedAnnotation?.photoRef
        
        cafeLabel.isHidden = false
        cafeLabel.text = selectedCafe.cafeName
        changeSaveButton()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func timeTextFieldSelected(_ sender: UITextField) {
        
        let calendar = Calendar.current
        let todayNow = Date()
        let todayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: todayNow)
        
        
        datePickerView.maximumDate = todayEnd
        datePickerView.minimumDate = todayNow
        
        datePickerView.minuteInterval = 5
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(NewEventViewController.datePickerValueChanged), for: UIControlEvents.valueChanged)
        
    }
    
    
    @objc func datePickerValueChanged(sender:UIDatePicker) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeTextField.text = formatter.string(from: sender.date)
        time = sender.date.timeIntervalSince1970
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
            detailViewController.eventTitle = titleTextField.text
            detailViewController.eventTime = time
            
        }
    }
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        guard let photoRef = selectedCafe.photoRef else { return }
        mapRequestManager.getPictureRequest(photoRef){ (photo) in
            self.selectedCafe.photo = photo
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "goToDetailScreenSegue", sender: self)
                
            }
        }
    }
    
    // Gestures
    @objc func addAnnotation(gestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        
        let newAnnotation = Annotations(title: "Selected Location", coordinate: CLLocationCoordinate2DMake(newCoordinates.latitude, newCoordinates.longitude))
        mapView.addAnnotation(newAnnotation)
        
        mapRequest(newCoordinates)
        
    }
    
    @objc func backgroundTap(gesture: UITapGestureRecognizer) {
        timeTextField.resignFirstResponder()
        titleTextField.resignFirstResponder()
        mapView.isHidden = false
    }
    
    //Other Functions
    func mapRequest(_ coordinates: CLLocationCoordinate2D) {
        mapRequestManager.getLocations(coordinates, radius: 500) { (mapArray) in
            
            for point in mapArray {
                let annotation = Annotations(title: point.cafeName, coordinate: CLLocationCoordinate2D(latitude: point.location.latitude, longitude: point.location.longitude))
                annotation.photoRef = point.photoRef
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func changeSaveButton() {
        if timeTextField != nil && titleTextField != nil && selectedCafe != nil {
            saveButton.isEnabled = true
        }
    }
    
    
    
    
}
