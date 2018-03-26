//
//  TokenModel.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 28.11.17.
//  Copyright © 2017 Blended Learning Center. All rights reserved.
//

import Foundation
import CoreData
import JWTswift

/**
 A ViewModel Class who control all the process of authentication, based on transferring the login token to the Autorization Provider, in this case Edu-ID Service
 
 ## Main functions :
 - Sending the login data in a signed JWT format
 - Extract the response from the AP/ Edu-ID service
 - Saving the response data into the shared data container
 - Fetch the saved data from the shared data container into the object variables
 */
class TokenModel : NSObject {
    //Some essential variable that are required to access the shared data container
    private lazy var entities : [NSManagedObject] = []
    private var persistentContainer : NSPersistentContainer? = nil
    private var managedContext : NSManagedObjectContext? = nil
    
    //an URI endpoint of the authentication server, this class would communicate only with this server for the whole process
    private var tokenURI : URL?
    
    //Essential data, which usually received from the server as a successful response
    private var accesToken : String?
    private var refreshToken : String?
    private var expired : Int?
    private var id_token : String?
    private var tokenType : String?
    
    
    private var jsonResponse : [String : Any]?
    private var id_tokenParsed : [[String : Any]]?

    //some constants
    private let client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    private let grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    
    //A boolean to check if the login successful or not, could be attached with a listener
    var downloadSuccess : BoxBinding<Bool?> = BoxBinding(nil)
    
    init( tokenURI : URL? = nil ) {
        super.init()
        
        self.tokenURI = tokenURI
        self.persistentContainer = SharedDataStore.getPersistentContainer()
        self.managedContext = self.persistentContainer?.viewContext
    }
    
    deinit {
            print("TokenModel is being deinitialized")
    }
    
    // TODO : This function is currently not being used
    func createClientAssertion (receiver : String, keyToSign : Key) -> String {
        
        var payload = [String : String]()
        payload["aud"] = receiver
        payload["jti"] = UUID().uuidString
        //3 years timestamp from now
        let date = Date(timeIntervalSinceNow: 94610000)
        var timestamp = Int(date.timeIntervalSince1970)
        payload["exp"] = String(timestamp)
        
        timestamp = Int(Date().timeIntervalSince1970)
        payload["iat"] = String(timestamp)
        
        print("uuid : \(String(describing: payload["jti"] ))")
        
        let jwt = JWS(payloadDict: payload)
        
        return jwt.sign(key: keyToSign, alg: .RS256)!
    }
    
    //creating a specific user assertion in a signed JWS format, based on the user credentials
    func createUserAssert(userSub : String, password : String ,issuer: String, audience : String , keyToSend: Key , keyToSign: Key) -> String? {
        
        let jwk = KeyStore.keyToJwk(key: keyToSend)
        print("KEYTOSEND : \(String(describing: jwk))")
        let cnf = ["jwk" : jwk!] as [String : Any]
        
        var payload = [String : Any] ()
        payload["iss"] = issuer
        payload["sub"] = userSub
        payload["aud"] = audience
        
        //3 years timestamp from now
        let date = Date(timeIntervalSinceNow: 94610000)
        var timestamp = Int(date.timeIntervalSince1970)
        payload["exp"] = String(timestamp)
        
        timestamp = Int(Date().timeIntervalSince1970)
        payload["iat"] = String(timestamp)
        payload["cnf"] = cnf
        payload["azp"] =  UIDevice.current.identifierForVendor?.uuidString //jwk?["kid"]?
        payload["x_crd"] = password
        
        let jwt = JWS.init(payloadDict: payload)
        
        return jwt.sign(key: keyToSign, alg: .RS256)
    }
    
    //Delete all relevant data of this class from variables and also from the shared data container,
    //This function is usually called after the user logout.
    func deleteAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: "Tokens")
        let req = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do{
            try managedContext?.execute(req)
            try managedContext?.save()
        }catch {
            print("Delete Failed : \(error) , \(error.localizedDescription)")
        }
        deleteCurrent()
    }
    
    private func deleteCurrent () {
        self.accesToken = nil
        self.refreshToken = nil
        self.expired = nil
        self.id_token = nil
        self.tokenType = nil
        self.jsonResponse = nil
        
        self.downloadSuccess.value = nil
    }
    
    //Extract the credentials data of the registered user from the database
    func extractDatabaseData(savedData : NSManagedObject){
        self.accesToken = savedData.value(forKey: "accessToken") as? String
        //        self.refreshToken = savedData.value(forKey: "refreshToken") as? String
        self.expired = savedData.value(forKey: "exp") as? Int
        self.id_token = savedData.value(forKey: "id_token") as? String
        self.tokenType = savedData.value(forKey: "tokenType") as? String
        
        parseTokenID()
    }
    
    //extract the data from the response, and assign them into the object variables
    func extractJson() {
        if jsonResponse == nil {
            print("JSON RESPONSE is empty!")
            return
        }
        //print(jsonResponse?.keys)
        self.id_token = jsonResponse!["id_token"] as? String
        self.accesToken = jsonResponse!["access_token"] as? String
        self.expired = jsonResponse!["expires_in"] as? Int
        print(self.expired!)
        self.tokenType = jsonResponse!["token_type"] as? String
        
    }
    
    ///Fetch the credentials data of the registered user from the database
    func fetchDatabase() -> Bool{
        let fetchRequest = NSFetchRequest<NSManagedObject>.init(entityName: "Tokens")
        do{
            entities = (try managedContext?.fetch(fetchRequest))!
        } catch{
            print("Couldn't fetch the data. \(error), \(error.localizedDescription)")
        }
        print("Token Fetched (fetchDatabase) : " , self.entities.count)
        if(entities.count > 0 ) {
            let entity = entities.first
            extractDatabaseData(savedData: entity!)
            return true
        } else {
            return false
        }
        
    }
    /**
     Main function to send the credentials data from the app into the authentication server
     
     - parameter username : Username on this case is the app's username, which is registered already inside the server, !!NOT user's data!!
     - parameter password : Password on this case is the app's password, !!NOT user's data'
     - Throws : throw ns error if there isn't any url found on the class variable
 */
    func fetchServer(username : String , password : String, assertionBody : String) throws {
        
        if self.tokenURI == nil {
            throw NSError.init(domain: "No URL found in token model", code: 404, userInfo: nil)
        }
        
        let request  = NSMutableURLRequest(url: self.tokenURI!)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        let loginString = String.init(format: "%@:%@", username, password)
        let loginData = loginString.data(using: .utf8)!
        let base64loginString  = loginData.base64EncodedString().clearPaddding()
        let body  = [ "grant_type" : self.grant_type ,
                      "assertion" : assertionBody,
                      "scope" : "openid profile email address phone" // \(username) julius.saputra@htwchur.ch"
        ]
        
        request.httpMethod = "POST"
        request.httpBody = httpBodyBuilder(dict: body).data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic \(base64loginString)" , forHTTPHeaderField: "Authorization")
        
        let dataTask  = session.dataTask(with: request as URLRequest)
        dataTask.resume()
        
    }
    
    func giveAccessToken() -> String? {
        return self.accesToken
    }
    
    func giveTokenID() -> [[String : Any]]? {
        return self.id_tokenParsed
    }
    
    func giveTokenIDasJSON() -> Data? {
        var jsonDict = [String:Any]()
        jsonDict["header"] = id_tokenParsed?.first
        jsonDict["payload"] = id_tokenParsed?.last
        do{
            let json = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
            return json
        }catch {
            print(error.localizedDescription)
            return nil
        }
        
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
    
    
    func giveIdTokenJWS() -> [String : Any]?{
        /*
        guard let jwsToParse : String = self.jsonResponse?["id_token"] as? String else {
            return nil
        }*/
        guard let jwsToParse : String  = self.id_token else {
            return nil
        }
        
        guard let result : [String : Any] = JWS.parseJWSpayload(stringJWS: jwsToParse) else {
            return nil
        }
        
        return result
    }
    
    func parseTokenID () {
        self.id_tokenParsed = [[String : Any]]()
        id_tokenParsed?.append( JWS.parseJWSheader(stringJWS: self.id_token!)! )
        id_tokenParsed?.append(JWS.parseJWSpayload(stringJWS: self.id_token!)!)
    }
    
    // FIXME: why save "expired" in database model as Integer 64 result a crash
    // Save the current token variables into the shared data store, for the next usage of the app.
    func save() {
        let entity = NSEntityDescription.entity(forEntityName: "Tokens", in: self.managedContext!) as NSEntityDescription!
        let tokenData = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        tokenData.setValue(accesToken, forKey: "accessToken")
        tokenData.setValue(String(describing: expired), forKey: "exp")
        tokenData.setValue(id_token, forKey: "id_token")
        //        tokenData.setValue(refreshToken, forKey: "refreshToken")
        tokenData.setValue(tokenType, forKey: "tokenType")
        
        do{
            try managedContext?.save()
            print("TOKEN SAVED")
        }catch{
            print("Couldn't save the token data. \(error) , \(error.localizedDescription)")
        }
    }
    
    //Set the destination uri, which the credential data will be sent to
    func setURI(uri : URL) {
        self.tokenURI = uri
    }
    
    // TODO: Optional, validate the access token, which the app received from the server
    func validateAccessToken () -> Bool {
        if self.id_tokenParsed == nil &&  id_tokenParsed?.first!["alg"] as! String != "RS256" {
            return false
        }
        print(id_tokenParsed?.first! as Any)
        print(id_tokenParsed?.last! as Any)
        print("at hash count : " , (id_tokenParsed?.last!["at_hash"] as! String).count )
        
        let data = accesToken?.data(using: .utf8)
        let hash = data?.hashSHA256()
        let hashString = hash!.base64EncodedString()
        let midIndex = hashString.index((hashString.startIndex), offsetBy: ((hashString.count)/2) )
        let hashresult = String(hashString[ ..<midIndex]).base64ToBase64Url()
        print("hash1 : " , hashresult)
        
        if id_tokenParsed?.last!["at_hash"] as! String == hashresult {
            return true
        } else {
            return false
        }
    }
    
    //Verify the JWS from the server, with the help of JWTswift library
    func verifyIDToken() -> Bool {
        self.parseTokenID()
        let ks = KeyStore.init()
        let pathToPubKey = Bundle.main.url(forResource: "eduid_pub", withExtension: "jwks")
        let keys = ks.jwksToKeyFromBundle(jwksPath: (pathToPubKey?.relativePath)!)
        let result = JWS.verify(jwsToVerify: self.id_token!, key: (keys?.first)!)
        
        return result
        
    }
    
}

// MARK: EXTENSION
// Extension to deal with the response from the server
extension TokenModel : URLSessionDataDelegate {
    
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
        print("Did receive data, data length: \(data.count)")
        
        do{
            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
            print("Response : \(jsonResponse)")
            self.jsonResponse = jsonResponse
            self.extractJson()
            if self.verifyIDToken() {
//                let _ = validateAccessToken()
                self.downloadSuccess.value = true
            } else {
                self.downloadSuccess.value = false
            }
            self.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
}
