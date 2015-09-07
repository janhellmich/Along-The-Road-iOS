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
    let dataProcessor = DataFilter.sharedInstance
    
    //These represent the location and map based variables
    var coreLocationManager = CLLocationManager()
    var locationManager:LocationManager!
    var startItem: MKMapItem?
    var destinationItem: MKMapItem?
    var annotations:[MKPointAnnotation]? //This is an array of the annotations on the map
    var userLocation: CLLocationCoordinate2D? //This will later be instantiated with the user's current location
    
    // variable used to reder the different routes properly
    var activeRoute: Bool = false
    
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
        req.requestsAlternateRoutes = true
        self.map.showAnnotations(self.annotations, animated: true)
        
        var directions = MKDirections(request: req)
        
        directions.calculateDirectionsWithCompletionHandler({ (response: MKDirectionsResponse!, error: NSError!) -> Void in
            if error != nil {
                println("Directions failed with error: \(error.localizedDescription), trying again")
                self.getDirections()
            } else {
                
                self.setNewRegion()
                
                for (i, route) in enumerate(response.routes) {
                    var currentRoute = route as! MKRoute
                    
                    var renderer = MKPolygonRenderer(overlay:currentRoute.polyline)
                    renderer.strokeColor = UIColor.grayColor()
                    self.routeData.route = currentRoute

                    if i == 0 {
                        self.routeData.route = currentRoute
                        self.activeRoute = true
                    } else {
                        self.activeRoute = false
                    }
                    
                    
                    self.map.rendererForOverlay(currentRoute.polyline)
                    self.map.addOverlay(currentRoute.polyline, level:MKOverlayLevel.AboveLabels)
                }
                
//                var route = response.routes[0] as! MKRoute
//                println(response.routes.count)
//                
//                self.routeData.route = route //Add the route to the route data model
//                
//                self.setNewRegion()
//                
//                var renderer = MKPolygonRenderer(overlay:route.polyline)
//                renderer.strokeColor = UIColor.blueColor()
//                
//                self.map.rendererForOverlay(route.polyline)
//                self.map.addOverlay(route.polyline, level:MKOverlayLevel.AboveLabels)
            }
        });
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
    
    func createAnnotation (coord: CLLocationCoordinate2D, title: String, subtitle: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coord
        annotation.title = title
        annotation.subtitle = subtitle
        self.annotations?.append(annotation)
        self.map.addAnnotation(annotation)
    }
    
}