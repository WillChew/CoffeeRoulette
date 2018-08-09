//
//  CoffeeRouletteViewController.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-07-26.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import CloudKit
import ChameleonFramework

class CoffeeRouletteViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    private var longPressGesture: UILongPressGestureRecognizer!
    var locationManager: CLLocationManager!
    var circle: MKCircle!
    var delta : CLLocationDegrees = 0.0129654
    var currentLocation: CLLocationCoordinate2D!
    var mapRequestManager: MapRequestManager!
    var cafes = [Cafe]()
    var selectedAnnotation: Annotations?
    var eventRecords = [CKRecord]()
    var event: CKRecord!
    var cafePhoto: UIImage!
    var centerMapButton: UIButton!
    
    var databaseManager = (UIApplication.shared.delegate as! AppDelegate).databaseManager
    
    @IBOutlet weak var mapView: MKMapView!
    
    let splashScreen = UIView()
    
    @IBOutlet weak var rouletteButtonImage: UIImageView!
    @IBOutlet weak var coffeeButtonImage: UIImageView!
    @IBOutlet weak var createEventButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    let spinner = UIActivityIndicatorView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        databaseManager.fetchAllSubscriptions()
        
        
        spinner.hidesWhenStopped = true
        splashScreen.frame = view.frame
        splashScreen.backgroundColor = .black
        view.addSubview(splashScreen)
        splashScreen.addSubview(spinner)
        spinner.startAnimating()
        spinner.center = splashScreen.center
        splashScreen.alpha = 0.75
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        createCenterButton()
        
        self.view.backgroundColor = UIColor(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.view.frame, andColors: [UIColor.black, UIColor(red:0.3, green:0.3, blue:0.3, alpha:1.0)])
        
        let nav = self.navigationController!.navigationBar
        nav.backgroundColor = UIColor.black
        nav.tintColor = UIColor(red:0.96, green:0.96, blue:0.86, alpha:1.0)
        nav.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor(red:0.96, green:0.96, blue:0.86, alpha:1.0)]
        
        goButton.alpha = 0.0
        UIView.animate(withDuration: 1.2, delay: 0.3, options: [], animations: {
            self.goButton.alpha = 1.0
        }, completion: nil)
        
        createEventButton.alpha = 0.0
        UIView.animate(withDuration: 1.2, delay: 0.1, options: [], animations: {
            self.createEventButton.alpha = 1.0
        }, completion: nil)
        
        
        // CHECK IF USER IS SCHEDULED FOR AN UPCOMING EVENT
        databaseManager.isUserInEvent { [weak self] (record, error) in
            
            if let record = record {
                print(#line, #function, "we are in an event")
                self?.event = record
                
                // guest must request cafe photo
                let photoRef = record["cafePhotoRef"]
                
                let mapRequestManager = MapRequestManager()
                
                mapRequestManager.getPictureRequest(photoRef as? String) { [weak self] (photo) in
                    DispatchQueue.main.async {
                        self?.cafePhoto = photo
                        self?.performSegue(withIdentifier: "goToDetailSegue", sender: self)
                    }
                }
                
            } else {
                print(#line, #function, "we are not in an event")
                // stay put!
                DispatchQueue.main.async {
                    self?.spinner.stopAnimating()
                    self?.splashScreen.isHidden = true
                }
            }
            
        }
        
        createEventButton.backgroundColor = UIColor(red:0.96, green:0.96, blue:0.86, alpha:1.0)
        
        
        createEventButton.layer.borderWidth = 2.5
        createEventButton.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        createEventButton.setTitleColor(UIColor(red:0.10, green:0.10, blue:0.10, alpha:1.0), for: .normal)
        
        
        
        
        
        createEventButton.setTitleColor(UIColor(red:0.27, green:0.22, blue:0.14, alpha:1.0), for: .normal)
        createEventButton.layer.cornerRadius = goButton.frame.height / 4
        goButton.backgroundColor = UIColor(red:0.75, green:0.63, blue:0.45, alpha:1.0)
        goButton.setTitleColor(UIColor(red:0.10, green:0.10, blue:0.10, alpha:1.0), for: .normal)
        goButton.layer.cornerRadius = goButton.frame.height / 4
        goButton.layer.borderWidth = 2.5
        goButton.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        mapView.layer.borderWidth = 2.5
        mapView.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        
        
        //check if user is in an event
        UserDefaults.standard.set(false, forKey: "isInEvent")
        let inEvent = UserDefaults.standard.bool(forKey: "isInEvent")
        if inEvent {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let eventDetailViewController = storyboard.instantiateViewController(withIdentifier: "EventDetailsViewController")
            self.present(eventDetailViewController, animated: false, completion: nil)
        }
        
        mapRequestManager = MapRequestManager()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        mapView.delegate = self
        
        
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
            currentLocation = locationManager.location?.coordinate
            
            
        }
        mapView.removeOverlays(mapView.overlays)
        circle = MKCircle(center: currentLocation, radius: 500)
        
        mapView.add(circle)
        
        mapRequest(currentLocation)
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGesture)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        spinner.stopAnimating()
        splashScreen.isHidden = true
    }
    
    
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
        
    }
    
    @IBAction func goButtonTapped(_ sender: Any) {
        print(#line, "Go button was tapped")
        
        let location = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let radius = 0.5 // in kilometers
        
        databaseManager.getEventsNearMe(location: location, radius: radius) { [weak self] (records, error) in
            self?.eventRecords = records!
            DispatchQueue.main.async {
                self?.performSegue(withIdentifier: "goToEventConfirmation", sender: self)
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
            annotationView?.backgroundColor = .clear
            annotationView?.glyphTintColor = .clear
            annotationView?.tintColor = .clear
            
            
            
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
    
    func mapRequest(_ coordinates: CLLocationCoordinate2D) {
        
        mapRequestManager.getLocations(coordinates, radius: 500) { (mapArray) in
            print(#line, "number of cafes found on map request", mapArray.count)
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
    
    
    //PRAGMA MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailSegue" {
            let detailViewController = segue.destination as! EventDetailsViewController
            detailViewController.event = event
            
            let catchPhrase = event["catchPhrase"] as? String
            
            
            if catchPhrase! == "" {
                // host has created an event but no guest has confirmed
                detailViewController.guestStatus = "No guest yet"
                detailViewController.catchPhrase = ""
            } else {
                // host and guest see the same thing
                detailViewController.guestStatus = ""
                detailViewController.catchPhrase = "Your catchphrase is: \(catchPhrase!)"
            }
            
            
            
            detailViewController.cafePicture = cafePhoto
            detailViewController.databaseManager = databaseManager
            
        }
        if segue.identifier == "goToCreateSegue" {
            let createViewController = segue.destination as! NewEventViewController
            createViewController.databaseManager = databaseManager
            createViewController.locationManager = locationManager
            createViewController.cafes = self.cafes
        }
        if segue.identifier == "goToEventConfirmation" {
            let eventConfirmationViewController = segue.destination as! EventConfirmationViewController
            eventConfirmationViewController.eventRecords = eventRecords
            eventConfirmationViewController.locationManager = locationManager
            eventConfirmationViewController.databaseManager = databaseManager
            
        }
    }
    
    @IBAction func unwindToRoulette(segue: UIStoryboardSegue) {
        
    }
    
    func createCenterButton() {
        centerMapButton = UIButton()
        self.mapView.userTrackingMode = .none
        centerMapButton.frame = .zero
        self.view.addSubview(centerMapButton)
        centerMapButton.backgroundColor = .clear
        centerMapButton.translatesAutoresizingMaskIntoConstraints = false
        centerMapButton.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: -15).isActive = true
        centerMapButton.centerXAnchor.constraint(equalTo: coffeeButtonImage.centerXAnchor).isActive = true
        centerMapButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        centerMapButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        centerMapButton.setImage(UIImage(named: "marker"), for: .normal)
        centerMapButton.addTarget(self, action: #selector(centerMap), for: .touchUpInside)
    }
    
    @objc func centerMap() {
        self.mapView.userTrackingMode = .follow
        mapRequest(currentLocation)
    }
    
    
}


extension CoffeeRouletteViewController {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else { return MKOverlayRenderer() }
        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
        
        circleRenderer.fillColor = UIColor(red:0.10, green:0.74, blue:0.61, alpha:0.1)
        mapView.tintColor = UIColor(red:0.91, green:0.73, blue:0.47, alpha:1.0)
        
        circleRenderer.alpha = 0.9
        circleRenderer.strokeColor = UIColor(red:0.10, green:0.74, blue:0.61, alpha:1.0)
        circleRenderer.lineWidth = 1
        
        
        return circleRenderer
    }
}
