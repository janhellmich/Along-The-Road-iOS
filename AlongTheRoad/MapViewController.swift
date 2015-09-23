//
//  MapViewController.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 8/29/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AddressBook

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    let venueDetailHelpers = RestaurantTableView()

    //This represent the shared data model
    let routeData = RouteDataModel.sharedInstance
    let dataProcessor = RouteDataFilter.sharedInstance
    let restaurantData = RestaurantDataModel.sharedInstance
    let restaurantFilterData = RestaurantFilterData.sharedInstance
    let filter = RestaurantFilter.sharedInstance
    let mapHelpers = MapHelpers()

    //These represent the location and map based variables
    var coreLocationManager = CLLocationManager()
    var locationManager:LocationManager!
    var startItem: MKMapItem?
    var destinationItem: MKMapItem?
    var annotations:[MKPointAnnotation] = [] //This is an array of the annotations on the map
    var userLocation: CLLocationCoordinate2D? //This will later be instantiated with the user's current location
    var waypoints: [WaypointStructure] = []
    var activeWaypointIdx: Int = 0
    var activeRestaurantIdx: Int = -1
    var activeMarker: CustomAnnotation?
    let viewRadius = 20.0
    
    var queryIndex = 0
    var maxQueryIndex = 0
    
    
    
    
    
    //API Keys for FourSquare
    let CLIENT_ID="ELLZUH013LMEXWRWGBOSNBTXE3NV02IUUO3ZFPVFFSZYLA30"
    let CLIENT_SECRET="U2EQ1N1J4EAG4XH4QO4HCZTGM3FCWDLXU2WJ0OPTD2Q3YUKF"

    
    
    //These three outlets correspond to the view itself. They permit the controller to access these components
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var venueNameLabel: UILabel!
    @IBOutlet weak var venueCategoryLabel: UILabel!
    @IBOutlet weak var venuePriceLabel: UILabel!
    @IBOutlet weak var venueRatingLabel: UILabel!
    @IBOutlet weak var venueTipLabel: UILabel!
    @IBOutlet weak var venueImage: UIImageView!
    @IBOutlet weak var venueOpenLabel: UILabel!
    @IBOutlet weak var rightArrow: UIButton!
    
    
    @IBAction func distanceSliderValueChanged(sender: UISlider) {
        distanceLabel.text = "\(round(sender.value*10)/10) mi"
    }

    @IBAction func handleSliderRelease(sender: UISlider) {
        activeRestaurantIdx = -1
        var distance = mapHelpers.milesToMeters(Double(sender.value))
        for (idx, waypoint) in enumerate(waypoints) {
            if waypoint.distance >= distance {
                println("SET ACTIVE WP called from handleSilider")
                setActiveWaypoint(idx)
                return
            }
        }
        println("SET ACTIVE WP called from handleSilider")
        setActiveWaypoint(waypoints.count - 1)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        rightArrow.imageEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10)
        
        // reset the venue labels
        venueNameLabel.text = ""
        venueOpenLabel.text = ""
        venueRatingLabel.text = ""
        venueTipLabel.text = ""
        venuePriceLabel.text = ""
        venueCategoryLabel.text = ""
        
        var distance = routeData.route!.distance as Double
        if routeData.searchRadius > distance/routeData.minDistToRadiusRatio {
            routeData.searchRadius = distance/routeData.minDistToRadiusRatio
            routeData.mapWidth = distance
        }
        
        distanceSlider.maximumTrackTintColor = UIColor.darkGrayColor()
        
        coreLocationManager.delegate = self
        self.displayLocation()

        
        println("VIEW DID LOAD CALLED: destitem is set? \(destinationItem == nil)")
        
        var listViewButton:UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "list"), style: UIBarButtonItemStyle.Plain, target: self, action: "showListView")
        var filterViewButton:UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: UIBarButtonItemStyle.Plain, target: self, action: "showFilterView")
        
        self.navigationItem.rightBarButtonItems = [listViewButton, filterViewButton]
        
        
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
            updateMarkers()
            activeRestaurantIdx = -1
            println("SET ACTIVE WP called from viewWillAppear")
            setActiveWaypoint(activeWaypointIdx)
        }
        self.navigationController?.interactivePopGestureRecognizer.delegate = self;
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer.delegate = nil;
    }
    
    func showListView() {
        self.performSegueWithIdentifier("show-list", sender: nil)
    }
    
    func showFilterView() {
        self.performSegueWithIdentifier("show-filter", sender: nil)
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
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false;
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
            //self.createAnnotation(self.userLocation!, imageName: "list")
        }
    }
    
    /* function: displayLocation
     * ---------------------------------------
     * This function is called once the current location has been established. It creates and adds
     * the map items to the map and then uses the two to find the directions between
     * the two addresses
    */
    func displayLocation(){
        self.addMapItem( "start", address: routeData.startingPoint)
        self.addMapItem( "destination", address: routeData.destination)
    }
    
    /* function: addMapItem
    * ---------------------------------------
    * This function geocodes the address string. This means that it queries the apple database
    * for where that address is located geographically. It then selects the most likely result
    * and uses it to create a map item. If the map item is the destination, then it will invoke
    * the getDirections method which will find the directions and update the map
    */
    func addMapItem (type: String, address: String){
        let geoCoder = CLGeocoder()
        
        if address == "Current Location" {
            let location = routeData.currentLocation
            let mkplace = MKPlacemark(coordinate: location!.coordinate, addressDictionary: nil)
            
            self.createAnnotation(mkplace.coordinate, imageName: type)
            
            if type == "start" {
                self.restaurantData.startingPoint = mkplace.coordinate // Required for searching by distance
                self.startItem = MKMapItem(placemark: mkplace)
            } else if type == "destination" {
                self.destinationItem = MKMapItem(placemark: mkplace)
            }
            
            if (self.startItem != nil && self.destinationItem != nil) {
                self.displayRoute()
                self.annotations = []
            }
        }

        geoCoder.geocodeAddressString(address, completionHandler: { (placemarks: [AnyObject]!, error: NSError!) -> Void in
            if error != nil {
                println("Geocode failed with error: \(error.localizedDescription)")
            } else if placemarks.count > 0 {
                let place = placemarks[0] as! CLPlacemark
            
                let location = place.location
                
                var mkplace = MKPlacemark(placemark: place)
                
                self.createAnnotation(mkplace.coordinate, imageName: type)
                
                if type == "start" {
                    self.restaurantData.startingPoint = mkplace.coordinate // Required for searching by distance
                    self.startItem = MKMapItem(placemark: mkplace)
                } else if type == "destination" {
                    self.destinationItem = MKMapItem(placemark: mkplace)
                }
                
                if (self.startItem != nil && self.destinationItem != nil) {
                    self.displayRoute()
                    self.annotations = []
                }
            }
        })
    }

    // display the selected route and make api requests
    func displayRoute() {
        var route = routeData.route!
        waypoints = self.dataProcessor.getSections(self.routeData.route!)
        
        println("SET ACTIVE WP called from displayRoute")
        println("\n\n\n\n NUM WAYPOINTS: \(waypoints.count), SEARCH RADIUS: \(routeData.searchRadius)\n\n\n\n")
        queryNext()
        
        self.map.addOverlay(route.polyline, level:MKOverlayLevel.AboveLabels)
    }
    
    @IBAction func showDetailView(sender: AnyObject) {
        if restaurantData.filteredRestaurants.count > activeRestaurantIdx {
            var currentVenue = restaurantData.filteredRestaurants[activeRestaurantIdx]
            restaurantData.selectedRestaurant = currentVenue
            performSegueWithIdentifier("show-details", sender: nil)
        }
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

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if !(annotation is CustomAnnotation) {
            return nil
        }
        
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView.canShowCallout = true
        }
        else {
            anView.annotation = annotation
        }
        
        //Set annotation-specific properties **AFTER**
        //the view is dequeued or created...
        
        let ca = annotation as! CustomAnnotation
        anView.image = UIImage(named:ca.imageName)
        anView.layer.zPosition = 1
        anView.canShowCallout = false
        
        if ca.imageName == "active" {
            anView.layer.zPosition = 2
        }
        
        return anView
    }

    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        var lat = view.annotation.coordinate.latitude
        var long = view.annotation.coordinate.longitude
        
        for (idx, restaurant) in enumerate(restaurantData.filteredRestaurants) {
            if restaurant.location.latitude == lat && restaurant.location.longitude == long {
                setActiveRestaurant(idx)
                break
            }
        }
    }
    

    
    /* function: setNewRegion
     * ----------------------
     * This function will reorient the view so that it fits both the starting point and the end
     * of the given route. It will work by finding the furthest out longitude and latitude and then
     * set the map to fit around all of these. It should also include annotations later on.
    */
    func setNewRegion () {
        //Extract the coord
        var startCoord = startItem?.placemark.coordinate
        var destCoord = destinationItem?.placemark.coordinate
        //All elements to be displayed on the map need to be placed in this array
        var locations = [startCoord!, destCoord!]
        


        var region = dataProcessor.findRegion(locations)
        
        //Currently calls sendFourSquare request on
        map.setRegion(region, animated: false)
    }
    
    
    /* function: createAnnotation
     * ---------------------------
     * This function will take in a title, a subtitle and a CLLCoordinate and will
     * create an annotation for those values. It will then add it to the map and 
     * also add it to the annotations array.
    */
    
    func makeAnnotation (coord: CLLocationCoordinate2D, imageName: String) -> CustomAnnotation {
        let annotation = CustomAnnotation()
        annotation.coordinate = coord
        annotation.imageName = imageName
        return annotation
    }
    
    func createAnnotation (coord: CLLocationCoordinate2D, imageName: String) {
        let annotation = makeAnnotation(coord, imageName: imageName)
        annotations.append(annotation)
        map.addAnnotation(annotation)
    }
    
    /* function: sendFourSquareRequest
     * -------------------------------
     * This is a sample request to the four square api. It takes in a latitude and a longitude and display all the
     * best restaurants found by the four square api in that area. For now it just displays them as annotations
     * with the name and ratings but can later be modified for filters and further functionallity
    */
    func sendFourSquareRequest (waypoint: WaypointStructure) {
        
        var lat = waypoint.coordinate.latitude
        var long = waypoint.coordinate.longitude
        
        var url = NSURL(string: "https://api.foursquare.com/v2/venues/explore?client_id=\(self.CLIENT_ID)&client_secret=\(self.CLIENT_SECRET)&v=20150902&ll=\(lat),\(long)&venuePhotos=1&section=\(routeData.searchSection)&limit=20&radius=\(routeData.searchRadius)")
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
            
            var newlyAdded = self.restaurantData.addRestaurants(dataObj, waypointDistance: waypoint.distance)
            var newlyFiltered = self.filter.filterRestaurantArray(newlyAdded)
            newlyFiltered.sort({$1.totalDistance > $0.totalDistance})
            
            // sort newlyFiltered by distance
            println("NUM OF WPS: \(self.waypoints.count), LAST WP DIST: \(self.mapHelpers.metersToMiles(self.waypoints[self.waypoints.count - 1].distance))")
            println("FourSquare request returned \(newlyFiltered.count) results for WP #\(self.queryIndex)\n")
            if self.restaurantData.filteredRestaurants.count > 0 {
                 println("LAST RESTAURANT DIST: \(self.mapHelpers.metersToMiles(self.restaurantData.filteredRestaurants[self.restaurantData.filteredRestaurants.count-1].totalDistance))")
            }
            
            
            for restaurant in newlyFiltered  {
                println("REST DIST: \(self.mapHelpers.metersToMiles(restaurant.totalDistance))")
                var coord = restaurant.location
                var title = restaurant.name
                var rating = restaurant.rating
                
                self.createAnnotation(coord, imageName: "venue")
            }
            
            self.restaurantData.convertToArray()
            self.filter.filterRestaurants()
            self.distanceSlider.maximumValue = Float(self.mapHelpers.metersToMiles(waypoint.distance))
            
            if self.activeRestaurantIdx == -1 && self.restaurantData.filteredRestaurants.count > 0 {
                self.setActiveWaypoint(self.activeWaypointIdx)
            }
            
            self.queryNext()

        }
    }
    
    func queryNext () {
        if (queryIndex < waypoints.count) {
            var waypoint = waypoints[queryIndex]
            sendFourSquareRequest(waypoint)
            queryIndex++
        }
    }
    
    func determineActiveRestaurant () {
        
        println("determineActiveRestaurant called: WP_IDX: \(activeWaypointIdx) WP_DIST: \(mapHelpers.metersToMiles(waypoints[activeWaypointIdx].distance))")
        for (idx, restaurant) in enumerate(self.restaurantData.filteredRestaurants) {
            
            if restaurant.totalDistance >= waypoints[activeWaypointIdx].distance && restaurant.totalDistance - waypoints[activeWaypointIdx].distance <= Double(routeData.searchRadius) {
                println("   active restaurant found: REST_DIST: \(mapHelpers.metersToMiles(restaurant.totalDistance))")

                setActiveRestaurant(idx)
                return
            }
        }
        println("No matching Restaurant found")
        // set waypoint to next waypoint
        if (activeWaypointIdx + 1 < waypoints.count) {
            println("SET ACTIVE WP called from determine active after no matching results found")
            setActiveWaypoint(activeWaypointIdx + 1)
        } else {
            println("EDGE CASE IN DETERMINE_ACTIVE_REST")
            if restaurantData.filteredRestaurants.count > 0 {
                var lastRestaurantDistance = restaurantData.filteredRestaurants[restaurantData.filteredRestaurants.count-1].totalDistance
                for (idx, waypoint) in enumerate(waypoints) {
                    if waypoint.distance > lastRestaurantDistance {
                        setActiveWaypoint(idx-1)
                        return
                    }
                }
            }
        }
    }

    
    func updateMarkers () {
        map.removeAnnotations(annotations)
        
        annotations = []
        for venue in restaurantData.filteredRestaurants {
            createAnnotation(venue.location, imageName: "venue")
        }
        
        println("updateMarkers called: # of Filtered: \(restaurantData.filteredRestaurants.count)")
    }
    
    func setActiveWaypoint (idx: Int) {
        println("\n")
        
        if idx >= waypoints.count {
            activeWaypointIdx = waypoints.count - 1
        } else if idx < 0 {
            activeWaypointIdx = 0
        } else {
            activeWaypointIdx = idx
        }
        
        var activeWaypoint = waypoints[activeWaypointIdx]
        
        distanceSlider.value = Float(mapHelpers.metersToMiles(activeWaypoint.distance))
        distanceLabel.text = "\(mapHelpers.roundDouble(Double(distanceSlider.value))) mi"
        
        restaurantFilterData.distanceFromOrigin = activeWaypoint.distance
        
        centerMap(activeWaypoint)
        
        if activeRestaurantIdx == -1 {
            determineActiveRestaurant()
        }

    }
    
    func centerMap (waypoint: WaypointStructure) {
        var region = MKCoordinateRegionMakeWithDistance(waypoint.coordinate, 100, routeData.mapWidth)
        map.setRegion(region, animated: true)
    }
    
    func addActiveMarker() {
        if annotations.count > activeRestaurantIdx {
            var marker = makeAnnotation(annotations[activeRestaurantIdx].coordinate, imageName: "active")
            activeMarker = marker
            map.addAnnotation(marker)

        }
    }
    
    func removeActiveMarker() {
        if activeMarker != nil {
            map.removeAnnotation(activeMarker!)
        }
    }
    
    func setActiveRestaurant (idx: Int) {
        println("setActiveRestaurant called: REST_IDX: \(idx)/\(restaurantData.filteredRestaurants.count), REST_DIST: \(mapHelpers.metersToMiles(restaurantData.filteredRestaurants[idx].totalDistance))")
        
        if (idx >= restaurantData.filteredRestaurants.count || idx < 0) {
            return
        }
        
        activeRestaurantIdx = idx
        var activeRestaurant = restaurantData.filteredRestaurants[idx]
        // change appearance of marker
        removeActiveMarker()
        addActiveMarker()
        
        
        // request the image
        var imgURL: NSURL = NSURL(string: activeRestaurant.imageUrl)!
        let request: NSURLRequest = NSURLRequest(URL:imgURL)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            if error != nil {
                return
            }
            var image = UIImage(data: data!)
            if image != nil {
                self.venueImage.image = image!
                self.venueImage.layer.borderWidth = 0.5
                self.venueImage.layer.borderColor = UIColor.lightGrayColor().CGColor
                self.venueImage.clipsToBounds = true
                self.venueImage.layer.cornerRadius = self.venueImage.frame.size.width / 2
            }
        }
        
        
        venueNameLabel.text = activeRestaurant.name
        venueCategoryLabel.text = activeRestaurant.category
        venuePriceLabel.text = venueDetailHelpers.getPriceRange(activeRestaurant.priceRange)
        venueRatingLabel.text = "\u{1f3c6} \(venueDetailHelpers.getRating(activeRestaurant.rating))"
        venueTipLabel.text = activeRestaurant.tip
        venueOpenLabel.text = activeRestaurant.openUntil
        
        if (Array(activeRestaurant.openUntil.lowercaseString)[0] == "c") {
            venueOpenLabel.textColor = UIColor.redColor()
        } else {
            venueOpenLabel.textColor = UIColor(red: 50/255, green: 154/255, blue: 119/255, alpha: 1)
        }
        

        var numFilteredRestaurants = restaurantData.filteredRestaurants.count
    }
    
    @IBAction func goToNext(sender: UIButton) {
        println("goToNext called: REST_IDX: \(activeRestaurantIdx)/\(restaurantData.filteredRestaurants.count), WP_IDX: \(activeWaypointIdx)/\(waypoints.count)")
        if activeRestaurantIdx != -1 {
            if (activeRestaurantIdx + 1 < restaurantData.filteredRestaurants.count) {
                activeRestaurantIdx++
                var activeRestaurant = restaurantData.filteredRestaurants[activeRestaurantIdx]
                
                if activeWaypointIdx + 1 < waypoints.count {
                    var nextWaypoint = waypoints[activeWaypointIdx + 1]
                    if (activeRestaurant.totalDistance > nextWaypoint.distance) {
                        activeRestaurantIdx = -1
                        println("setActiveWaypoint called from nextButton")
                        setActiveWaypoint(activeWaypointIdx + 1)
                    } else {
                        setActiveRestaurant(activeRestaurantIdx)
                    }
                } else {
                    setActiveRestaurant(activeRestaurantIdx)
                }
                
            }

        }
    }
    
    
    @IBAction func goToPrevious(sender: UIButton) {
        println("goToPrevious called: REST_IDX: \(activeRestaurantIdx)/\(restaurantData.filteredRestaurants.count), WP_IDX: \(activeWaypointIdx)/\(waypoints.count)")
        if activeRestaurantIdx > 0 {
            activeRestaurantIdx--
            var activeRestaurant = restaurantData.filteredRestaurants[activeRestaurantIdx]
            
            
            var idx = activeWaypointIdx
            
            while (idx > 0 && waypoints[idx].distance > activeRestaurant.totalDistance) {
                idx--
            }
            
            setActiveWaypoint(idx)
            
            setActiveRestaurant(activeRestaurantIdx)
        }
    }
}