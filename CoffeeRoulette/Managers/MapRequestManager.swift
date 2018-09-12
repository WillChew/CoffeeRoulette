//
//  MapRequestManager.swift
//  CoffeeRoulette
//
//  Created by Will Chew on 2018-07-30.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import UIKit
import CoreLocation

enum Constants {
    
    static let authorization = "Authorization"
    static let key = "Bearer QCsxzDpQvN4jHRQjPxszCt55RVndyUZI6sOQZ1xF_sHk_ewwXItiHEOxV3IoKOcsdbfNbnrBZbew8a2PLjf2qe0VRBou758RWt5PYJ5iQz8u3amGTSgQokeug1MtW3Yx"
    static let radius = "radius"
    static let term = "term"
    static let coffee = "cafe"
    static let latitude = "latitude"
    static let longitude = "longitude"

}
class MapRequestManager {
    
    
    func getLocations(_ currentLocation: CLLocationCoordinate2D, radius: Int, completion: @escaping([Cafe]) -> () ) {
        var cafeArray = [Cafe]()
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let url = URL(string: "https://api.yelp.com")!
        
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.path = "/v3/businesses/search"

        let latitudeQueryItem = URLQueryItem(name: Constants.latitude, value: "\(currentLocation.latitude)")
        let longitudeQueryItem = URLQueryItem(name: Constants.longitude, value: "\(currentLocation.longitude)")
        let radiusQueryItem = URLQueryItem(name: Constants.radius, value: "\(radius)")
        let keywordQueryItem = URLQueryItem(name: Constants.term, value: Constants.coffee)
        components.queryItems = [latitudeQueryItem, longitudeQueryItem, radiusQueryItem, keywordQueryItem]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.addValue(Constants.key, forHTTPHeaderField: Constants.authorization)
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                //success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print(#line, "Success: \(statusCode)")
            } else if let error = error {
                //error
                print(#line, error.localizedDescription)
            }
            
            guard let data = data else { return }
            guard let jsonResult = try! JSONSerialization.jsonObject(with: data) as? Dictionary<String,Any?> else { return }
            let cafes = jsonResult["businesses"] as! Array<Dictionary<String,Any?>>
            
            for cafe in cafes {

                guard let coordinates = cafe["coordinates"] as? Dictionary<String,Any?>, let name = cafe["name"], let location = cafe["location"] as? Dictionary<String,Any?> else { return }
                let rating = cafe["rating"] as? Double
                let lat = coordinates["latitude"] as! CLLocationDegrees
                let lng = coordinates["longitude"] as! CLLocationDegrees
                let photo = cafe["image_url"] as? String
                let address = location["address1"] as? String
                let cafeCoordinates = CLLocationCoordinate2DMake(lat, lng)
                let newCafe = Cafe(cafeName: name as! String, location: cafeCoordinates)
                newCafe.photoRef = photo
                newCafe.rating = rating
                newCafe.address = address
                cafeArray.append(newCafe)
                
                
            }
            completion(cafeArray)
        })
        
        
        task.resume()
        session.finishTasksAndInvalidate()
        
    }
    
    func getPictureRequest(_ photoRef: String?, completion: @escaping(UIImage) -> ()) {
        // handle dummy image
        guard let photoRef = photoRef else {
            let cup = UIImage(named: "cup.png")
            completion(cup!)
            return
        }

//            guard let data = data, let image = UIImage(data: data, scale: 1.0) else { return }
        guard let imageURL = URL(string: photoRef), let imageData = try? Data(contentsOf: imageURL), let image = UIImage(data: imageData) else { return }
        
        
            
            
            completion(image)
        }

    }
    


