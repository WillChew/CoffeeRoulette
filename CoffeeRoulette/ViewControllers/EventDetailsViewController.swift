//
//  EventDetailsViewController.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-07-26.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit
import MapKit

class EventDetailsViewController: UIViewController {
    
    var cafe: Cafe?
    var eventTitle: String?
    var eventTime: Date?
    var eventLocation: String?
    var cafePicture: UIImage?
    
    var guestStatus: String?
    var catchPhrase: String?
    
    
    //placeholder values
    let latitude = 43.6456
    let longitude = -79.3954
    let name = "Quantum"
    
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var cafeImageView: UIImageView!
    
    @IBOutlet weak var guestStatusLabel: UILabel!
    @IBOutlet weak var catchPhraseLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let eventTime = eventTime else { return }
       let date = eventTime
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let eventDateTime = formatter.string(from: date)
        
        titleLabel.text = eventTitle
        timeLabel.text = eventDateTime
        locationLabel.text = eventLocation
        cafeImageView.image = cafe?.photo
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "goToMainScreen", sender: self)
    }
    @IBAction func directionsButtonPressed(_ sender: UIButton) {
        
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, 1000, 1000)
        let placeMarker = MKPlacemark(coordinate: coordinates)
        let mapItem = MKMapItem(placemark: placeMarker)
        mapItem.name = name
        mapItem.openInMaps(launchOptions:[
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center)
            ] as [String : Any])
        
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
