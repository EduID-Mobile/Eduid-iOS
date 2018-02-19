//
//  EduidConfigModel.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 28.11.17.
//  Copyright © 2017 Blended Learning Center. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/**
 A ViewModel Class who control all the processes around configuration data. This config data are essential, to let the app know where should this app send its data to.
 
 ## Main functions  :
 - Fetching the configuration data from a specific URI or Database
 - Saving the fetched data into the shared data container
 */
class EduidConfigModel : NSObject {
    //Some essential variable that are required to access the shared data container
    private var entities : [NSManagedObject] = []
    private lazy var persistentContainer : NSPersistentContainer? = nil
    private lazy var managedContext: NSManagedObjectContext? = nil
    
    private var jsonDict: [String : Any]?
    
    //Essential Data from URI/ data container
    private var issuer : String?
    private var auth : URL?
    private var endSession : URL?
    private var userInfo : URL?
    private var introspection : URL?
    private var token : URL?
    private var revocation : URL?
    private var jwksUri : URL?
    
    //Additional Data
    private var claims : [String]?
    
    //URI where the config data are stored
    var serverUrl : URL?
    
    var downloadedSuccess : BoxBinding<Bool?> = BoxBinding(nil)
    var totalSize : String?
    
    init(serverUrl : URL? = nil) {
        super.init()
    
        self.persistentContainer = SharedDataStore.getPersistentContainer()
        self.managedContext = persistentContainer?.viewContext
        
        self.serverUrl = serverUrl
        
        //defer would be called at the end of this init()
        defer{ self.fetchDatabase() }
    }
    
    deinit {
        print("EduidConfigModel is being deinitialized")
    }
    
    /**
     Delete a specific attribute(s) from the entities
     */
    func delete(name : String) {
        let indexHelper = searchData(name: name)
        if indexHelper.count <= 0{
            return
        }
        for i in indexHelper{
            
            do {
                managedContext?.delete(entities[i] as NSManagedObject)
                try managedContext?.save()
            }catch let error as NSError{
                print("Error on deleting request. \(error)  : \(error.userInfo)")
            }
            
        }
    }
    
    /**
     Delete/clear all the config data from the class variable, and also from the shared data container.
 */
    func deleteAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EduidConfiguration")
        let req = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do{
            try managedContext?.execute(req)
            try managedContext?.save()
        }catch let error as NSError {
            print("Delete Failed : \(error) , \(error.userInfo)")
        }
        
        self.issuer = nil
        self.auth = nil
        self.endSession = nil
        self.userInfo = nil
        self.introspection = nil
        self.token = nil
        self.revocation = nil
        self.jwksUri = nil
        
        self.downloadedSuccess.value = nil
    }
    
    //Extract the json response from the server and assign them into the object variables
    private func extractJson (){
        
        self.issuer = jsonDict?["issuer"] as? String
        self.auth = URL(string: jsonDict?["authorization_endpoint"] as! String)
        self.endSession = URL(string: jsonDict?["end_session_endpoint"] as! String)
        self.userInfo = URL(string: jsonDict?["userinfo_endpoint"] as! String)
        self.introspection = URL(string: jsonDict?["introspection_endpoint"] as! String)
        self.token = URL(string: jsonDict?["token_endpoint"] as! String)
        self.revocation = URL(string: jsonDict?["revocation_endpoint"] as! String)
        self.jwksUri = URL(string: jsonDict?["jwks_uri"] as! String)
        
    }
    
    //Extract the saved data from data container and assign them into the object varuiables
    private func extractDatabaseData(savedData : NSManagedObject){
        self.issuer = savedData.value(forKey: "issuer") as? String
        self.auth = URL(string: savedData.value(forKey: "auth") as! String)
        self.endSession = URL(string: savedData.value(forKey:"endSession") as! String)
        self.userInfo = URL(string: savedData.value(forKey: "userInfo") as! String)
        self.introspection = URL(string: savedData.value(forKey: "introspection") as! String)
        self.token = URL(string: savedData.value(forKey: "token") as! String)
        self.revocation = URL(string: savedData.value(forKey: "revocation") as! String)
        self.jwksUri = URL(string: savedData.value(forKey: "jwksUri") as! String)
    }
    
    //Fetch config data from the EDU-ID Server
    func fetchServer() {
        
        var request = URLRequest(url: self.serverUrl!)
        request.timeoutInterval = 5
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let dataTask = session.dataTask(with: request)
        dataTask.resume()
        
    }
    
    //Fetch data from share data container, usually used at the begining
    func fetchDatabase(){
        let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: "EduidConfiguration")
        do{
            entities = (try managedContext?.fetch(fetchRequest))!
        } catch let error as NSError {
            print("Couldn't fetch the data. \(error), \(error.userInfo)")
        }
        print("FETCHED (fetchDatabase) : " , self.entities.count )
        
        //assuming there is just one config data in core data
        if(entities.count > 0) {
            let entity = entities.first
            extractDatabaseData(savedData: entity!)
        }
        
    }
    
    //Fetch some specific data from the shared data container
    func fetchDatabase(withFilter name: String ){
        let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: "EduidConfiguration")
        fetchRequest.predicate = NSPredicate(format: "cfg_name == %@", name)
        do{
            entities = (try managedContext?.fetch(fetchRequest))!
        } catch let error as NSError {
            print("Couldn't fetch the data. \(error), \(error.userInfo)")
        }
        
    }
    
    //get the data in NSDictionary format
    func getAll() -> [NSDictionary] {
        if entities.count == 0 {return []}
        //print("in get all : ", eduidConfigData.count)
        
        var configArray = [NSMutableDictionary]()
        
        for i in 0 ..< entities.count {
            //print("in for")
            let config = entities[i]
            let entityDesc = config.entity
            let attributes = entityDesc.attributesByName
            
            let dictConfig = NSMutableDictionary()
            
            for attributeName in attributes.keys {
                //print("in second for")
                let tmpValue = config.value(forKey: attributeName)
                dictConfig.setValue(tmpValue, forKey: attributeName)
                //                print(dictConfig.value(forKey: attributeName)!);
            }
            //print("dictConfig : ", dictConfig.count)
            configArray.append(dictConfig)
        }
        //print("ENDE : " , configArray.count)
        return configArray
        
    }

    //getting the token Endpoint (for the login)
    func getTokenEndpoint () -> URL? {
        if(self.token == nil){
            return nil
        }
        return self.token!
    }
    
    //get the issuer info
    func getIssuer () -> String? {
        if self.issuer == nil {
            return nil
        }
        return self.issuer
    }
    
    func printAllData () {
        for confData in entities{
            //print("printALL")
            let entityDesc = confData.entity
            let keys = entityDesc.attributesByName
            
            for key in keys.keys {
                print("Printing Data , key : ",  key , " , value :" , confData.value(forKey: key) as Any)
            }
        }
    }
    
    //Save the current object variables into the shared data container
    func save(){
        
        let entity = NSEntityDescription.entity(forEntityName: "EduidConfiguration", in: managedContext!) as NSEntityDescription!
        let configData = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        configData.setValue(auth?.absoluteString, forKey: "auth")
        configData.setValue(endSession?.absoluteString, forKey: "endSession")
        configData.setValue(introspection?.absoluteString, forKey: "introspection")
        configData.setValue(issuer, forKey: "issuer")
        configData.setValue(jwksUri?.absoluteString, forKey: "jwksUri")
        configData.setValue(revocation?.absoluteString, forKey: "revocation")
        configData.setValue(token?.absoluteString, forKey: "token")
        configData.setValue(userInfo?.absoluteString, forKey: "userInfo")
        
        do{
            try managedContext!.save()
            print("CONFIGDATA SAVED")
        } catch let error as NSError {
            print("Couldn't save the data. \(error), \(error.userInfo)")
        }
    }
    
    //Function to search a specific entry inside the shared data container
    func searchData(name : String) -> [Int] {
        var result : [Int] = []
        
        for i in 0 ..< entities.count {
            let configData = entities[i]
            //print("search DATA : " , configData.value(forKey: "cfg_name") )
            //print("in search data " , configData.entity.propertiesByName.keys.contains(name))
            if configData.value(forKey: "cfg_name") as! String == name {
                result.append(i)
            }
            continue
        }
        
        return result
    }
    
}


// MARK: EXTENSION
// Extension to manage the response data from the server
extension EduidConfigModel : URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if(error == nil){
            return
        }
        print("Session complete with error : \(error.debugDescription)")
        
        self.downloadedSuccess.value = nil
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        let httpResponse = dataTask.response as! HTTPURLResponse
        print("Did Receive Response with Status: " , httpResponse.statusCode)
        if(httpResponse.statusCode != 200){
            self.downloadedSuccess.value = false
            return
        }
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("Did receive data , data length: " , data.count)
        do{
            jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
        } catch{
            print(error)
            return
        }
        print(jsonDict!)
        let supportedTypes = jsonDict!["grant_types_supported"] as! [String]
        for type in supportedTypes{
            //print(type , " contain bearer : " , type.contains("jwt-bearer"))
            if type.contains("jwt-bearer") {
                extractJson()
                save()
            }
        }
        self.downloadedSuccess.value = true
    }
}

