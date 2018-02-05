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

class EduidConfigModel : NSObject {
    
    private var entities : [NSManagedObject] = []
    //    private lazy var appDelegate: AppDelegate? = nil
    private lazy var persistentContainer : NSPersistentContainer? = nil
    private lazy var managedContext: NSManagedObjectContext? = nil
    private var jsonDict: [String : Any]?
    
    private var issuer : String?
    
    //Endpoints
    private var auth : URL?
    private var endSession : URL?
    private var userInfo : URL?
    private var introspection : URL?
    private var token : URL?
    private var revocation : URL?
    
    //jwks URI
    private var jwksUri : URL?
    //Additional Data
    private var claims : [String]?
    //private var grantSupported : Bool?
    
    var serverUrl : URL?
    var downloadedSuccess : BoxBinding<Bool?> = BoxBinding(nil)
    var totalSize : String?
    
    init(serverUrl : URL? = nil) {
        super.init()
        //        self.appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
        self.persistentContainer = SharedDataStore.getPersistentContainer()
        self.managedContext = persistentContainer?.viewContext
        
        self.serverUrl = serverUrl
        
        //defer would be called at the end of this init()
        defer{ self.fetchDatabase() }
    }
    
    deinit {
        print("EduidConfigModel is being deinitialized")
    }
    
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
    
    func extractJson (){
        
        self.issuer = jsonDict?["issuer"] as? String
        self.auth = URL(string: jsonDict?["authorization_endpoint"] as! String)
        self.endSession = URL(string: jsonDict?["end_session_endpoint"] as! String)
        self.userInfo = URL(string: jsonDict?["userinfo_endpoint"] as! String)
        self.introspection = URL(string: jsonDict?["introspection_endpoint"] as! String)
        self.token = URL(string: jsonDict?["token_endpoint"] as! String)
        self.revocation = URL(string: jsonDict?["revocation_endpoint"] as! String)
        self.jwksUri = URL(string: jsonDict?["jwks_uri"] as! String)
        
    }
    
    func extractDatabaseData(savedData : NSManagedObject){
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
    
    //Fetch data from core data, usually used at the begining
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
    
    //Fetch some specific data from core data
    func fetchDatabase(withFilter name: String ){
        let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: "EduidConfiguration")
        fetchRequest.predicate = NSPredicate(format: "cfg_name == %@", name)
        do{
            entities = (try managedContext?.fetch(fetchRequest))!
        } catch let error as NSError {
            print("Couldn't fetch the data. \(error), \(error.userInfo)")
        }
        
    }
    
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
    
    func getTokenEndpoint () -> URL? {
        if(self.token == nil){
            return nil
        }
        return self.token!
    }
    
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
    
    func save(){ //(data : [String : String] ){
        
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

extension EduidConfigModel : URLSessionDownloadDelegate {
    
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("FINISHED")
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if self.serverUrl != downloadTask.originalRequest?.url {
            return
        }
        
//        self.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
//        print(self.progress)
        self.totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
    }
    
}


extension URLSession{
    
    
    
    func sendSynchronousRequest(url : URL, completionHandler : @escaping (NSData?, URLResponse?, Error?) -> Void ) {
        
        let semaphore = DispatchSemaphore.init(value: 0)
        let task = self.dataTask(with: url) { (data, response, error) in
            completionHandler(data! as NSData, response, error)
            semaphore.signal()
        }
        task.resume()
        let _ = semaphore.wait(timeout: DispatchTime.init(uptimeNanoseconds: 5000000000)) //5 seconds (in nanosec)
    }
    
}

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

