//
//  ProtocolsModel.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 28.11.17.
//  Copyright © 2017 Blended Learning Center. All rights reserved.
//

import Foundation
import CoreData

/**
 A ViewModel Class who control all the process especially fetching the available services,
 based on the protocols of the third party app
 
 ## Main function :
 - Fetching the available services from a specific URI end point
 
 */
class ProtocolsModel : NSObject {
    //Some essential variable that are required to access the shared data container
    private lazy var entities : [NSManagedObject] = []
    private lazy var persistentContainer: NSPersistentContainer? = nil
    private lazy var managedContext : NSManagedObjectContext? = nil
    
    private var jsonResponse : [Any]?
    private var singleton : Bool
    
    //Variables to contain the essential data for the available services
    private var engineName : [String]?
    private var homePageLink : [String]?
    private var apisLink : [String]?
    
    //boolean to check the download status, could be attached with a listener
    var downloadSuccess : BoxBinding<Bool?> = BoxBinding(nil)
    
    init(singleton : Bool) {
        self.singleton = singleton
        super.init()
    }
    ///default = set as singleton
    convenience override init(){
        self.init(singleton: true)
    }
    
    deinit {
        print("ProtocolsModel is being deinitialized")
    }
    
    //main function to fetch the service data from a specific URI adress
    func fetchProtocols ( address : URL , protocolList : [String]){
        
        let request = NSMutableURLRequest(url: address)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5
        do{
            let arraybody = try JSONSerialization.data(withJSONObject: protocolList, options: [])
            request.httpBody = arraybody
        }catch {
            print(error)
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        print("protocol list : \(protocolList)")
        let dataTask = session.dataTask(with: request as URLRequest)
        dataTask.resume()
    }
    
    //extract the json response and assign them into the object variables
    private func extractJson(){
        
        if self.jsonResponse == nil {
            return
        }
        self.engineName = [String]()
        self.homePageLink = [String]()
        self.apisLink = [String]()
        
        for entity in jsonResponse! {
            let jsonDict = entity as! [String : Any]
            self.engineName?.append( jsonDict["engineName"] as! String )
            self.homePageLink?.append( jsonDict["homePageLink"] as! String)
            
            let apis = jsonDict["apis"] as! [String : Any]
            let apisOauth = apis["org.ietf.oauth2"] as! [String : Any]
            
            self.apisLink?.append(apisOauth["apiLink"] as! String)
        }
    }
    
    //return the number of the available services for the specific protocol, used to generate the cells number for the view
    func getCount() -> Int{
        return (self.engineName?.count)!
    }
    
    func getApisLink(serviceName: String)-> URL?{
        if engineName == nil{
            return nil
        }
        
        let index = engineName!.index(of: serviceName)
        let strUrl = getHomepageLink(entryNumber: index!)! + self.apisLink![index!]
        return URL(string: strUrl)
    }
    
    func getHomepageLink(serviceName: String) -> String?{
        if engineName == nil{
            return nil
        }
        let index = engineName?.index(of: serviceName)
        return self.homePageLink?[index!]
    }
    
    private func getApislink(entryNumber : Int) -> URL? {
        
        let strurl = getHomepageLink(entryNumber: entryNumber)! + self.apisLink![entryNumber]
        let resultUrl = URL(string: strurl)
        
        return resultUrl
    }
    
    private func getHomepageLink(entryNumber : Int) -> String? {
        return self.homePageLink?[entryNumber] ?? nil
    }
    
    func getEngines(entryNumber : Int) -> String? {
        
        return self.engineName?[entryNumber] ?? nil
    }
    
}

// MARK: EXTENSION
//Extension to deal with the response from the server
extension ProtocolsModel : URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
            return
        }
        print("COMPLETE WITH ERROR")
        
        self.downloadSuccess.value = nil
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        let httpResponse = dataTask.response as! HTTPURLResponse
        print("Did receive response with status : \(httpResponse.statusCode) (ProtocolsModel)")
        if httpResponse.statusCode != 200 {
            self.downloadSuccess.value = false
            return
        }
        
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        do{
            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as! [Any]
            print("Response : \(jsonResponse)")
            self.jsonResponse =  jsonResponse
            self.extractJson()
            downloadSuccess.value = true
        }catch {
            print(error.localizedDescription)
        }
        
    }
    
}
