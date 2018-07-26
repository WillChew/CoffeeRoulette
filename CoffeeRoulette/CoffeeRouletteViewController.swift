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

class CoffeeRouletteViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager!
    var circle: MKCircle!
    var delta : CLLocationDegrees = 0.01
    var currentLocation: CLLocationCoordinate2D!
    

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        // Do any additional setup after loading the view, typically from a nib.
            locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location?.coordinate
//        print("locations = \(currentLocation.latitude) \(currentLocation.longitude)")
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpanMake(delta, delta))
        mapView.setRegion(coordinateRegion, animated: true)
//        mapView.removeOverlays(mapView.overlays)
//        circle = MKCircle(center: currentLocation, radius: CLLocationDistance(slider.value))
//        
//        mapView.add(circle)
        
        
        
    }
    
    @IBAction func sliderChanged(_ sender: Any) {
        circle = MKCircle(center: currentLocation, radius: CLLocationDistance(slider.value))
    }
}

//extension CoffeeRouletteViewController: MKMapViewDelegate {
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        guard let circleOverlay = overlay as? MKCircle else { return MKOverlayRenderer() }
//        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
//        circleRenderer.strokeColor = .red
//        circleRenderer.fillColor = .red
//        circleRenderer.alpha = 0.2
//        return circleRenderer
//    }
//}













