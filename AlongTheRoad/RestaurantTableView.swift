//
//  RestaurantTableView.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 9/3/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit

class RestaurantTableView: UITableViewController {

    var restaurantData = RestaurantDataModel.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restaurantData.convertToArray()
        restaurantData.filterRestaurants()
        restaurantData.sortRestaurantsByDistance()

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return restaurantData.filteredRestaurant.count
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var restaurant:RestaurantStructure = self.restaurantData.filteredRestaurant[indexPath.row]
        self.restaurantData.selectedRestaurant = restaurant
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("restaurandID", forIndexPath: indexPath) as! RestaurantTableViewCell

        // Configure the cell...
        
        var currentVenue = self.restaurantData.filteredRestaurant[indexPath.item]
        cell.restaurantName.text =  currentVenue.name
        
        cell.location.text = currentVenue.address//self.getLocation(currentVenue)
        cell.distance.text = self.getDistance(currentVenue.totalDistance)
        self.getImage(currentVenue.imageUrl, cell: cell)
        cell.openUntil.text = currentVenue.openUntil
        cell.priceRange.text = getPriceRange(currentVenue.priceRange);
        cell.rating.text = self.getRating(currentVenue.rating)
        
        return cell
    }


    func getPriceRange (price: Int) -> String{
        var dollarSigns = "";
        for i in 0..<price {
            dollarSigns += "$"
        }
        return dollarSigns
    }
    

    func getRating (ratingDouble: Double) -> String {
            var rating = String(format:"%f", ratingDouble)
            var cuttoff = advance(rating.startIndex, 3)
            rating = rating.substringToIndex(cuttoff)
        
        return rating

    }
    

    
    
    /* function: getImage
    * ----------------------
    * This function extracts the data from the currentVenue for the image from the restaurant
    */
    func getImage (url: String, cell: RestaurantTableViewCell) {
        var imgURL: NSURL = NSURL(string: url)!
        let request: NSURLRequest = NSURLRequest(URL:imgURL)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            if error != nil {
                return
            }
            var image = UIImage(data: data!)
            if image != nil {
                cell.restaurantPhoto.image = image!
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
    func getDistance (distanceMeters: Double) -> String {
        var distance = String(format:"%f", distanceMeters/1600)
        var cuttoff = advance(distance.startIndex, 3)
        var finalString = distance.substringToIndex(cuttoff)
        return "\(finalString) mi"
    }


}
