//
//  ActionViewController.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 30.11.17.
//  Copyright © 2017 Blended Learning Center. All rights reserved.
//

import UIKit
import MobileCoreServices
import JWTswift
//DONT USED THIS CLASS ANYMORE
class ServiceListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    
    var token : TokenModel?
    var protocols : ProtocolsModel?
    var fetchedSuccess : Bool = false
    var exContext : NSExtensionContext?
    var apString : String?
    
    private var sessionKey : [String : Key]?
    private var authprotocols : [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("IN EXTENSION service list....")
        self.navigationController?.isNavigationBarHidden = true
//        imageView.image = UIImage(named: "appicontest")
//        let keyStore = KeyStore()
//        //key to sign
//        var urlPathKey = Bundle.main.url(forResource: "ios_priv", withExtension: "jwks")
//        let keyID = keyStore.getPrivateKeyIDFromJWKSinBundle(resourcePath: (urlPathKey?.relativePath)!)
//        urlPathKey = Bundle.main.url(forResource: "ios_priv", withExtension: "pem")
//
//        guard let privateKeyID = keyStore.getPrivateKeyFromPemInBundle(resourcePath: (urlPathKey?.relativePath)!, identifier: keyID!) else {
//            print("ERROR getting private key")
//            return
//        }
        
        showToken()
        
        if !self.checkSessionKey() {
            print("NO SESSION KEY")
            return
        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        print("VIEW WILL DISAPPEAR extension")
        //        token?.deleteAll()
    }
    
    func checkSessionKey() -> Bool {
        
        sessionKey = KeyChain.loadKeyPair(tagString: "sessionKey")
        
        if sessionKey != nil {
            print("Keys already existed")
            return true
        } else {
            return false
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.exContext?.completeRequest(returningItems: [], completionHandler: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
    @IBAction func done() {
        
        let item = token?.giveTokenIDasJSON()
        let returnProvider = NSItemProvider(item: item! as NSSecureCoding, typeIdentifier: kUTTypeJSON as String)
        
        let returnItem = NSExtensionItem()
        
        if !self.fetchedSuccess {
            //            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            self.exContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
        
        returnItem.attachments = [returnProvider]
        
        //        self.extensionContext!.completeRequest(returningItems: [returnItem], completionHandler: nil)
        self.exContext?.completeRequest(returningItems: [returnItem], completionHandler: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func showToken() {
        
        self.token = TokenModel()
        self.authprotocols = [String]()
        if !(token?.fetchDatabase())! {
            return
        }
        
        let textItem = self.exContext?.inputItems.first as! NSExtensionItem
        
        let group = DispatchGroup()
        
        for itemProvider in textItem.attachments! {
            group.enter()
            
            let textItemProvider = itemProvider as! NSItemProvider
            
            if  textItemProvider.hasItemConformingToTypeIdentifier(kUTTypePlainText as String) {
                
                textItemProvider.loadItem(forTypeIdentifier: String(kUTTypePlainText), options: nil, completionHandler: { (result, error) in
                    let text = result as! String
                    print(text)
                    self.authprotocols?.append(text)
                    group.leave()
                })
            }
        }
        self.fetchedSuccess = true
        
        group.notify(queue: .main) {
            self.showProtocols()
        }
    }
    
    func showProtocols() {
        let addresss = URL.init(string: loadProtocolURLFromPlist()! )
        self.protocols = ProtocolsModel()
        
        protocols!.downloadSuccess.bind {
            self.checkDownload(downloaded: $0 )
        }
        
        protocols?.fetchProtocols(address: addresss!, protocolList: authprotocols!)
    }
    
    func loadProtocolURLFromPlist() -> String? {
        if let path = Bundle.main.path(forResource: "Setting", ofType: "plist") {
            if let dic = NSDictionary(contentsOfFile: path) as? [String : Any] {
                return dic["RSDprotocol"] as? String
            }
        }
        return nil
    }
    
    func checkDownload(downloaded : Bool?){
        print("checkDownload in ServiceListViewController : \(String(describing: downloaded))")
        if downloaded == nil || !downloaded! {
            return
        }
        //TODO create handler for no connection and rejected request
        //        self.availableServices = (protocols?.getEngines())!
        DispatchQueue.main.sync {
            self.tableView.reloadData()
        }
        
        
    }
    
    func showList(_ downloaded : Bool){
        if(downloaded){
            print("DOWNLOADED")
        } else {
            print("NOT DOWNLOADED")
        }
    }
    
    func authRequest(adress : URL , homepageLink : String){
        
        let authToken = AuthorizationTokenModel()
        print(self.token?.giveAccessToken()! as Any)
        let idToken = self.token?.giveTokenID()?.last
        print(self.token?.giveTokenID()?.first as Any)
        print(self.token?.giveTokenID()?.last as Any)
        let assert = authToken.createAssert(addressToSend: adress.absoluteString, subject: idToken!["sub"] as! String, audience: self.apString! , accessToken: (token?.giveAccessToken()!)!, kidToSend: (self.sessionKey!["public"]?.getKid())! , keyToSign: self.sessionKey!["private"]!)
        print("ASSERT : \(assert!)")
        
        authToken.fetch(address: adress, assertionBody: assert!)
    }
    
}

extension ServiceListViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.protocols == nil) {
            return 0
        } else {
            return (self.protocols?.getCount())!
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellExt")
        cell?.textLabel?.text = self.protocols?.getEngines(entryNumber: indexPath.row)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("TAPPED row : \(indexPath.row)")
        
        let apiLink = self.protocols?.getApislink(entryNumber: indexPath.row)
        if apiLink == nil {
            return
        }
        self.authRequest(adress: apiLink!, homepageLink: (self.protocols?.getHomepageLink(entryNumber: indexPath.row))!)
    }
    
}



