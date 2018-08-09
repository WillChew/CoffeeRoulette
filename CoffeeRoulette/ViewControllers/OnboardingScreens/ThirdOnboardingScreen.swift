//
//  ThirdOnboardingScreen.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-08-01.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit
import CoreLocation
import ChameleonFramework


class ThirdOnboardingScreen: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var getStartedButton: UIButton!
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.view.frame, andColors: [UIColor.black, UIColor(red:0.3, green:0.3, blue:0.3, alpha:1.0)])
        
        getStartedButton.backgroundColor = UIColor(red:0.75, green:0.63, blue:0.45, alpha:1.0)
        getStartedButton.setTitleColor(UIColor(red:0.27, green:0.22, blue:0.14, alpha:1.0), for: .normal)
        
        getStartedButton.layer.borderWidth = 2.5
        
        getStartedButton.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        
        getStartedButton.layer.cornerRadius = getStartedButton.frame.height / 4
        
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func getStartedButtonPressed(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: "hasLaunched")
    }
    
}
