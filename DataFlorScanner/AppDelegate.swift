//
//  AppDelegate.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 27.01.23.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    static var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
