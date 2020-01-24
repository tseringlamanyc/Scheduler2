//
//  SchedulesTabController.swift
//  Scheduler
//
//  Created by Tsering Lama on 1/24/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit

class SchedulesTabController: UITabBarController {
    
    // get instance of the 2 tabs from storyboard
    
    private let dataPersistence = DataPersistence<Event>(filename: "schedules.plist")
    
    private lazy var schedulesNavController: UINavigationController = {
        guard let navController = storyboard?.instantiateViewController(identifier: "SchedulesNavController") as? UINavigationController, let schedulesListController = navController.viewControllers.first as? ScheduleListController else {
            fatalError("Couldnt load NavController")
        }
        // set data persistence property
        schedulesListController.dataPersistence = dataPersistence 
        return navController
    } ()
    
    // first we access to the UINavigationController then we access the first view controller
    private lazy var completedNavController: UINavigationController = {
        guard let navController = storyboard?.instantiateViewController(identifier: "CompletedNavController") as? UINavigationController, let recentlyCompletedController = navController.viewControllers.first as? CompletedScheduleController else {
            fatalError("Couldnt load nav controller")
        }
        // set data persistence property
        recentlyCompletedController.dataPersistence = dataPersistence
        return navController
    } ()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [schedulesNavController, completedNavController]
    }
}
