//
// The MIT License (MIT)
//
// Copyright © 2019 NoodleOfDeath. All rights reserved.
// NoodleOfDeath
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE

import UIKit

import SwiftyFileSystem

let UserDirectory = FileSystem.documentPath +/ "UserDocuments"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var rootViewController: ViewController = ViewController()
    lazy var navController: UINavigationController = rootViewController.asNavigationController

    var launchOptions: [UIApplicationLaunchOptionsKey: Any]?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navController
        window.makeKeyAndVisible()
        
        self.window = window
        self.launchOptions = launchOptions
        
        if !FileSystem.fileExists(at: UserDirectory) {
            FileSystem.createDirectory(at: URL(fileURLWithPath: UserDirectory))
        }
        
        if let path = Bundle.main.path(forResource: "SampleResources", ofType: nil) {
            for item in FileSystem.contentsOfDirectory(at: path) {
                if FileSystem.fileExists(at: UserDirectory +/ item) { continue }
                let src = URL(fileURLWithPath: path +/ item)
                let dst = URL(fileURLWithPath: UserDirectory +/ item)
                FileSystem.copyItem(at: src, to: dst)
            }
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if let rawURL = launchOptions?[.url] as? CVarArg {
            launchOptions?[.url] = nil
            guard let url = URL(string: String(format: "%@", rawURL)) else { return }
            importDocument(at: url)
        }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        importDocument(at: url)
        return true
    }
    
    /// Copies a file from another application, from the inbox directory,
    /// to the user documents directory.
    func importDocument(at url: URL) {
        let dst = URL(fileURLWithPath: UserDirectory +/ url.lastPathComponent)
        if let dstURL = FileSystem.copyItem(at: url, to: dst) {
            FileSystem.removeItem(at: url)
            rootViewController.open(Document(fileURL: dstURL), completionHandler: nil)
        }
    }
    
}

