//
//  RestaurantFilter.swift
//  AlongTheRoad
//
//  Created by Jan Hellmich on 9/11/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit


class RestaurantFilter: NSObject {
    
    static let sharedInstance = RestaurantFilter()
    
    let restaurantData = RestaurantDataModel.sharedInstance
    let filterData = RestaurantFilterData.sharedInstance
    
    var filterFunctions = Array<(RestaurantStructure -> Bool)>()

    // initializa all filterFunctions
    override init() {
        super.init()
        func priceFilter(venue: RestaurantStructure) -> Bool {
            let prices = filterData.pricesSelcted
            // if all ranges are checked or unchecked it should be included
            if (prices[0] == prices[1] && prices[0] == prices[2] && prices[0] == prices[3]) {
                return true
            } else if venue.priceRange == 0 {
                return false
            } else {
                return prices[venue.priceRange - 1]
            }
        }
        filterFunctions.append(priceFilter)
        
        func ratingFilter(venue: RestaurantStructure) -> Bool {
            let minRating = filterData.minRatingSelected
            return venue.rating > Double(minRating)
        }
        filterFunctions.append(ratingFilter)
        
        func openNowFilter(venue: RestaurantStructure) -> Bool {
            let openNow = filterData.openSelected
            if openNow == false {
                return true
            }
            return Array(venue.openUntil)[0] == "O"
        }
        filterFunctions.append(openNowFilter)
        
        func distanceFilter(venue: RestaurantStructure) -> Bool {
            return true
        }
        filterFunctions.append(distanceFilter)
        
    }
    
    
    func filterRestaurants () {
        let restaurants = restaurantData.restaurants
        var filterdRestaurants = [RestaurantStructure]()
        
        for restaurant in restaurants {
            var passes = true;
            for filter in filterFunctions {
                if filter(restaurant) == false {
                    passes = false
                    println(filter)
                }
            }
            if passes == true {
                filterdRestaurants.append(restaurant)
            }
        }
        
        restaurantData.filteredRestaurants = filterdRestaurants
        
    }
    
    
    
    
}