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

    //These represent the location and map based variables
    var coreLocationManager = CLLocationManager()
    var locationManager:LocationManager!
    var startItem: MKMapItem?
    var destinationItem: MKMapItem?
    var annotations:[MKPointAnnotation]? //This is an array of the annotations on the map
    var userLocation: CLLocationCoordinate2D? //This will later be instantiated with the user's current location
    
    
    //API Keys for FourSquare
    let CLIENT_ID="ELLZUH013LMEXWRWGBOSNBTXE3NV02IUUO3ZFPVFFSZYLA30"
    let CLIENT_SECRET="U2EQ1N1J4EAG4XH4QO4HCZTGM3FCWDLXU2WJ0OPTD2Q3YUKF"

    
    
    //These three outlets correspond to the view itself. They permit the controller to access these components
    @IBOutlet weak var destLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var map: MKMapView!
    
    
    /* function:
     * ------------------------------------
     *
     *
     *
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        coreLocationManager.delegate = self
        self.destLabel.text = routeData.destination
        self.startLabel.text = routeData.startingPoint
        
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
        }
    }
    
    /* function: displayLocation
     * ---------------------------------------
     * This function is called once the current location has been established. It creates and adds
     * the map items to the map and then uses the two to find the directions between
     * the two addresses
    */
    func displayLocation(location:CLLocation){
        self.addMapItem( "Start", address: routeData.destination)
        self.addMapItem( "Destination", address: routeData.startingPoint)
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
                    self.startItem = MKMapItem(placemark: mkplace)
                } else {
                    self.destinationItem = MKMapItem(placemark: mkplace)
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
        self.annotations?.append(annotation)
        self.map.addAnnotation(annotation)
    }
    
    /* function: sendFourSquareRequest
     * -------------------------------
     * This is a sample request to the four square api. It takes in a latitude and a longitude and display all the
     * best restaurants found by the four square api in that area. For now it just displays them as annotations
     * with the name and ratings but can later be modified for filters and further functionallity
    */
    func sendFourSquareRequest (lat: Double, long: Double) {
        
       
        var url = NSURL(string: "https://api.foursquare.com/v2/venues/explore?client_id=\(self.CLIENT_ID)&client_secret=\(self.CLIENT_SECRET)&v=20130815&ll=\(lat),\(long)&&venuePhotos=1")//)&&radius=\(routeData.searchRadius)&&section=\(routeData.searchSection)")
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
                
                self.routeData.restaurantDictionary["\(coord.latitude),\(coord.longitude)"] = restaurantArray[i]
                self.createAnnotation(coord, title: title, subtitle: "Rating: \(rating)")
            }
           
            //Add the restaurans to the array
//            self.routeData.restaurants += restaurantArray;
            //Render the pins on the map
            self.map.showAnnotations(self.annotations, animated: true)
        }
    }
    
}