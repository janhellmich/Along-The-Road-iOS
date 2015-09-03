//
//  GoogleMapViewController.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 8/29/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AddressBook

class MapViewController: UIViewController, CLLocationManagerDelegate {

    var destination: String?
    var startingPoint: String?
    
    var coreLocationManager = CLLocationManager()
    var locationManager:LocationManager!
    var startItem: MKMapItem?
    var destinationItem: MKMapItem?
    var annotations:[MKPointAnnotation]?
    var coords: CLLocationCoordinate2D?
    var userLocation: CLLocationCoordinate2D?
    
    //API Keys for FourSquare
    let CLIENT_ID="ELLZUH013LMEXWRWGBOSNBTXE3NV02IUUO3ZFPVFFSZYLA30"
    let CLIENT_SECRET="2DMIIPTIXZHNUR1P1IMY4SPKVE2LEKNZVJWFJYHWZP5GGTZM"
    
    
    //These three outlets correspond to the view itself. They permit the controller to access these components
    @IBOutlet weak var destLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        coreLocationManager.delegate = self
        self.destLabel.text = self.destination
        self.startLabel.text = self.startingPoint
        
        locationManager = LocationManager.sharedInstance
        
        let authorizationCode = CLLocationManager.authorizationStatus()
        if authorizationCode == CLAuthorizationStatus.NotDetermined && coreLocationManager.respondsToSelector("requestAlwaysAuthorization") || coreLocationManager.respondsToSelector("requestWhenInUseAuthorization") {
            if NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationAlwaysUsageDescription") != nil {
                coreLocationManager.requestAlwaysAuthorization()
            } else {
                getLocation()
            }
        }
    }

    /* function: locationManager
    * ---------------------------------------
    * The locationManager is a function that is automatically invoked when current location
    * is searched for
    *
    */
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != CLAuthorizationStatus.NotDetermined || status != CLAuthorizationStatus.Denied || status != CLAuthorizationStatus.Restricted {
            getLocation()
        }
    }
    
    /* function: getLocation
    * ---------------------------------------
    * This function beggins checking for the users current location. It starts updating the
    * users movements, which can be modified to allow for the users location to be allowed
    * as a starting point
    */
    func getLocation(){
        locationManager.startUpdatingLocationWithCompletionHandler { (latitude, longitude, status, verboseMessage, error) -> () in
            self.displayLocation(CLLocation(latitude: latitude, longitude: longitude))
            self.userLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            print(self.userLocation!)
        
        }
    }
    
    /* function: displayLocation
     * ---------------------------------------
     * This function is called once the current location has been established. It creates and adds
     * the map items to the map and then uses the two to find the directions between
     * the two addresses
    */
    func displayLocation(location:CLLocation){
        let destination = self.destination!
        let start = self.startingPoint!
        self.addMapItem( "startItem", address: start)
        self.addMapItem( "end", address: destination)
    }
    
    /* function: addMapItem
    * ---------------------------------------
    * This function geocodes the address string. This means that it querries the apple database
    * for where that address is located geographically. It then selects the most likely result
    * and uses it to create a map item. If the map item is the destination, then it will invoke
    * the getDirections method which will find the directions and update the map
    */
    func addMapItem (type: String, address: String){
        let geoCoder = CLGeocoder()

        geoCoder.geocodeAddressString(address, completionHandler: { (placemarks: [AnyObject]!, error: NSError!) -> Void in
            print("ran")
            if error != nil {
                println("Geocode failed with error: \(error.localizedDescription)")
            } else if placemarks.count > 0 {
                let place = placemarks[0] as! CLPlacemark
            
                let location = place.location
                self.coords = location.coordinate
                
                var mkplace = MKPlacemark(placemark: place)
                
                self.createAnnotation(mkplace.coordinate, title: "", subtitle: "")
                
                if type == "startItem" {
                    self.startItem = MKMapItem(placemark: mkplace)
                } else {
                    self.destinationItem = MKMapItem(placemark: mkplace)
                    self.getDirections()
                }
            }
        })
    }
    
    /* function: getDirections
    * ---------------------------------------
    * This function uses the two location mapItems to determine the best route.
    * If there is an error in searching for the directions, then it will recursively call itself.
    * This is meant to deal with the way apple maps sends error messages for correct routes about
    * Half the time. However, for invaldid addresses
    */
    func getDirections() {
        var req = MKDirectionsRequest()
        
        req.setDestination(self.destinationItem)
        req.setSource(self.startItem)
        req.transportType = MKDirectionsTransportType.Automobile
        self.map.showAnnotations(self.annotations, animated: true)
        
        var directions = MKDirections(request: req)
        
        directions.calculateDirectionsWithCompletionHandler({ (response: MKDirectionsResponse!, error: NSError!) -> Void in
            if error != nil {
                println("Directions failed with error: \(error.localizedDescription), trying again")
                self.getDirections()
            } else {
                var route = response.routes[0] as! MKRoute
                var steps = route.steps
                
                for(var i = 0 ; i < steps.count ; i++ ) {
                    println(steps[i].instructions)
                }
                print(route.polyline)
                 self.setNewRegion()
                //This portion is meant to display the polyline object. It currently does not work
                // self.map.rendererForOverlay(route.polyline)
                self.map.addOverlay(route.polyline, level: MKOverlayLevel.AboveRoads)
            }
        });
    }
    
    /* function: setNewRegion
     * ----------------------
     * This function will reorient the view so that it fits both the starting point and the end
     * of the given route. It will work by finding the furthest out longitude and latitude and then
     * set the map to fit around all of these. It should also include annotations later on.
    */
    func setNewRegion () {
        var startCoord = self.startItem?.placemark.coordinate
        var destCoord = self.destinationItem?.placemark.coordinate
        var locations = [startCoord!, destCoord!] //First place all needed coordinates into this array
        
        var upperLimit = CLLocationCoordinate2D(latitude: -90, longitude: -90)
        var lowerLimit = CLLocationCoordinate2D(latitude: 90, longitude: 90)
        
        for(var i = 0 ; i < locations.count ; i++ ) {
            if(locations[i].latitude > upperLimit.latitude) {
                upperLimit.latitude = locations[i].latitude
            }
            if(locations[i].latitude < lowerLimit.latitude) {
                lowerLimit.latitude = locations[i].latitude
            }
            if(locations[i].longitude > upperLimit.longitude) {
                upperLimit.longitude = locations[i].longitude
            }
            if(locations[i].longitude < lowerLimit.longitude) {
                lowerLimit.longitude = locations[i].longitude
            }
        }
        
        
        var locationSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1 )
        locationSpan.longitudeDelta = (upperLimit.longitude - lowerLimit.longitude)
        locationSpan.latitudeDelta = (upperLimit.latitude - lowerLimit.latitude)
        
        var center = CLLocationCoordinate2D()
        center.latitude = (upperLimit.latitude + lowerLimit.latitude)/2
        center.longitude = (upperLimit.longitude + lowerLimit.longitude)/2
        
        var region = MKCoordinateRegion(center: center, span: locationSpan)
        
        //Currently calls sendFourSquare request on
        sendFourSquareRequest(center.latitude, long: center.longitude)
        self.map.setRegion(region, animated: true)
    }
    
    
    /* function: createAnnotation
     * ---------------------------
     * This function will take in a title, a subtitle and a CLLCoordinate and will
     * create an annotation for those values. It will then add it to the map and 
     * also add it to the annotations array.
    */
    
    func createAnnotation (coord: CLLocationCoordinate2D, title: String, subtitle: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coord
        annotation.title = title
        annotation.subtitle = subtitle
        self.annotations?.append(annotation)
        self.map.addAnnotation(annotation)
    }
    
    /* function: sendFourSquareRequest
     * -------------------------------
     * This is a sample request to the four square api. It currently just prints a list of results 
     * for the passed in latitude and longitude.
     *
    */
    func sendFourSquareRequest (lat: Double, long: Double) {
        
        var url = NSURL(string: "https://api.foursquare.com/v2/venues/explore?client_id=\(self.CLIENT_ID)&client_secret=\(self.CLIENT_SECRET)&v=20130815&ll=\(lat),\(long)")
        var req = NSURLRequest(URL: url!)
        
        NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            var parseError: NSError?
            let parsedObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error:&parseError)
            var dataObj = parsedObject!.objectForKey("response")!.objectForKey("groups")![0].objectForKey("items")!
            // println(dataObj)
            var restaurantArray = [AnyObject]()
            for i in 0..<dataObj.count {
                restaurantArray.append(dataObj[i].objectForKey("venue")!)
            }
            
            for i in 0..<restaurantArray.count  {
                var currentVenue = restaurantArray[i]
                var coord = CLLocationCoordinate2D()
                coord.latitude = currentVenue.objectForKey("location")!.objectForKey("lat") as!Double
                coord.longitude = currentVenue.objectForKey("location")!.objectForKey("lng") as! Double
                var title = currentVenue.objectForKey("name") as! String
                var rating =  currentVenue.objectForKey("rating") as! Double
                
                self.createAnnotation(coord, title: title, subtitle: "Rating: \(rating)")
                
            }
            self.map.showAnnotations(self.annotations, animated: true)
            print(restaurantArray[0])
        }
    }
    
}