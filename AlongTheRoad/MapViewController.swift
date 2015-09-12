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

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    //This represent the shared data model
    let routeData = RouteDataModel.sharedInstance
    let dataProcessor = RouteDataFilter.sharedInstance
    let restaurantData = RestaurantDataModel.sharedInstance

    //These represent the location and map based variables
    var coreLocationManager = CLLocationManager()
    var locationManager:LocationManager!
    var startItem: MKMapItem?
    var destinationItem: MKMapItem?
    var annotations:[MKPointAnnotation] = [] //This is an array of the annotations on the map
    var userLocation: CLLocationCoordinate2D? //This will later be instantiated with the user's current location
    
    //API Keys for FourSquare
    let CLIENT_ID="ELLZUH013LMEXWRWGBOSNBTXE3NV02IUUO3ZFPVFFSZYLA30"
    let CLIENT_SECRET="U2EQ1N1J4EAG4XH4QO4HCZTGM3FCWDLXU2WJ0OPTD2Q3YUKF"

    
    
    //These three outlets correspond to the view itself. They permit the controller to access these components
    @IBOutlet weak var map: MKMapView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        coreLocationManager.delegate = self
        self.displayLocation()
        
        var rightAddBarButtonItem:UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "list"), style: UIBarButtonItemStyle.Plain, target: self, action: "showListView")
        self.navigationItem.rightBarButtonItem = rightAddBarButtonItem

        
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
    
    override func viewWillAppear(animated: Bool) {
        
        // check that the initial load has happened
        if self.destinationItem != nil {
            map.removeAnnotations(annotations)
            println("# of Annotations \(annotations.count)")
            println("# of Filtered \(restaurantData.filteredRestaurants.count)")
            println("# of Total Restauratants \(restaurantData.restaurants.count)")
            self.createAnnotation(self.startItem!.placemark.location.coordinate, title: "Start", subtitle: "")
            self.createAnnotation(self.destinationItem!.placemark.location.coordinate, title: "Destination", subtitle: "")
            
            for venue in restaurantData.filteredRestaurants {
                createAnnotation(venue.location, title: venue.name, subtitle: "Rating: \(venue.rating)")
            }
        }
        
    }
    
    func showListView() {
        self.performSegueWithIdentifier("show-list", sender: nil)
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
            self.userLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    /* function: displayLocation
     * ---------------------------------------
     * This function is called once the current location has been established. It creates and adds
     * the map items to the map and then uses the two to find the directions between
     * the two addresses
    */
    func displayLocation(){
        self.addMapItem( "Start", address: routeData.startingPoint)
        self.addMapItem( "Destination", address: routeData.destination)
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
            if error != nil {
                println("Geocode failed with error: \(error.localizedDescription)")
            } else if placemarks.count > 0 {
                let place = placemarks[0] as! CLPlacemark
            
                let location = place.location
                
                var mkplace = MKPlacemark(placemark: place)
                
                self.createAnnotation(mkplace.coordinate, title: type, subtitle: "")
                
                if type == "Start" {
                    self.restaurantData.startingPoint = mkplace.coordinate // Required for searching by distance
                    self.startItem = MKMapItem(placemark: mkplace)
                } else if type == "Destination" {
                    self.destinationItem = MKMapItem(placemark: mkplace)
                }
                
                if (self.startItem != nil && self.destinationItem != nil) {
                    self.displayRoute()
                    self.setNewRegion()
                }
            }
        })
    }

    // display the selected route and make api requests
    func displayRoute() {
        var route = routeData.route!
        var querries = self.dataProcessor.getSections(self.routeData.route!)
 
        for i in 0..<querries.count {
            self.sendFourSquareRequest(querries[i].latitude, long: querries[i].longitude)
        }
        
        self.map.addOverlay(route.polyline, level:MKOverlayLevel.AboveLabels)
    }
    
    
    // sets the renderForOverlay delegate method
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        
        if overlay is MKPolyline {
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 6
            return polylineRenderer
        } 
        return nil
    }

    

    
    /* function: setNewRegion
     * ----------------------
     * This function will reorient the view so that it fits both the starting point and the end
     * of the given route. It will work by finding the furthest out longitude and latitude and then
     * set the map to fit around all of these. It should also include annotations later on.
    */
    func setNewRegion () {
        //Extract the coord
        var startCoord = self.startItem?.placemark.coordinate
        var destCoord = self.destinationItem?.placemark.coordinate
        //All elements to be displayed on the map need to be placed in this array
        var locations = [startCoord!, destCoord!]
        


        var region = self.dataProcessor.findRegion(locations)
        
        //Currently calls sendFourSquare request on
        self.map.setRegion(region, animated: false)
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
        self.annotations.append(annotation)
        self.map.addAnnotation(annotation)
    }
    
    /* function: sendFourSquareRequest
     * -------------------------------
     * This is a sample request to the four square api. It takes in a latitude and a longitude and display all the
     * best restaurants found by the four square api in that area. For now it just displays them as annotations
     * with the name and ratings but can later be modified for filters and further functionallity
    */
    func sendFourSquareRequest (lat: Double, long: Double) {
        
        var url = NSURL(string: "https://api.foursquare.com/v2/venues/explore?client_id=\(self.CLIENT_ID)&client_secret=\(self.CLIENT_SECRET)&v=20130815&ll=\(lat),\(long)&&venuePhotos=1&&openNow=1")//&&openNow=1)")//&&section=\(routeData.searchSection)")
        var req = NSURLRequest(URL: url!)
        NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            var parseError: NSError?
            //Early exit for error
            if error != nil {
                return
            }
            //Section that extracts the desired data from the responce
            let parsedObject :AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error:&parseError)
            var dataObj : AnyObject? = parsedObject?.objectForKey("response")?.objectForKey("groups")?[0].objectForKey("items")!
            
            //Early exit if there is not valid data passed back
            if dataObj == nil {
                return
            }
            
            //Add the restaurants to the restaurants array
            var restaurantArray = [AnyObject]()
            
            var newlyAdded = self.restaurantData.addRestaurants(dataObj)
            
            //This section checks if it is the last query and then adds the annotation to the map
            for i in 0..<newlyAdded.count  {
                var currentVenue = newlyAdded[i]
                var coord = currentVenue.location
                var title = currentVenue.name
                
                var rating = currentVenue.rating
                self.createAnnotation(coord, title: title, subtitle: "Rating: \(rating)")
            }
           
            //self.map.showAnnotations(self.annotations, animated: true)
        }
    }
    
}