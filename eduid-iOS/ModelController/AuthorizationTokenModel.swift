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

/**
 A ViewModel Class who control all the authorization process, this class would send a get request to the Resource Provider.
 Resource provider then would be verify the data, and return an access token as a reply, if the user has a right to access the data from RP (Resource Provider)
 This view model would be used only on the app extension.
 
 ## Main functions :
 - Request the access token from the resource provider
 - Extract the access token from the RP, if available
 */
class AuthorizationTokenModel : NSObject {
    //Some essential variable that are required to access the shared data container
    private lazy var entities : [NSManagedObject] = []
    private lazy var persistentContainer : NSPersistentContainer? = nil
    private lazy var managedContext : NSManagedObjectContext? = nil
    
    //contains the whole raw response from the resource provider
    private var jsonResponse : [String : Any]?
    
//    private let client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    private let grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    
    //boolean to check the download status, could be attached with a listener
    var downloadSuccess : BoxBinding<Bool?> = BoxBinding(nil)
    
    override init() {
        super.init()

    }
    
    deinit {
        print("AuthorizationTokenModel is being deinitialized")
    }
    
    //Create the assert in from of JWS to be sent into the resource provider
    func createAssert(addressToSend : String, subject : String , audience : String, accessToken : String ,kidToSend : String , keyToSign : Key, keyToEncrypt: Key?) -> String? {
        var payload = [String : Any]()
        
        // This if case is ONLY FOR TESTING moodle core dev RFC 7521 + 23
        if(addressToSend.contains("moodle-dev.htwchur")){
            print("CreateAssert addressTosend = " , addressToSend)
            payload["azp"] = "https://moodle-dev.htwchur.ch/julius/admin/oauth2callback.php"
            
        } else {
            payload["azp"] = addressToSend
        }
        
        //payload["azp"] = addressToSend
        payload["iss"] = UIDevice.current.identifierForVendor?.uuidString
        payload["aud"] = audience
        payload["sub"] = subject
            
        let timestamp = Int(Date().timeIntervalSince1970) - 70 //remove 70 ticks workaround from server rejection
        payload["iat"] = String(timestamp)
        payload["cnf"] = ["kid" : kidToSend]
            
        payload["x_jwt"] = accessToken
        print("assert Payload: \(payload)")
        let jws = JWS(payloadDict: payload)
        let jwsCompact = jws.sign(key: keyToSign, alg: .RS256)
        
        // TODO JWE :: server and moodle plugin cannot handle the JWE correctly yet
        if keyToEncrypt != nil {
            let jwe : JWE
            do{
                jwe = try JWE(plainJWS: jwsCompact!, alg: .RSA_OAEP_256, publicKey: keyToEncrypt!, kid: keyToEncrypt!.getKid()!, aud: audience)
            } catch {
                print(error)
                return nil
            }
            
//            return jwe.getCompactJWE()
            return jwsCompact!
            
        } else {
            // Just JWS
            return jwsCompact!
        }
        
    }
    
    //Main function to request the token from the resource provider(RP)
    func fetch (address : URL, assertionBody : String ){
        // for testing moodle core dev RFC 7521 + 23
        var addressTmp = address
        if(address.absoluteString.contains("moodle-dev.htwchur")){
            print("HTW dev!! = " , address.absoluteString)
            addressTmp = URL(string: "https://moodle-dev.htwchur.ch/julius/admin/oauth2callback.php")!
        }
        //end of testing code
        let body = [ "assertion" : assertionBody,
            "grant_type" : self.grant_type
                    ]
        let bodyUrl = httpBodyBuilder(dict: body)
        let strUrl = addressTmp.absoluteString + "?" + bodyUrl
        
        let request = NSMutableURLRequest(url: URL(string: strUrl)!)
        request.httpMethod = "GET"
        request.timeoutInterval = 4
        print("FETCH : " , request.url as Any)
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let dataTask = session.dataTask(with: request as URLRequest)
        dataTask.resume()
    }
    
    //This function return the raw response from the server in a Data format
    func giveJsonResponse() -> Data? {
        do{
            let json = try JSONSerialization.data(withJSONObject: self.jsonResponse!, options: [])
            return json
        }catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func giveResponseAsDict() -> [String: Any]? {
        return jsonResponse
    }
    
    private func extractJson(){
        
    }
    
    //Additional function to ease the combining process of the Http body data, which are wanted to be sent
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

// MARK: EXTENSION
// Extension to deal with the response from the server
extension AuthorizationTokenModel : URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Did complete with Error : \(error.debugDescription)")
        if(error != nil){
            self.downloadSuccess.value = nil
        }
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
            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as! [String : Any]
            print("Response : \(jsonResponse)")
            self.jsonResponse = jsonResponse
            self.downloadSuccess.value = true
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
}
