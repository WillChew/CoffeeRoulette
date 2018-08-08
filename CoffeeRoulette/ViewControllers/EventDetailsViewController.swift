//
//  EventDetailsViewController.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-07-26.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit
import CloudKit
import MapKit
import ChameleonFramework

class EventDetailsViewController: UIViewController {

    var databaseManager: DatabaseManager!

    var event: CKRecord?

    var cafe: Cafe?
    //var eventTime: Date?
    //var eventLocation: String?
    var cafePicture: UIImage?

    var guestStatus: String!
    var catchPhrase: String!

    @IBOutlet weak var getDirectionsButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var cafeImageView: UIImageView!

    @IBOutlet weak var guestStatusLabel: UILabel!
    @IBOutlet weak var catchPhraseLabel: UILabel!

    @IBOutlet weak var venueImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.view.frame, andColors: [UIColor.black, UIColor(red:0.3, green:0.3, blue:0.3, alpha:1.0)])
        // host and guest both pass event record
        guard let event = event else { return }

        if cafePicture != nil {
            cafeImageView.image = cafePicture
        } else {
            // host passes selected cafe (with photo)
            cafeImageView.image = cafe?.photo
        }


        let date = event["time"] as? Date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        titleLabel.text = event["title"] as? String
        timeLabel.text = formatter.string(from: date!)
        locationLabel.text = event["cafeAddress"] as? String
//        titleLabel
        


        NotificationCenter.default.addObserver(self, selector: #selector(confirmGuest(notfication:)), name: Notification.Name("guestConfirmed"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(goBackToRoulette(notification:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.backgroundColor = UIColor(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.view.frame, andColors: [UIColor.black, UIColor(red:0.3, green:0.3, blue:0.3, alpha:1.0)])
        
        
        // LABEL STYLING
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        timeLabel.textColor = UIColor.white
        
        timeLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        
        locationLabel.textColor = UIColor.white
        locationLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        
        guestStatusLabel.textColor = UIColor.white
        guestStatusLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        guestStatusLabel.lineBreakMode = .byWordWrapping
        guestStatusLabel.numberOfLines = 0
        
        catchPhraseLabel.textColor = UIColor.white
        catchPhraseLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        catchPhraseLabel.lineBreakMode = .byWordWrapping
        catchPhraseLabel.numberOfLines = 0
        
        
        // BUTTON STYLING
        getDirectionsButton.layer.masksToBounds = true
        getDirectionsButton.layer.cornerRadius = 15
        getDirectionsButton.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        getDirectionsButton.layer.borderWidth = 2.5
        //        getDirectionsButton.setTitleColor(UIColor.black, for: .normal).cgColor
        getDirectionsButton.backgroundColor = UIColor(red:0.10, green:0.74, blue:0.61, alpha:1.0)
        getDirectionsButton.translatesAutoresizingMaskIntoConstraints = false
        
        getDirectionsButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        getDirectionsButton.setTitle("Open Directions in Maps", for: UIControlState.normal)
        
        venueImage.layer.borderColor = UIColor(red:0.15, green:0.15, blue:0.15, alpha:1.0).cgColor
        venueImage.layer.borderWidth = 2.5
    }

    @objc func goBackToRoulette(notification: NSNotification) {
        databaseManager.isUserInEvent { [weak self] (record, error) in

            if record != nil {
                print(#line, #function, "we are in an event")
                // stay here
            } else {
                print(#line, #function, "we are not in an event")

                // go back to presenting view controller
                // self?.dismiss(animated: true, completion: nil)

                // go back to roulette view controller
                self?.performSegue(withIdentifier: "unwindToRoulette", sender: nil)
            }
        }
    }

    @objc func confirmGuest(notfication: NSNotification) {
        //view.backgroundColor = UIColor(red:0.10, green:0.74, blue:0.61, alpha:1.0)

        databaseManager.getEvent(recordID: event!.recordID) { (record, error) in

            let word = record!["catchPhrase"] as! String
            self.catchPhrase = "Your catchphrase is: \(word)"
            self.guestStatus = ""

            DispatchQueue.main.async {

                self.catchPhraseLabel.alpha = 0.0
                //self.catchPhraseLabel.textColor = .white
                self.catchPhraseLabel.text = self.catchPhrase

                UIView.animate(withDuration: 2.0, animations: {
                    self.guestStatusLabel.text = self.guestStatus
                    self.guestStatusLabel.alpha = 0.0
                    self.catchPhraseLabel.alpha = 1.0
                })

            }
        }

    }

    deinit {
        NotificationCenter.default.removeObserver(self)


    }



    override func viewDidLayoutSubviews() {
        guestStatusLabel.text = guestStatus
        catchPhraseLabel.text = catchPhrase
    }


    @IBAction func cancelButtonPressed(_ sender: Any) {

    }

    //Get directions
    @IBAction func directionsButtonPressed(_ sender: UIButton) {
        let eventLocation = event!["location"] as? CLLocation
        let cafeName = event!["cafeName"] as? String

        guard let lat = eventLocation?.coordinate.latitude, let lng = eventLocation?.coordinate.longitude else { return }

        let coordinates = CLLocationCoordinate2DMake(lat, lng)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, 1000, 1000)
        let placeMarker = MKPlacemark(coordinate: coordinates)
        let mapItem = MKMapItem(placemark: placeMarker)
        mapItem.name = cafeName
        mapItem.openInMaps(launchOptions:[
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center)
            ] as [String : Any])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "unwindToRoulette" {
            // do i need anything here?
        }
    }


}
