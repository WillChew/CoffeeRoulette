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

class CoffeeRouletteViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationManager: CLLocationManager!
    var circle: MKCircle!
    var delta : CLLocationDegrees = 0.005
    var currentLocation: CLLocationCoordinate2D!
    var mapRequestManager: MapRequestManager!
    var cafes = [Cafe]()
    var selectedAnnotation: Annotations?
    var eventRecords = [CKRecord]()
    
    var databaseManager = (UIApplication.shared.delegate as! AppDelegate).databaseManager
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var goButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        self.view.backgroundColor = UIColor(patternImage: <#T##UIImage#>)
        
        goButton.backgroundColor = UIColor(red:0.75, green:0.63, blue:0.45, alpha:1.0)
        goButton.setTitleColor(UIColor(red:0.27, green:0.22, blue:0.14, alpha:1.0), for: .normal)
        goButton.layer.cornerRadius = goButton.frame.height / 2
        
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
        
        mapRequest(currentLocation)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGesture)

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
    
    /*CIRCLE STUFF
     mapView.removeOverlays(mapView.overlays)
     //        circle = MKCircle(center: currentLocation, radius: CLLocationDistance(slider.value))
     //
     //        mapView.add(circle)
     */
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.selectedAnnotation = view.annotation as? Annotations
        
    }
    
    @IBAction func goButtonTapped(_ sender: Any) {
        print(#line, "Go button was tapped")
        
        /*
        databaseManager.getEvents { [weak self] (records, error) in
            self?.eventRecords = records!
            DispatchQueue.main.async {
                self?.performSegue(withIdentifier: "goToEventConfirmation", sender: self)
            }
        }
        */
        
        let location = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let radius = 0.5 // in kilometers

        databaseManager.getEventsNearMe(location: location, radius: radius) { [weak self] (records, error) in
            self?.eventRecords = records!
            DispatchQueue.main.async {
                self?.performSegue(withIdentifier: "goToEventConfirmation", sender: self)
            }
        }
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        delta = Double(slider.value)
        mapView.userTrackingMode = .follow
        var currentRegion = self.mapView.region
        currentRegion.span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        self.mapView.region = currentRegion
        
        /* CIRCLE STUFF
         //        mapView.remove(circle)
         //        let newRadius = sender.value
         //        circle = MKCircle(center: currentLocation, radius: CLLocationDistance(newRadius))
         //        mapView.add(circle)
         
         
         //        mapRequestManager.getLocations(currentLocation, radius: newRadius){ (cafeArray) in
         //            self.mapView.removeAnnotations(self.mapView.annotations)
         //            for point in cafeArray {
         //
         //                let annotation = Annotations(title: point.cafeName, coordinate: CLLocationCoordinate2D(latitude: point.location.latitude, longitude: point.location.longitude)) as MKAnnotation
         //                self.mapView.addAnnotation(annotation)
         //            }
         //        }
         */
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
            annotationView?.glyphTintColor = .clear
            
            let markerImage = UIImage(named: "cup")
            let size = CGSize(width: 50, height: 50)
            UIGraphicsBeginImageContext(size)
            markerImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            annotationView?.image = resizedImage
            
            
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    @objc func addAnnotation(gestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        
        let newAnnotation = Annotations(title: "Selected Location", coordinate: CLLocationCoordinate2DMake(newCoordinates.latitude, newCoordinates.longitude), subtitle: "New Starting Point")
        mapView.addAnnotation(newAnnotation)
       

        self.mapRequest(newCoordinates)
            
        
           
        
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
    
    
    //PRAGMA MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
    
    // TODO: DELETE THIS??
    @IBAction func unwindToRandomScreen(segue:UIStoryboardSegue) {
        
    }
    

}






//extension CoffeeRouletteViewController {
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        guard let circleOverlay = overlay as? MKCircle else { return MKOverlayRenderer() }
//        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
//        circleRenderer.fillColor = .red
//        circleRenderer.alpha = 0.1
//        return circleRenderer
//    }
//}
