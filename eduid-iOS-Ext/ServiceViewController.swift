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
import NVActivityIndicatorView

class ServiceViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    private var indicator : NVActivityIndicatorView!
    
    lazy var adapter : ListAdapter = {
       return ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()
    
    var token : TokenModel?
    var protocols : ProtocolsModel?
    var authToken = AuthorizationTokenModel()
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
        
        self.authToken.downloadSuccess.bind { (dlbool) in
            DispatchQueue.main.async{
                self.removeLoadUI()
                if dlbool == nil {
                    self.showAlertUILogin()
                }
                else if dlbool == false {
                    self.requestUnsuccessful()
                } else {
                    self.done(self)
                }
            }
        }
        
        self.setUIelements()
        
    }
    
    func setUIelements() {
        indicator = NVActivityIndicatorView(frame: CGRect(x: self.view.center.x,
                                                          y: self.view.center.y,
                                                          width: self.view.bounds.width / 5, height: self.view.bounds.height / 7))
        indicator!.color = UIColor(red: 85/255, green: 146/255, blue: 193/255, alpha: 1.0)
        indicator!.type = .lineScaleParty
        indicator.isHidden = false
        indicator.center = self.view.center
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
    
    func requestUnsuccessful(){
        
        let alert = UIAlertController(title: "Request rejected", message: "Please contact the administrator", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func showAlertUILogin(){
        
        let alert = UIAlertController(title: "Timeout: no connection to the server", message: "Please check your internet connection", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close App", style: .default, handler: { (alertAction) in
            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        }))
        alert.addAction(UIAlertAction(title: "Try Again", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }

    
    @IBAction func cancel(_ sender: Any) {
        self.exContext?.completeRequest(returningItems: [], completionHandler: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func done(_ sender: Any) {
        self.authToken.downloadSuccess.listener = nil
        let item = authToken.giveJsonResponse()
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
    
    func showLoadUI(){
        let tmpFrame = self.view.frame
        let view = UIView(frame: tmpFrame)
        view.tag = 1
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        
        indicator.startAnimating()
        view.addSubview(indicator)
        self.view.addSubview(view)
    }
    
    func removeLoadUI(){
        indicator.stopAnimating()
        let view  = self.view.viewWithTag(1)
        view?.removeFromSuperview()
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
        
        return ServiceSectionController(entry: object as! Service, token: self.token!, protocolsModel: self.protocols!, authToken: self.authToken, aud: self.apString!, sessionKeys: self.sessionKey!)
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
}
