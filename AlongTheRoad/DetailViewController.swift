//
//  DetailViewController.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 9/7/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit
import WebKit
import MapKit
import AddressBook


class DetailViewController: UIViewController {

    var routeDataModel = RouteDataModel.sharedInstance
    
    @IBOutlet weak var webpageView: UIView!
    @IBAction func getDirections(sender: AnyObject) {
        var restaurant: AnyObject = self.routeDataModel.selectedRestaurant!
        var coord = CLLocationCoordinate2D()
        coord.latitude = restaurant.objectForKey("location")!.objectForKey("lat") as!Double
        coord.longitude = restaurant.objectForKey("location")!.objectForKey("lng") as! Double
        
        var street = restaurant.objectForKey("location")!.objectForKey("address") as! String
        var city = restaurant.objectForKey("location")!.objectForKey("city") as! String
        var state = restaurant.objectForKey("location")!.objectForKey("state") as! String
        var ZIP = restaurant.objectForKey("location")!.objectForKey("postalCode") as! String
        let addressDict =
        [kABPersonAddressStreetKey as NSString: street,
            kABPersonAddressCityKey: city,
            kABPersonAddressStateKey: state,
            kABPersonAddressZIPKey: ZIP]
        
        
        let place = MKPlacemark(coordinate: coord,
            addressDictionary: addressDict)
        
        let mapItem = MKMapItem(placemark: place)
        
        let options = [MKLaunchOptionsDirectionsModeKey:
        MKLaunchOptionsDirectionsModeDriving]
        
        mapItem.openInMapsWithLaunchOptions(options)

        
    }
    @IBOutlet var containerView : UIView! = nil
    var webView: WKWebView?
    
    override func loadView() {
        super.loadView()
        
        self.webView = WKWebView()
        self.view = self.webView!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var restaurant: AnyObject = self.routeDataModel.selectedRestaurant!
        var urlString = ""
        if let name: AnyObject? = restaurant.objectForKey("name") {
            if let id: AnyObject? = restaurant.objectForKey("id") {
                var restaurantID = id as! String
                var restaurantName = name as! String
                
                //Handling Spaces
                var nameArr = split(restaurantName){$0 ==  " "}
                var newName = "-".join(nameArr)
                urlString = "https://foursquare.com/v/\(newName)/\(restaurantID)"
            }
        }

        
        var url = NSURL(string: urlString)
        
        var req = NSURLRequest(URL:url!)
        self.webView!.loadRequest(req)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
