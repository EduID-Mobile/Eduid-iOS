//
//  ProtocolsModel.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 28.11.17.
//  Copyright © 2017 Blended Learning Center. All rights reserved.
//

import Foundation
import CoreData

class ProtocolsModel : NSObject {
    
    private lazy var entities : [NSManagedObject] = []
    private lazy var persistentContainer: NSPersistentContainer? = nil
    private lazy var managedContext : NSManagedObjectContext? = nil
    
    private var jsonResponse : [Any]?
    
    private var engineName : [String]?
    private var homePageLink : [String]?
    private var apisLink : [String]?
    
    var downloadSuccess : BoxBinding<Bool?> = BoxBinding(nil)
    
    override init() {
        super.init()
    }
    
    deinit {
        print("ProtocolsModel is being deinitialized")
    }
    
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
    
    func getCount() -> Int{
        return (self.engineName?.count)!
    }
    
    func getApislink(entryNumber : Int) -> URL? {
        
        let strurl = getHomepageLink(entryNumber: entryNumber)! + self.apisLink![entryNumber]
        let resultUrl = URL(string: strurl)
        
        return resultUrl
    }
    
    func getHomepageLink(entryNumber : Int) -> String? {
        return self.homePageLink?[entryNumber] ?? nil
    }
    
    func getEngines(entryNumber : Int) -> String? {
        
        return self.engineName?[entryNumber] ?? nil
    }
    
}

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
