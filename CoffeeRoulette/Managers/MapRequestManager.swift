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
    static let key = "key"
//    static let api = ""
    static let api = "AIzaSyBPYVobA-0FPMZ00sU-S7MPPSyRyaYOfxM"
    //static let api = "AIzaSyDBkRECsxw7TPdZn3QiJbxX2ImmwedX1lc"
    static let location = "location"
    static let radius = "radius"
    static let keyword = "keyword"
    static let coffee = "coffee"
}
class MapRequestManager {
    
    
    func getLocations(_ currentLocation: CLLocationCoordinate2D, radius: Float, completion: @escaping([Cafe]) -> () ) {
        var cafeArray = [Cafe]()
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let url = URL(string: "https://maps.googleapis.com")!
        
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.path = "/maps/api/place/nearbysearch/json"
        let keyQueryItem = URLQueryItem(name: Constants.key, value: Constants.api)
        let locationQueryItem = URLQueryItem(name: Constants.location, value: "\(currentLocation.latitude),\(currentLocation.longitude)")
        let radiusQueryItem = URLQueryItem(name: Constants.radius, value: "\(radius)")
        let keywordQueryItem = URLQueryItem(name: Constants.keyword, value: Constants.coffee)
        components.queryItems = [keyQueryItem, locationQueryItem, radiusQueryItem, keywordQueryItem]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
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
            let cafes = jsonResult["results"] as! Array<Dictionary<String,Any?>>
            
            for cafe in cafes {
                guard let geometry = cafe["geometry"] as? Dictionary<String,Any?>, let location = geometry["location"] as? Dictionary<String,Any?>, let name = cafe["name"], let photosArray = cafe["photos"] as? Array<Dictionary<String,Any?>> else { return }
                let rating = cafe["rating"] as? Double
                let address = cafe["vicinity"] as? String
                let photoDict = photosArray[0]
                let photoRef = photoDict["photo_reference"] as? String
                let latitude = location["lat"] as! CLLocationDegrees
                let longitude = location["lng"] as! CLLocationDegrees
                let newCafe = Cafe(cafeName: name as! String, location:CLLocationCoordinate2DMake(latitude, longitude))
                newCafe.photoRef = photoRef
                newCafe.rating = rating
                newCafe.address = address
                cafeArray.append(newCafe)

            }
            completion(cafeArray)
        })
        
        
        task.resume()
        session.finishTasksAndInvalidate()
        
    }
    
    func getPictureRequest(_ photoRef: String, completion: @escaping(UIImage) -> ()) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let url = URL(string: "https://maps.googleapis.com")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.path = "/maps/api/place/photo"
        
        let maxWidthQueryItem = URLQueryItem(name: "maxwidth", value: "400")
        let photoReferenceQueryItem = URLQueryItem(name: "photoreference", value: photoRef)
        let keyQueryItem = URLQueryItem(name: "key", value: Constants.api)
        components.queryItems = [maxWidthQueryItem, photoReferenceQueryItem, keyQueryItem]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if error == nil {
                //success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print(#line, "Get photo request success: \(statusCode)")
            } else if let error = error {
                //fail
                print(error.localizedDescription)
            }
            guard let data = data, let image = UIImage(data: data, scale: 1.0) else { return }
            
            
            
            completion(image)
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
}

