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

    var restaurantData = RestaurantDataModel.sharedInstance
    
    @IBAction func getDirections(sender: AnyObject) {
        var restaurant = self.restaurantData.selectedRestaurant
        var coord = restaurant.location
        
        var street = restaurant.streetAddress
        var city = restaurant.city
        var state = restaurant.state
        var ZIP = restaurant.postalCode
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
        var restaurant = self.restaurantData.selectedRestaurant


        
        var url = NSURL(string: restaurant.url)
        
        var req = NSURLRequest(URL:url!)
        self.webView!.loadRequest(req)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
