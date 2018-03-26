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
    
    private var rsdResponse : [Any]?
    private var singleton : Bool
    private var protocolList : [String]?
    
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
        self.protocolList = protocolList
        
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
        
        if self.rsdResponse == nil {
            return
        }
        self.engineName = [String]()
        self.homePageLink = [String]()
        self.apisLink = [String]()
        
        for entity in rsdResponse! {
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
        return (self.engineName?.count) ?? 0
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
    
    func applyAuthorization( authorization: [String:Any] ) -> Data? {
        var arrayTmp : [Any] = [Any]()
        
        for serviceName in authorization.keys {
            
            for index in 0..<rsdResponse!.count{
                
                let discoveredService = rsdResponse![index]
                
                guard var discoveredTmp = discoveredService as? [String: Any] else { continue }
                if discoveredTmp["engineName"] as! String == serviceName {
                    print("Put AUTH tag here!")
                    
                    discoveredTmp["authorization"] = authorization[serviceName]
                    
                    arrayTmp.append(discoveredTmp)
                } /*else {
                    arrayTmp.append(discoveredService)
                }*/
                
            }
            
        }
        
        print("COMPLETED RSD : " , arrayTmp)
        arrayTmp = apisFiltern(completedRSD: arrayTmp)
        do{
            let json = try JSONSerialization.data(withJSONObject: arrayTmp, options: [])
            return json
        } catch {
            print("Error: problem on creating json Data")
            return nil
        }
    }
    
    func apisFiltern(completedRSD : [Any]) -> [Any]{
        print("BEFORE FILTER ::  ", completedRSD)
        let protocols  = self.protocolList!
        var result = [Any]()
        
        for index in 0..<completedRSD.count {
            
            guard var rsdEntry = completedRSD[index] as? [String: Any] else {
                continue
            }
            
            var filteredRSD = rsdEntry
            var filteredApis = [String : Any]()
            
            guard let apis  = rsdEntry["apis"] as? [String : Any] else {
                continue
            }
            print(apis.description)
            
            for api in apis.keys{
                
                for protocolTmp in protocols {
                    
                    if protocolTmp == api {
                        print("FOUND : \(protocolTmp)")
                        filteredApis[api] = apis[api]
                    }
                    
                }
            
            }
            
            filteredRSD["apis"] = filteredApis
            result.append(filteredRSD)
        }
        print("AFTER FILTER :: " , result)
        return result
        
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
            self.rsdResponse =  jsonResponse
            self.extractJson()
            self.downloadSuccess.value = true
        }catch {
            print(error.localizedDescription)
        }
        
    }
    
}
