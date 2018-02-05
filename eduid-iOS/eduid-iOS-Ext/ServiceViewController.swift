//
//  ServiceViewController.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 02.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import JWTswift
import MobileCoreServices
import IGListKit

class ServiceViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    lazy var adapter : ListAdapter = {
       return ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()
    
    var token : TokenModel?
    var protocols : ProtocolsModel?
    var fetchedSuccess : Bool = false
    var exContext : NSExtensionContext?
    var apString: String?
    
    private var sessionKey : [String : Key]?
    private var authprotocols : [String]?
    private var services : Service?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        showToken()
        if !self.checkSessionKey() {
            print("No Session Key")
            return
        }
        
        self.collectionView.collectionViewLayout = UICollectionViewFlowLayout()
        
        adapter.collectionView = collectionView
        adapter.dataSource = self
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
    
    @IBAction func done(_ sender: Any) {
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
        let count = protocols!.getCount()
        var tmpArray : [String] = []
        for i in 0..<count {
            let tmp = ((protocols?.getEngines(entryNumber: i))!)
            tmpArray.append(tmp)
        }
        self.services = Service.init(tmpArray)
        adapter.performUpdates(animated: true)
    }
    
    func authRequest(adress : URL , homepageLink : String){
        
        let authToken = AuthorizationTokenModel()
        print(self.token?.giveAccessToken()! as Any)
        let idToken = self.token?.giveTokenID()?.last
        print(self.token?.giveTokenID()?.first! as Any)
        print(self.token?.giveTokenID()?.last! as Any)
        let assert = authToken.createAssert(addressToSend: adress.absoluteString, subject: idToken!["sub"] as! String, audience: self.apString! , accessToken: (token?.giveAccessToken()!)!, kidToSend: (self.sessionKey!["public"]?.getKid())! , keyToSign: self.sessionKey!["private"]!)
        print("ASSERT : \(assert!)")
        
        authToken.fetch(address: adress, assertionBody: assert!)
    }
    
}

extension ServiceViewController : ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        if self.services == nil {
            return []
        }else {
            return [self.services!] as [ListDiffable]
        }
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return ServiceSectionController(entry: object as! Service, token: self.token!, aud: self.apString!, sessionKeys: self.sessionKey! )
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
}
