//
//  AuthorizationToken.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 26.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import Foundation
import CoreData
import JWTswift

class AuthorizationTokenModel : NSObject {
    
    private lazy var entities : [NSManagedObject] = []
    private lazy var persistentContainer : NSPersistentContainer? = nil
    private lazy var managedContext : NSManagedObjectContext? = nil
    
    private var jsonResponse : [String : Any]?
    
//    private let client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    private let grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    var downloadSuccess : BoxBinding<Bool?> = BoxBinding(nil)
    
    override init() {
        super.init()
        
//        self.
    }
    
    deinit {
        print("AuthorizationTokenModel is being deinitialized")
    }
    
    func createAssert(addressToSend : String, subject : String , audience : String, accessToken : String ,kidToSend : String , keyToSign : Key) -> String? {
        var payload = [String : Any]()
        payload["azp"] = addressToSend
        payload["iss"] = UIDevice.current.identifierForVendor?.uuidString
        payload["aud"] = audience
        payload["sub"] = subject
            
        let timestamp = Int(Date().timeIntervalSince1970)
        payload["iat"] = String(timestamp)
        payload["cnf"] = ["kid" : kidToSend]
            
        payload["x_jwt"] = accessToken
        print("assert Payload: \(payload)")
        let jwt = JWS.init(payloadDict: payload)
        
        return jwt.sign(key: keyToSign, alg: .RS256)
    }
    
    func fetch (address : URL, assertionBody : String ){
        
        let body = [ "assertion" : assertionBody,
            "grant_type" : self.grant_type
                    ]
        let bodyUrl = httpBodyBuilder(dict: body)
        let strUrl = address.absoluteString + "?" + bodyUrl
        
        let request = NSMutableURLRequest(url: URL(string: strUrl)!)
        request.httpMethod = "GET"
        print("FETCH : " , request.url)
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let dataTask = session.dataTask(with: request as URLRequest)
        dataTask.resume()
    }
    
    
    
    private func extractJson(){
        
    }
    
    private func httpBodyBuilder(dict : [String: Any]) -> String {
        var resultArray = [String]()
        
        for (key,value) in dict {
            let keyEncoded =  key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let valueEncoded = (value as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let encodedEntry = keyEncoded + "=" + valueEncoded
            
            resultArray.append(encodedEntry)
        }
        print("HTTP BODY : " ,resultArray.joined(separator: "&"))
        return resultArray.joined(separator: "&")
    }
    
    
}

extension AuthorizationTokenModel : URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Did complete with Error : \(error.debugDescription)")
        self.downloadSuccess.value = nil
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        let httpResponse = dataTask.response as! HTTPURLResponse
        print("Did receive response with status : \(httpResponse.statusCode)")
        if(httpResponse.statusCode != 200){
            print("Response : \(httpResponse.description)" )
            self.downloadSuccess.value = false
            return
        }
        completionHandler(URLSession.ResponseDisposition.allow)
        
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        do{
            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
            print("Response : \(jsonResponse)")
            self.jsonResponse = jsonResponse
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
}
