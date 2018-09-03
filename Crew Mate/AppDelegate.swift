//
//  AppDelegate.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/9/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let filename = url.lastPathComponent.dropLast(4).replacingOccurrences(of: "_", with: " ")
        if url.pathExtension.elementsEqual("cml") {
            let alertController = UIAlertController(title: "Import Lineup?", message: "Are you sure you want to import \(filename)?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Import", style: .default, handler: { (_) in
                self.processImport(from: url)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (alertAction) in
                print("Canceled...") //Remove Temp File
                do {
                    try FileManager.default.removeItem(at: url)
                    print("Deleted Temp File.")
                } catch {
                    print("Error removing temp file.")
                }
                
            }))
            window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Crew_Mate")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

extension AppDelegate {
    
    fileprivate func processImport(from url: URL) {
        do {
            let lineupData = try Data(contentsOf: url as URL, options: .uncached)
            //let jsonData = try JSONSerialization.jsonObject(with: lineupData, options: .mutableContainers)
            //print(jsonData)
            let lineupJson = try JSON(data: lineupData)
            createLineupEntity(from: lineupJson)
            
            
        } catch {
            print("Error: \(error)")
        }
    }
    
    fileprivate func getExistingMemberIds() -> [String] {
        var memberIds = [String]()
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do {
            let memberData = try managedContext.fetch(NSFetchRequest<CrewMember>(entityName: "CrewMember"))
            for member in memberData {
                if let id = member.id {
                    memberIds.append(id)
                }
            }
        } catch {
            print("Error fetching Member IDs: \(error)")
        }
        return memberIds
    }
    
    
    fileprivate func createNewMember(from member: JSON, comparedTo existingMembers: [String], into managedContext: NSManagedObjectContext) {
        var time2k = [Int]()
        var time5k = [Int]()
        var time6k = [Int]()
        
        if let firstName = member["firstName"].string,
            let lastName = member["lastName"].string,
            let memberId = member["id"].string,
            let height = member["height"].string,
            let notes = member["notes"].string,
            let cleared = member["cleared"].bool,
            let side = member["side"].string,
            let picture = member["picture"].string {
            
            //2K Time
            if let time2kMin = member["time2k"][0].int,
                let time2kSec = member["time2k"][1].int,
                let time2kTh = member["time2k"][2].int {
                time2k.append(time2kMin); time2k.append(time2kSec); time2k.append(time2kTh)
            }
            
            //5K Time
            if let time5kMin = member["time5k"][0].int,
                let time5kSec = member["time5k"][1].int,
                let time5kTh = member["time5k"][2].int {
                time5k.append(time5kMin); time5k.append(time5kSec); time5k.append(time5kTh)
            }
            
            //6K Time
            if let time6kMin = member["time6k"][0].int,
                let time6kSec = member["time6k"][1].int,
                let time6kTh = member["time6k"][2].int {
                time6k.append(time6kMin); time6k.append(time6kSec); time6k.append(time6kTh)
            }
            
            //Check existing CoreData Members...if current member does NOT exist, create new member
            if !(existingMembers.contains(memberId)) {
                if let newMember = NSEntityDescription.insertNewObject(forEntityName: "CrewMember", into: managedContext) as? CrewMember {
                    newMember.cleared = cleared
                    newMember.firstName = firstName
                    newMember.lastName = lastName
                    newMember.height = height
                    newMember.id = memberId
                    newMember.notes = notes
                    newMember.side = side
                    newMember.time2k = time2k
                    newMember.time5k = time5k
                    newMember.time6k = time6k
                    
                    //Convert Picture to Data for Saving
                    let img = convertBase64ToImage(imageString: picture)
                    let imgData = img.jpegData(compressionQuality: 0.7)
                    newMember.picture = imgData
                    
                }
            }
        }
    }
    
    fileprivate func createNewLineup(_ managedContext: NSManagedObjectContext, _ newBoatId: String, _ newOarId: String, _ createdDate: Date, _ lineupName: String, _ lineupId: String, _ rows: inout [String]) {
        //Create New Lineup
        //Note: Use "value: forKey:" to iterate through rows in linup
        let newLineup = NSEntityDescription.insertNewObject(forEntityName: "Lineup", into: managedContext)
        newLineup.setValue(newBoatId, forKey: "boat")
        newLineup.setValue(newOarId, forKey: "oar")
        newLineup.setValue(createdDate, forKey: "createdAt")
        newLineup.setValue(lineupName, forKey: "name")
        newLineup.setValue(lineupId, forKey: "id")
        for index in 1...9 {
            newLineup.setValue(rows[index - 1], forKey: "row\(index)")
        }
    }
    
    fileprivate func createLineupEntity(from jsonData: JSON) {
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        var rows = [String]()
        var newBoatId = ""
        var newOarId = ""
        let existingMembers = getExistingMemberIds()
        
        if let row1 = jsonData["row1"].string,
            let row2 = jsonData["row2"].string,
            let row3 = jsonData["row3"].string,
            let row4 = jsonData["row4"].string,
            let row5 = jsonData["row5"].string,
            let row6 = jsonData["row6"].string,
            let row7 = jsonData["row7"].string,
            let row8 = jsonData["row8"].string,
            let row9 = jsonData["row9"].string,
            let createdAt = jsonData["createdAt"].double,
            let lineupId = jsonData["id"].string,
            let lineupName = jsonData["name"].string {
            rows.append(row1)
            rows.append(row2)
            rows.append(row3)
            rows.append(row4)
            rows.append(row5)
            rows.append(row6)
            rows.append(row7)
            rows.append(row8)
            rows.append(row9)
            
            //Create New Members from JSON
            if let members = jsonData["members"].array {
                for member in members {
                    createNewMember(from: member, comparedTo: existingMembers, into: managedContext)
                }
            }
            
            //If boat exists create new boat object
            if let boatId = jsonData["boat"]["id"].string,
                let boatName = jsonData["boat"]["name"].string {
                if let newBoat = NSEntityDescription.insertNewObject(forEntityName: "Equipment", into: managedContext) as? Equipment {
                    newBoat.id = boatId
                    newBoat.name = boatName
                    newBoat.type = "boat"
                    newBoatId = boatId
                } else { print("No Entity (Boat) Error") }
            } else { print("No Boat in Lineup") }
            
            //If oar exists create new oar object
            if let oarId = jsonData["oar"]["id"].string,
                let oarName = jsonData["oar"]["name"].string {
                if let newOar = NSEntityDescription.insertNewObject(forEntityName: "Equipment", into: managedContext) as? Equipment {
                    newOar.id = oarId
                    newOar.name = oarName
                    newOar.type = "oar"
                    newOarId = oarId
                } else { print("New Entity (Oar) Error") }
            } else { print("No Oar in Lineup") }
            
            //Create Date Object from lineup data
            let createdDate = Date(timeIntervalSince1970: createdAt)
            createNewLineup(managedContext, newBoatId, newOarId, createdDate, lineupName, lineupId, &rows)
        }
    }
    
    
    
}
