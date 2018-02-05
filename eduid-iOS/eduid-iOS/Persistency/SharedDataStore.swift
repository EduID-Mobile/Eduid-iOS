//
//  SharedDataStore.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 28.11.17.
//  Copyright © 2017 Blended Learning Center. All rights reserved.
//

import Foundation
import CoreData

class SharedDataStore : NSObject {
    
    var managedObjectContext : NSManagedObjectContext?
    var managedObjectModel : NSManagedObjectModel?
    var persistentStoreCoordinator : NSPersistentStoreCoordinator?
    var persistentStore : NSPersistentStore?
    
    private static var persistentContainer : NSPersistentContainer = setupContainer()
    
    let Shared_Group_Context = "group.htwchur.eduid.share"
    
    override init() {
        super.init()
//        setupCoreData()
//        self.persistentContainer =  setupContainer()
    }
    
    func setupCoreData() {
        self.managedObjectModel = NSManagedObjectModel.mergedModel(from: nil)!
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel!)
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.managedObjectContext?.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        
    }
    
    static func setupContainer () -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "eduid_iOS")
        let storeUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.htwchur.eduid.share")?.appendingPathComponent("eduid_iOS.sqlite")
        print(storeUrl?.absoluteString ?? "no url for container found" )
        let description = NSPersistentStoreDescription()
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.url = storeUrl
        
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeUrl!)]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error) , \(error.userInfo)")
            }
            
        })
        return container
    }
    
    static func getPersistentContainer () -> NSPersistentContainer {
        return self.persistentContainer
    }
    
}

