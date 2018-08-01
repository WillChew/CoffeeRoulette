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
    var databaseManager = DatabaseManager()
    
    
    
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapRequestManager = MapRequestManager()
        locationManager = CLLocationManager()
        mapView.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location?.coordinate
        
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpanMake(delta, delta))
        mapView.setRegion(coordinateRegion, animated: true)
        
        mapRequest(currentLocation)
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
        databaseManager.getEvents { [weak self](records, error) in
            if ((error == nil) && (records != nil)) {
                self?.eventRecords = records!
                DispatchQueue.main.async {
                    self?.performSegue(withIdentifier: "goToEventConfirmation", sender: self)
                }
            }
        }
        
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        
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
        
        mapRequest(newCoordinates)
        
    }
    
    func mapRequest(_ coordinates: CLLocationCoordinate2D) {
        mapRequestManager.getLocations(coordinates, radius: 500) { (mapArray) in
            
            for point in mapArray {
                let annotation = Annotations(title: point.cafeName, coordinate: CLLocationCoordinate2D(latitude: point.location.latitude, longitude: point.location.longitude), subtitle: "Rating: \(String(format:"%.1f", point.rating!))")
                annotation.photoRef = point.photoRef
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    
    //PRAGMA MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCreateSegue" {
            let createViewController = segue.destination as! NewEventViewController
            createViewController.locationManager = locationManager
            createViewController.cafes = self.cafes
        }
        if segue.identifier == "goToEventConfirmation" {
            let eventConfirmationViewController = segue.destination as! EventConfirmationViewController
            eventConfirmationViewController.eventRecords = eventRecords
            
        }
    }
    
    
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
