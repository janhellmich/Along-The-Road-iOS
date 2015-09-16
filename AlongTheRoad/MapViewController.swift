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

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
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
    @IBOutlet weak var venueRatingLabel: UILabel!
    @IBOutlet weak var venueImage: UIImageView!
    
    
    @IBAction func distanceSliderValueChanged(sender: UISlider) {
        distanceLabel.text = "\(round(sender.value*10)/10) mi"
    }

    @IBAction func handleSliderRelease(sender: UISlider) {
        activeRestaurantIdx = -1
        var distance = mapHelpers.milesToMeters(Double(sender.value))
        for (idx, waypoint) in enumerate(waypoints) {
            if waypoint.distance >= distance {
                setActiveWaypoint(idx)
                return
            }
        }
        setActiveWaypoint(waypoints.count - 1)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        coreLocationManager.delegate = self
        self.displayLocation()
        
        var rightAddBarButtonItem:UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "list"), style: UIBarButtonItemStyle.Plain, target: self, action: "showListView")
        self.navigationItem.rightBarButtonItem = rightAddBarButtonItem
        
        distanceSlider.maximumValue = Float(mapHelpers.metersToMiles(routeData.route!.distance))
        
        
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
//            map.removeAnnotations(annotations)
//            println("# of Annotations \(annotations.count)")
//            println("# of Filtered \(restaurantData.filteredRestaurants.count)")
//            println("# of Total Restauratants \(restaurantData.restaurants.count)")
//            self.createAnnotation(self.startItem!.placemark.location.coordinate, title: "Start", subtitle: "")
//            annotations = []
//            self.createAnnotation(self.destinationItem!.placemark.location.coordinate, title: "Destination", subtitle: "")
//            
//            for venue in restaurantData.filteredRestaurants {
//                createAnnotation(venue.location, title: venue.name, subtitle: "Rating: \(venue.rating)")
//            }
            updateMarkers()
            activeRestaurantIdx = -1
            setActiveWaypoint(activeWaypointIdx)
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
        self.addMapItem( "start", address: routeData.startingPoint)
        self.addMapItem( "destination", address: routeData.destination)
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
                
                self.createAnnotation(mkplace.coordinate, imageName: type)
                
                if type == "start" {
                    self.restaurantData.startingPoint = mkplace.coordinate // Required for searching by distance
                    self.startItem = MKMapItem(placemark: mkplace)
                } else if type == "destination" {
                    self.destinationItem = MKMapItem(placemark: mkplace)
                }
                
                if (self.startItem != nil && self.destinationItem != nil) {
                    self.displayRoute()
                    //self.setNewRegion()
                }
            }
        })
    }

    // display the selected route and make api requests
    func displayRoute() {
        var route = routeData.route!
        waypoints = self.dataProcessor.getSections(self.routeData.route!)
        
        setActiveWaypoint(0)
        
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
        if ca.imageName == "active" {
            anView.layer.zPosition = 2
        }
        
        return anView
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
            
            for restaurant in newlyFiltered  {
                var coord = restaurant.location
                var title = restaurant.name
                var rating = restaurant.rating
                
                self.createAnnotation(coord, imageName: "venue")
            }
            
            
            
            
            self.restaurantData.convertToArray()
            self.filter.filterRestaurants()
            
            
            var activeWaypoint = self.waypoints[self.activeWaypointIdx]
            if self.activeRestaurantIdx == -1 {
                self.determineActiveRestaurant()
            } else {
                self.queryNext()
            }
            
           
            //self.map.showAnnotations(self.annotations, animated: true)
        }
    }
    
    func searchSurroundingRestaurants () {
        println("searchSurroundingRestaurants")
        for (idx, waypoint) in enumerate(waypoints) {
            if abs(waypoint.distance - waypoints[activeWaypointIdx].distance) <= restaurantFilterData.searchOffset {
                if !waypoint.wasQueried {
                    sendFourSquareRequest(waypoint)
                    waypoints[idx].wasQueried = true
                }
            }
        }
    }
    
    func determineQueryRange () {
        var minSet = false
        for (idx, waypoint) in enumerate(waypoints) {
            if abs(waypoint.distance - waypoints[activeWaypointIdx].distance) <= restaurantFilterData.searchOffset {
                if !minSet {
                    queryIndex = idx
                    minSet = true
                }
                maxQueryIndex = idx
            }
        }
    }
    
    func queryNext () {
        if (++queryIndex <= maxQueryIndex) {
            var waypoint = waypoints[queryIndex]
            if !waypoint.wasQueried {
                sendFourSquareRequest(waypoints[queryIndex])
                waypoint.wasQueried = true
            } else {
                queryNext()
            }
        }
    }
    
    func determineActiveRestaurant () {
        for (idx, restaurant) in enumerate(self.restaurantData.filteredRestaurants) {
            println("\n\n")
            println(restaurant.totalDistance)
            println(waypoints[activeWaypointIdx].distance)
            println("diff between restaurant and waypoint distances\(mapHelpers.metersToMiles(restaurant.totalDistance - waypoints[activeWaypointIdx].distance))")
            if restaurant.totalDistance >= waypoints[activeWaypointIdx].distance && restaurant.totalDistance - waypoints[activeWaypointIdx].distance <= Double(routeData.searchRadius) {
                println("determineActiveRestaurant")
                println("   active waypoint distance \(mapHelpers.metersToMiles(waypoints[activeWaypointIdx].distance))")
                //println("   next waypoint distance \(mapHelpers.metersToMiles(waypoints[activeWaypointIdx+1].distance))")
                println("   active restaurant distance \(mapHelpers.metersToMiles(restaurant.totalDistance))")
                println(idx)
                // update all markers
                updateMarkers()
                setActiveRestaurant(idx)
                //self.searchSurroundingRestaurants()
                determineQueryRange()
                queryNext()
                return
            }
        }
        println("NO Restaurant found")
        // set waypoint to next waypoint, adjust location of slider?
        if (++activeWaypointIdx < waypoints.count) {
            setActiveWaypoint(activeWaypointIdx)
        } else {
            var lastRestaurantDistance = restaurantData.filteredRestaurants[restaurantData.filteredRestaurants.count-1].totalDistance
            for (idx, waypoint) in enumerate(waypoints) {
                if waypoint.distance > lastRestaurantDistance {
                    setActiveWaypoint(idx-1)
                }
            }
        
        }
        
        
    }
    
    func updateMarkers () {
        map.removeAnnotations(annotations)

        self.createAnnotation(self.startItem!.placemark.location.coordinate, imageName: "start")
        self.createAnnotation(self.destinationItem!.placemark.location.coordinate, imageName: "destination")
        
        annotations = []
        for venue in restaurantData.filteredRestaurants {
            createAnnotation(venue.location, imageName: "venue")
        }
        println("# of Annotations \(annotations.count)")
        println("# of Filtered \(restaurantData.filteredRestaurants.count)")
        println("# of Total Restauratants \(restaurantData.restaurants.count)")

    }
    
    func setActiveWaypoint (idx: Int) {
        println("Index of new active waypoint\(idx)")
        activeWaypointIdx = idx
        var activeWaypoint = waypoints[activeWaypointIdx]
        
        distanceSlider.value = Float(mapHelpers.metersToMiles(activeWaypoint.distance))
        distanceLabel.text = "\(mapHelpers.roundDouble(Double(distanceSlider.value))) mi"
        
        restaurantFilterData.distanceFromOrigin = activeWaypoint.distance
        filter.filterRestaurants()
        
        centerMap(activeWaypoint)
        
        // check if activeWaypoint was queried
        if activeWaypoint.wasQueried {
            determineActiveRestaurant()
        } else {
            activeWaypoint.wasQueried = true
            sendFourSquareRequest(activeWaypoint)
        }
    }
    
    func centerMap (waypoint: WaypointStructure) {
        var region = MKCoordinateRegionMakeWithDistance(waypoint.coordinate, 100, 20000)
        map.setRegion(region, animated: true)
    }
    
    func addActiveMarker() {
        var marker = makeAnnotation(annotations[activeRestaurantIdx].coordinate, imageName: "active")
        activeMarker = marker
        map.addAnnotation(marker)
    }
    
    func removeActiveMarker() {
        if activeMarker != nil {
            map.removeAnnotation(activeMarker!)
        }
    }
    
    func setActiveRestaurant (idx: Int) {
        activeRestaurantIdx = idx
        var activeRestaurant = restaurantData.filteredRestaurants[idx]
        // change appearance of marker
        removeActiveMarker()
        addActiveMarker()
        
        // update the active restaurant display
//        println(activeRestaurant.imageUrl)
//        var imgURL: NSURL = NSURL(string: activeRestaurant.imageUrl)!
//        let request: NSURLRequest = NSURLRequest(URL:imgURL)
//        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
//            if error != nil {
//                return
//            }
//            var image = UIImage(data: data!)
//            if image != nil {
//                self.venueImage.image = image!
////                cell.restaurantPhoto.image = image!
////                cell.restaurantPhoto.layer.borderWidth = 3.0
////                cell.restaurantPhoto.layer.borderColor = UIColor.brownColor().CGColor
////                cell.restaurantPhoto.clipsToBounds = true
////                cell.restaurantPhoto.layer.cornerRadius = cell.restaurantPhoto.frame.size.width / 2
//            }
//        }
        
//        if let url = NSURL(string: activeRestaurant.imageUrl) {
//            if let data = NSData(contentsOfURL: url){
//                venueImage.image = UIImage(data: data)
//            }
//        }


        
        venueNameLabel.text = activeRestaurant.name
        venueCategoryLabel.text = venueDetailHelpers.getPriceRange(activeRestaurant.priceRange)
        venueRatingLabel.text = venueDetailHelpers.getRating(activeRestaurant.rating)
        
        
        println("NEW ACTIVE RESTUARANT \(idx)")
        println("   total distance of restaurant \(mapHelpers.metersToMiles(restaurantData.filteredRestaurants[idx].totalDistance))")
        println(restaurantData.filteredRestaurants[idx].name)
        println("   first filtered restarauant \(mapHelpers.metersToMiles(restaurantData.filteredRestaurants[0].totalDistance))")
        var numFilteredRestaurants = restaurantData.filteredRestaurants.count
        println("   number of restaurants filtered\(numFilteredRestaurants)")
        println("   last filtered restarauant \(mapHelpers.metersToMiles(restaurantData.filteredRestaurants[numFilteredRestaurants-1].totalDistance))")
        // TODO: change display of the active restaurant's marker
        //restaurantData.filteredRestaurants[idx]
    }
    
    @IBAction func goToNext(sender: UIButton) {
        if activeRestaurantIdx != -1 {
            if (activeRestaurantIdx + 1 < restaurantData.filteredRestaurants.count) {
                activeRestaurantIdx++
                var activeRestaurant = restaurantData.filteredRestaurants[activeRestaurantIdx]
                
                if activeWaypointIdx + 1 < waypoints.count {
                    var nextWaypoint = waypoints[activeWaypointIdx + 1]
                    if (activeRestaurant.totalDistance > nextWaypoint.distance) {
                        activeRestaurantIdx = -1
                        setActiveWaypoint(activeWaypointIdx + 1)
                        println("SETTING NEW ACTIVE WP")
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
        if activeRestaurantIdx != -1 {
            if (activeRestaurantIdx > 0) {
                activeRestaurantIdx--
                var activeRestaurant = restaurantData.filteredRestaurants[activeRestaurantIdx]
                
                if activeWaypointIdx > 0 {
                    var currentWaypoint = waypoints[activeWaypointIdx]
                    if (activeRestaurant.totalDistance < currentWaypoint.distance) {
                        centerMap(waypoints[--activeWaypointIdx])
                    }
                }
                setActiveRestaurant(activeRestaurantIdx)
            }
            
        }
    }
}