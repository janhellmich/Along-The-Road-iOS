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

class RouteViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    //This represent the shared data model
    let routeData = RouteDataModel.sharedInstance
    let dataProcessor = RouteDataFilter.sharedInstance
    let restaurantData = RestaurantDataModel.sharedInstance
    let mapHelpers = MapHelpers()
    
    //These represent the location and map based variables
    var coreLocationManager = CLLocationManager()
    var locationManager:LocationManager!
    var startItem: MKMapItem?
    var destinationItem: MKMapItem?
    var annotations:[CustomAnnotation]? //This is an array of the annotations on the map
    var userLocation: CLLocationCoordinate2D? //This will later be instantiated with the user's current location
    
    // variable used to reder the different routes properly
    var activeRoute: Bool = false
    
    //These three outlets correspond to the view itself. They permit the controller to access these components
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var routeControl: UISegmentedControl!
    @IBOutlet weak var goButton: UIButton!
    
    @IBAction func routeSelected(sender: UISegmentedControl) {
        var active = sender.selectedSegmentIndex
        self.displayRoutes(active)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        coreLocationManager.delegate = self
        
        routeControl.removeAllSegments();
        
        self.displayLocation()
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
    
    // Navigate to next view on GO!
    @IBAction func clickGo(sender: AnyObject) {
        restaurantData.reset()
        self.performSegueWithIdentifier("go", sender: nil)
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
        
        if address == "Current Location" {
            var location = routeData.currentLocation
            var mkplace = MKPlacemark(coordinate: location!.coordinate, addressDictionary: nil)
            
            self.createAnnotation(mkplace.coordinate, imageName: type)
            
            if type == "start" {
                self.startItem = MKMapItem(placemark: mkplace)
            } else {
                self.destinationItem = MKMapItem(placemark: mkplace)
            }
            
            if self.startItem != nil && self.destinationItem != nil {
                self.getDirections()
            }
            
            return
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
                    self.startItem = MKMapItem(placemark: mkplace)
                } else {
                    self.destinationItem = MKMapItem(placemark: mkplace)
                }
                
                if self.startItem != nil && self.destinationItem != nil {
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
        req.transportType = routeData.modeOfTravel
        req.requestsAlternateRoutes = true
        self.map.showAnnotations(self.annotations, animated: true)
        
        var directions = MKDirections(request: req)
        
        directions.calculateDirectionsWithCompletionHandler({ (response: MKDirectionsResponse!, error: NSError!) -> Void in
            if error != nil {
                println("Directions failed with error: \(error.localizedDescription)")
            } else {
                self.setNewRegion()
                self.routeData.routes = response.routes
                self.displayRoutes(0)
                self.generateSegmentControl()
                
                self.goButton.enabled = true;
                // add go button to view
//                var rightAddBarButtonItem:UIBarButtonItem = UIBarButtonItem(title: "GO!", style: UIBarButtonItemStyle.Plain, target: self, action: "clickGo")
//                self.navigationItem.rightBarButtonItem = rightAddBarButtonItem
            }
        });
    }
    
    // generate Segment display to choose between routes
    func generateSegmentControl() {
        for (i, route) in enumerate(routeData.routes) {
            routeControl.insertSegmentWithTitle("\(mapHelpers.roundDouble(mapHelpers.metersToMiles(route.distance)))mi - \(timeConverter(route.expectedTravelTime))", atIndex: i, animated: false)
        }
        routeControl.selectedSegmentIndex = 0

    }
    
    // turn seconds into readable time
    func timeConverter(time: Double) -> String {
        var min = Int(time / 60) % 60
        var hours = (Int(time/60) - min) / 60
        
        if hours > 0 {
            return "\(hours)h \(min)m"
        } else {
            return "\(min)min"
        }
    }
    
    // displays all routes on the map
    func displayRoutes(activeIndex: Int) {
        
        for (i, route) in enumerate(routeData.routes) {
            var currentRoute = route as! MKRoute
            var renderer = MKPolygonRenderer(overlay:currentRoute.polyline)
            renderer.strokeColor = UIColor.grayColor()
            
            if i != activeIndex {
                self.activeRoute = false
                self.map.addOverlay(currentRoute.polyline, level:MKOverlayLevel.AboveLabels)
            }
        }
        
        // render the active route last to make it appear on top
        var activeRoute = routeData.routes[activeIndex] as! MKRoute
        self.routeData.route = activeRoute
        self.activeRoute = true
        self.map.addOverlay(activeRoute.polyline, level:MKOverlayLevel.AboveLabels)
        
    }
    
    // sets the renderForOverlay delegate method
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            if self.activeRoute {
                polylineRenderer.strokeColor = UIColor.blueColor()
            } else {
                polylineRenderer.strokeColor = UIColor.grayColor()
            }
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
        var startCoord = self.startItem?.placemark.coordinate
        var destCoord = self.destinationItem?.placemark.coordinate
        //All elements to be displayed on the map need to be placed in this array
        var locations = [startCoord!, destCoord!]
        
        
        
        var region = self.dataProcessor.findRegion(locations)
        
        //Currently calls sendFourSquare request on
        self.map.setRegion(region, animated: true)
    }
    
    
    /* function: createAnnotation
    * ---------------------------
    * This function will take in a title, a subtitle and a CLLCoordinate and will
    * create an annotation for those values. It will then add it to the map and
    * also add it to the annotations array.
    */
    
    func makeAnnotation (coord: CLLocationCoordinate2D, imageName: String) -> CustomAnnotation {
        let annotation = CustomAnnotation()
        println(imageName)
        annotation.coordinate = coord
        annotation.imageName = imageName
        return annotation
    }
    
    func createAnnotation (coord: CLLocationCoordinate2D, imageName: String) {
        let annotation = makeAnnotation(coord, imageName: imageName)
        //annotations.append(annotation)
        map.addAnnotation(annotation)
    }
    
}