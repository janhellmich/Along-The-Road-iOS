//
//  RestaurantDataModel.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 9/7/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//
//  This model handles processing the data so that it is easier to work
//  with later on. 

import UIKit
import CoreLocation
class RestaurantDataModel: NSObject {
    class var sharedInstance: RestaurantDataModel {
        struct Static {
            static var instance: RestaurantDataModel?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = RestaurantDataModel()
        }
        
        return Static.instance!
    }
    
    var restaurants = [AnyObject]()
    var restaurantDictionary = [String: AnyObject]()
    
    override init () {
        
    }
    /* function: addRestaurants
     * -------------------------
     * This function takes in a dataObj returned from the Four square api query. It then processes the 
     * data passed in and stores it based on its key value pairs in the restaurant dictionry. It also 
     * eliminates all the repeats and selects the one with the closer proximity to the route
    */
    func addRestaurants (dataObj: [AnyObject]?) {
        //Add the restaurants to the restaurants array
        var restaurantArray = [AnyObject]()
        for i in 0..<dataObj!.count {
            restaurantArray.append(dataObj![i].objectForKey("venue")!)
        }
        
        //Create annotations for each restaurant that was found
        //This section needs to later be modified to deal with possible nil values
        for i in 0..<restaurantArray.count  {
            var currentVenue : AnyObject = restaurantArray[i]
            var coord = CLLocationCoordinate2D()
            coord.latitude = currentVenue.objectForKey("location")!.objectForKey("lat") as!Double
            coord.longitude = currentVenue.objectForKey("location")!.objectForKey("lng") as! Double
            var title = currentVenue.objectForKey("name") as! String
            
            //Insanely sketchy logic but don't worry about it
            var rating = 0.0
            if var otherRating: AnyObject = currentVenue.objectForKey("rating")  {
                rating = otherRating as! Double
            }
            if self.restaurantDictionary["\(coord.latitude),\(coord.longitude)"] == nil {
                self.restaurantDictionary["\(coord.latitude),\(coord.longitude)"] = restaurantArray[i]
            } else { //check which one is closer and add that one
                
            }
        }
    }
}
