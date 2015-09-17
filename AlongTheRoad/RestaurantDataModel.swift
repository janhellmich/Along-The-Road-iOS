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
import Foundation
import MapKit

class RestaurantDataModel: NSObject {

    static let sharedInstance = RestaurantDataModel()
    
    var startingPoint: CLLocationCoordinate2D
    var restaurants: [RestaurantStructure]
    var restaurantDictionary: [String: RestaurantStructure]
    var selectedRestaurant: RestaurantStructure
    var restaurantsToAddToMap: [RestaurantStructure]
    var filteredRestaurants: [RestaurantStructure]
    
    var mapHelpers = MapHelpers()
    

    override init () {
        restaurantDictionary = [String: RestaurantStructure]()
        restaurants = [RestaurantStructure]()
        startingPoint = CLLocationCoordinate2D()
        selectedRestaurant = RestaurantStructure()
        restaurantsToAddToMap = [RestaurantStructure]()
        filteredRestaurants = [RestaurantStructure]()

    }
    
    
    func addStartingPoint (startingCoords: CLLocationCoordinate2D) {
        startingPoint = startingCoords;
    }
    
    
    /* function: addRestaurants
     * -------------------------
     * This function takes in a dataObj returned from the Four square api query. It then processes the 
     * data passed in and stores it based on its key value pairs in the restaurant dictionry. It also 
     * eliminates all the repeats and selects the one with the closer proximity to the route
    */
    
    func addRestaurants (dataObj: AnyObject?, waypointDistance: Double) -> [RestaurantStructure] {
        restaurantsToAddToMap = [RestaurantStructure]()
        //Add the restaurants to the restaurants array
        var restaurantArray = [AnyObject]()
        for i in 0..<dataObj!.count {
            restaurantArray.append(dataObj![i].objectForKey("venue")!)
        }
        
        
        //Create annotations for each restaurant that was found
        //This section needs to later be modified to deal with possible nil values
        for i in 0..<restaurantArray.count  {
            var restaurant = createRestaurantObject(restaurantArray[i], waypointDistance: waypointDistance)
            if restaurantDictionary["\(restaurant.location.latitude),\(restaurant.location.longitude)"] == nil {
                restaurantDictionary["\(restaurant.location.latitude),\(restaurant.location.longitude)"] = restaurant
                restaurantsToAddToMap.append(restaurant)
            } 
        }
        return restaurantsToAddToMap
    }
    
    func convertToArray () {
        restaurants = [RestaurantStructure]()
        for (key,value) in restaurantDictionary {
            restaurants.append(value)
        }
    }
    
    func reset () {
        restaurantDictionary = [String: RestaurantStructure]()
        restaurants = [RestaurantStructure]()
    }
    
    
    func createRestaurantObject(venue: AnyObject, waypointDistance: Double) -> RestaurantStructure {
        var name = getName(venue)
        var address = getAddress(venue)
        var distanceToRoad = getDistanceToRoad(venue)
        var imageUrl = getImageUrl(venue)
        var openUntil = getOpenUntil(venue)
        var rating = getRating(venue)
        var priceRange = getPriceRange(venue)
        var location = getLocation(venue)
        var url = getUrl(venue)
        var streetAddress = getStreetAddress(venue)
        var city = getCity(venue)
        var state = getState(venue)
        var zip = getZip(venue)
        //println("WAYPOINTDISTANCE: \(waypointDistance)")
        var distance = waypointDistance + distanceToRoad // meters
        
        // consider pricerange of 3 and 4 equally due to limited space in filter page
        if (priceRange == 4) {
            priceRange = 3
        }
        
        var restaurant = RestaurantStructure(name: name,  url: url, imageUrl: imageUrl, distanceToRoad: distanceToRoad, address: address, totalDistance: distance, openUntil: openUntil, rating: rating, priceRange: priceRange, location: location, streetAddress: streetAddress, city: city, state: state, postalCode: zip)
        
        return restaurant
    }
    
    func sortRestaurantsByRating () {
        filteredRestaurants.sort({$0.rating > $1.rating})
    }
    
    func sortRestaurantsByDistance() {
        filteredRestaurants.sort({$1.totalDistance > $0.totalDistance})

    }
    
    func getStreetAddress(currentVenue: AnyObject) -> String {
        if var street: AnyObject = currentVenue.objectForKey("location")!.objectForKey("address") {
            return street as! String
        }
        return ""
        
    }
    func getCity(currentVenue: AnyObject) -> String {
        if var city: AnyObject = currentVenue.objectForKey("location")!.objectForKey("city") {
            return city as! String
        }
        return ""
        

    }
    func getState(currentVenue: AnyObject) -> String {
        if var state: AnyObject = currentVenue.objectForKey("location")!.objectForKey("state") {
                return state as! String
            }
        
        return ""
    }
    func getZip(currentVenue: AnyObject) -> String {
        if let zip: AnyObject = currentVenue.objectForKey("location")!.objectForKey("postalCode") {
            return zip as! String
        }
        return ""
    }
    func getName (currentVenue: AnyObject) -> String {
        var name = currentVenue.objectForKey("name") as! String

        return name
        
    }
    /* function: getLocation
    * ----------------------
    * This function extracts the data from the currentVenue for the location and address.
    * It returns as string for the current address
    */
    func getAddress (currentVenue: AnyObject) -> String {
        var address = ""
        var addexists:AnyObject? = currentVenue.objectForKey("location")?.objectForKey("address")
        if addexists != nil {
            address += addexists as! String + ", "
        }
        
        var city:AnyObject? = currentVenue.objectForKey("location")?.objectForKey("city")
        if city != nil {
            address += city as! String + ", "
        }
        
        var state: AnyObject? = currentVenue.objectForKey("location")?.objectForKey("state")
        if state != nil {
            address += state as! String
        }
        return  address
    }
    
//    func getTotalDistance(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> Double {
//        var req = MKDirectionsRequest()
//        
//        req.setDestination(end)
//        req.setSource(start)
//        req.transportType = MKDirectionsTransportType.Automobile
//        
//        var directions = MKDirections(request: req)
//        
//        directions.calculateDirectionsWithCompletionHandler({ (response: MKDirectionsResponse!, error: NSError!) -> Void in
//            if error != nil {
//                println("Directions failed with error: \(error.localizedDescription), trying again")
//                self.getDirections()
//            } else {
//                self.setNewRegion()
//                self.routeData.routes = response.routes
//                self.displayRoutes(0)
//                self.generateSegmentControl()
//                
//                // add go button to view
//                var rightAddBarButtonItem:UIBarButtonItem = UIBarButtonItem(title: "GO!", style: UIBarButtonItemStyle.Plain, target: self, action: "clickGo")
//                self.navigationItem.rightBarButtonItem = rightAddBarButtonItem
//            }
//        });
//
//    }
    
    func getUrl (currentVenue: AnyObject) -> String {
        let restaurantName = currentVenue.objectForKey("name") as! String
        let restaurantID = currentVenue.objectForKey("id") as! String
        
        var nameArr = split(restaurantName){$0 ==  " "}
        var newName = "-".join(nameArr)

        return "https://foursquare.com/v/\(newName)/\(restaurantID)"
    }
    
    /* function: getDistance
    * ----------------------
    * This function extracts the data from the currentVenue for the distance from the road.
    * It returns as string formatted in miles for how far from the route the restaurant is
    */
    func getDistanceToRoad (currentVenue: AnyObject) -> Double {
        var distanceMeters = currentVenue.objectForKey("location")?.objectForKey("distance") as! Double
        return distanceMeters
    }
    

    func getImageUrl (currentVenue: AnyObject) -> String {
        var imageItems: AnyObject? = currentVenue.objectForKey("featuredPhotos")?.objectForKey("items")?[0]
        var prefix: AnyObject? = imageItems?.objectForKey("prefix")
        var suffix: AnyObject?=imageItems?.objectForKey("suffix")
        
        
        var url: String = ""
        if  prefix != nil && suffix != nil {
            url = "\(prefix as! String)110x110\(suffix as! String)"
        }
        return url
    }
    
    
    /* function: getOpenUntil
    * ----------------------
    * This function extracts the data from the currentVenue for when it is open and
    * returns a string showing when the store is open until or closed if it is closed
    */
    func getOpenUntil (currentVenue: AnyObject) -> String {
        var open: AnyObject? = currentVenue.objectForKey("hours")?.objectForKey("isOpen")
        if open != nil && open as! Int  == 0 {
            return "Closed"
        }
        
        var status: AnyObject? = currentVenue.objectForKey("hours")?.objectForKey("status")
        if status != nil {
            return status as! String
        }
        return " "
    }
    

    func getRating (currentVenue: AnyObject) -> Double {
        var ratingObj: AnyObject? = currentVenue.objectForKey("rating")
        
        if ratingObj != nil {
            var temp = ratingObj as! Double
            return temp
        }
        return 0.0
    }

    
    func getPriceRange (currentVenue: AnyObject) -> Int{
        var price: AnyObject? = currentVenue.objectForKey("price")?.objectForKey("tier")
        if price != nil {
            var newPrice = price as! Int

            return newPrice
        }
        return 0
    }
    
    func getLocation (currentVenue: AnyObject) -> CLLocationCoordinate2D {
        var coord = CLLocationCoordinate2D()
        coord.latitude = currentVenue.objectForKey("location")!.objectForKey("lat") as!Double
        coord.longitude = currentVenue.objectForKey("location")!.objectForKey("lng") as! Double
        return coord
    }
    
    
    
//    func getTotalDistance(currentVenue: AnyObject) -> Double {
//        var lat1 = startingPoint.latitude;
//        var lat2 = currentVenue.objectForKey("location")!.objectForKey("lat") as!Double
//        var lon1 = startingPoint.longitude
//        var lon2 = currentVenue.objectForKey("location")!.objectForKey("lng") as!Double
//
//        
//        func DegreesToRadians (value:Double) -> Double {
//            return value * M_PI / 180.0
//        }
//        
//        var R:Double = 6371000 // metres
//        var latRad1 = DegreesToRadians(lat1)
//        var latRad2 = DegreesToRadians(lat2)
//        var change1 = DegreesToRadians(lat2-lat1)
//        var change2 = DegreesToRadians(lon2-lon1)
//        
//        var l = Double(sin(change1/2) * sin(change1/2))
//        var k = Double(cos(latRad1) * cos(latRad2) *
//            sin(change2/2) * sin(change2/2))
//        
//        var a = Double( l + k)
//        
//        var c = 2 * atan2(sqrt(a), sqrt(1-a));
//        
//        var d = R * c;
//        return d
//    }

}
