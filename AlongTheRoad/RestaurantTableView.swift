//
//  RestaurantTableView.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 9/3/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit

class RestaurantTableView: UITableViewController {

    var routeData = RouteDataModel.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for (name, restaurant) in routeData.restaurantDictionary {
            routeData.restaurants.append(restaurant)
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        return routeData.restaurantDictionary.count
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var restaurant:AnyObject = self.routeData.restaurants[indexPath.row]
        self.routeData.selectedRestaurant = restaurant
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("restaurandID", forIndexPath: indexPath) as! RestaurantTableViewCell

        // Configure the cell...
        
        var currentVenue: AnyObject = self.routeData.restaurants[indexPath.item]
        cell.restaurantName.text =  currentVenue.objectForKey("name") as? String
        
        cell.location.text = self.getLocation(currentVenue)
        cell.distance.text = self.getDistance(currentVenue)
        self.getImage(currentVenue, cell: cell)
        cell.openUntil.text = self.getOpenUntil(currentVenue);
        cell.priceRange.text = getPriceRange(currentVenue);
        cell.rating.text = self.getRating(currentVenue)
        //Open Until
        //First check if it is open, if not then set it to false.
        

        
        //Returning the cell
        return cell
    }

    /* function: getPriceRange
    * ----------------------
    *
    */
    func getPriceRange (currentVenue: AnyObject) -> String{
        var price: AnyObject? = currentVenue.objectForKey("price")?.objectForKey("tier")
        if price != nil {
            var newPrice = price as! Int
            var dollarSigns = "";
            for i in 0..<newPrice {
                dollarSigns += "$"
            }
            return dollarSigns
        }
        return ""
    }
    
    /* function: getRating
    * ----------------------
    *
    */
    func getRating (currentVenue: AnyObject) -> String {
        var ratingObj: AnyObject? = currentVenue.objectForKey("rating")
        
        if ratingObj != nil {
            var temp = ratingObj as! Double
            var rating = String(format:"%f", temp)
            var cuttoff = advance(rating.startIndex, 3)
            rating = rating.substringToIndex(cuttoff)
        
        return rating
        }
        return " "
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
    
    
    
    /* function: getImage
    * ----------------------
    * This function extracts the data from the currentVenue for the image from the restaurant
    */
    func getImage (currentVenue: AnyObject, cell: RestaurantTableViewCell) {
        //Getting Image Section
        var imageItems: AnyObject? = currentVenue.objectForKey("featuredPhotos")?.objectForKey("items")?[0]
        var prefix: AnyObject? = imageItems?.objectForKey("prefix")
        var suffix: AnyObject?=imageItems?.objectForKey("suffix")
        
        
        var url: String = ""
        if  prefix != nil && suffix != nil {
            url = "\(prefix as! String)110x110\(suffix as! String)"
        }
        var imgURL: NSURL = NSURL(string: url)!
        let request: NSURLRequest = NSURLRequest(URL:imgURL)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            if error != nil {
                return
            }
            var image = UIImage(data: data!)
            if image != nil {
                cell.restaurantPhoto.image = image!
//                cell.restaurantPhoto.layer.cornerRadius = 10.0
                cell.restaurantPhoto.layer.borderWidth = 3.0
                cell.restaurantPhoto.layer.borderColor = UIColor.brownColor().CGColor
                cell.restaurantPhoto.clipsToBounds = true
                cell.restaurantPhoto.layer.cornerRadius = cell.restaurantPhoto.frame.size.width / 2
            }
        }
    }
    
    /* function: getDistance
     * ----------------------
     * This function extracts the data from the currentVenue for the distance from the road.
     * It returns as string formatted in miles for how far from the route the restaurant is
    */
    func getDistance (currentVenue: AnyObject) -> String {
        var distanceMeters = currentVenue.objectForKey("location")?.objectForKey("distance") as! Double
        var distance = String(format:"%f", distanceMeters/1600)
        var cuttoff = advance(distance.startIndex, 3)
        var finalString = distance.substringToIndex(cuttoff)
        return "\(finalString) mi"
    }
    /* function: getLocation
    * ----------------------
    * This function extracts the data from the currentVenue for the location and address.
    * It returns as string for the current address
    */
    func getLocation (currentVenue: AnyObject) -> String {
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

}
