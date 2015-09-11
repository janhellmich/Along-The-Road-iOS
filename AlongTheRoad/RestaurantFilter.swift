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
    
    let RestaurantData = RestaurantDataModel.sharedInstance
    
    var filterFunctions = Array<(RestaurantStructure -> Bool)>()

    // initializa all filterFunctions
    override init() {
        func priceFilter(venue: RestaurantStructure) -> Bool {
            return true
        }
        filterFunctions.append(priceFilter)
        
        func ratingFilter(venue: RestaurantStructure) -> Bool {
            return true
        }
        filterFunctions.append(ratingFilter)
        
        func openNowFilter(venue: RestaurantStructure) -> Bool {
            return true
        }
        filterFunctions.append(openNowFilter)
    }
    
    
    func filterRestaurants () {
        let restaurants = RestaurantData.restaurants
        var filterdRestaurants = [RestaurantStructure]()
        
        for restaurant in restaurants {
            var passes = true;
            for filter in filterFunctions {
                if filter(restaurant) == false {
                    passes = false
                }
            }
            if passes == true {
                filterdRestaurants.append(restaurant)
            }
        }
        
        RestaurantData.filteredRestaurants = filterdRestaurants
        
    }
    
    
    
    
}