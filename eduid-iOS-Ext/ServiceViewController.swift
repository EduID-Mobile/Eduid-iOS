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
/**
 This View Controller would appear if the user has logged in on the successfully, and show the available services for the user & the third party app.
 Authorization process would be happen here after the user chosen one of the service, if successfull the app would receive an access token for the third party app.
 This class uses ProtocolsModel and AuthorizationTokenModel for its main functionality
 
 ## Functions:
 - Show the availables services for the specified third party app (ProtocolsModel)
 - Control the Authorization process (AuthorizationTokenModel)
 - Returning the extension into the third party app.
 */

class ServiceViewController: UIViewController {
    
    @IBOutlet weak var midLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var serviceButton: UIButton!
    @IBOutlet weak var institutionButton: UIButton!
    //private var filterButton = DropDownButton()
    
    private var indicator : NVActivityIndicatorView!
    
    lazy var adapter : ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()
    
    var token : TokenModel?
    var protocols : ProtocolsModel?
    var singleton : Bool?
    var authToken = AuthorizationTokenModel()
    var fetchedSuccess : Bool = false
    var exContext : NSExtensionContext?
    var apString: String?
    var selectedServices : [String]?
    var response : [String: Any]?
    
    private var filterString = ""
    
    
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
    
        serviceButton.tag = 0
        institutionButton.tag = 1
        //        filterButton = DropDownButton(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        //        self.view.addSubview(filterButton)
        self.setUIelements()
        
    }
    //   MARK: -- BUTTON ACTIONS
    
    @IBAction func filter(_ sender: UIButton) {
        print("Filter function : " , sender.titleLabel?.text ?? "nil" , ", \(sender.tag)")
        if !sender.isSelected{
            sender.isSelected = true
        } else {
            sender.isSelected = false
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.exContext?.completeRequest(returningItems: [], completionHandler: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func done(_ sender: Any) {
        self.authToken.downloadSuccess.listener = nil
        if singleton! {
            let item = authToken.giveJsonResponse()
            let returnProvider = NSItemProvider(item: item! as NSSecureCoding, typeIdentifier: kUTTypeJSON as String)
            let returnItem = NSExtensionItem()
  
            returnItem.attachments = [returnProvider]
            self.exContext?.completeRequest(returningItems: [returnItem], completionHandler: nil)
            self.navigationController?.popToRootViewController(animated: true)
        } else{
            do{
                let json = try JSONSerialization.data(withJSONObject: self.response!, options: [])
                let returnProvider = NSItemProvider(item: json as NSSecureCoding, typeIdentifier: kUTTypeJSON as String)
                let returnItem = NSExtensionItem()
                returnItem.attachments = [returnProvider]
                self.exContext?.completeRequest(returningItems: [returnItem], completionHandler: nil)
                self.navigationController?.popToRootViewController(animated: true)
            }catch {
                print("ERROR: problem on creating json data")
                return
            }
        }
    }
    
    // MARK: -- UI Functions
    
    func setUIelements() {
        
        
        indicator = NVActivityIndicatorView(frame: CGRect(x: self.view.center.x,
                                                          y: self.view.center.y,
                                                          width: self.view.bounds.width / 5, height: self.view.bounds.height / 7))
        indicator!.color = UIColor(red: 85/255, green: 146/255, blue: 193/255, alpha: 1.0)
        indicator!.type = .lineScaleParty
        indicator.isHidden = false
        indicator.center = self.view.center
        
        /*
         filterButton.translatesAutoresizingMaskIntoConstraints = false
         filterButton.dropView.dropdownOptions = ["My Federation", "My Institution", "Last Services"]
         filterButton.setImage(UIImage(named: "filter"), for: UIControlState.normal)
         filterButton.setImage(UIImage(named: "filterActive"), for: [UIControlState.selected , UIControlState.highlighted])
         
         filterButton.trailingAnchor.constraint(equalTo: self.midLabel.trailingAnchor, constant: -10).isActive = true
         filterButton.centerYAnchor.constraint(equalTo: self.midLabel.centerYAnchor).isActive = true
         filterButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
         filterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
         self.view.bringSubview(toFront: filterButton)
         */
        
    }
    
    func showAlertUILogin(){
        
        let alert = UIAlertController(title: "Timeout: no connection to the server", message: "Please check your internet connection", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close App", style: .default, handler: { (alertAction) in
            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        }))
        alert.addAction(UIAlertAction(title: "Try Again", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showLoadUI(){
        let tmpFrame = self.view.frame
        let view = UIView(frame: tmpFrame)
        view.tag = 7777
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        
        indicator.startAnimating()
        view.addSubview(indicator)
        self.view.addSubview(view)
    }
    
    func removeLoadUI(){
        indicator.stopAnimating()
        let view  = self.view.viewWithTag(7777)
        view?.removeFromSuperview()
    }
    
    //    MARK : -- Additional Functions
    /**
     Check if the fetching data of available services is successfull or not.
     */
    func checkDownload(downloaded : Bool?){
        print("checkDownload in ServiceViewController : \(String(describing: downloaded))")
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
    
    /**
     Check the availability of the session key in the keychain, without session key, app coudln't sign and send the data to the resource provider.
     - returns : Boolean, 'True' if session key are existed, otherwise 'False'
     */
    func checkSessionKey() -> Bool {
        
        sessionKey = KeyChain.loadKeyPair(tagString: "sessionKey")
        
        if sessionKey != nil {
            print("Keys already existed")
            return true
        } else {
            return false
        }
    }
    
    func loadProtocolURLFromPlist() -> String? {
        if let path = Bundle.main.path(forResource: "Setting", ofType: "plist") {
            if let dic = NSDictionary(contentsOfFile: path) as? [String : Any] {
                return dic["RSDprotocol"] as? String
            }
        }
        return nil
    }
    
    func requestUnsuccessful(){
        
        let alert = UIAlertController(title: "Request rejected", message: "Please contact the administrator", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showProtocols() {
        let addresss = URL.init(string: loadProtocolURLFromPlist()! )
        
        self.protocols = self.singleton != nil ? ProtocolsModel(singleton: singleton!) : ProtocolsModel()
        doneButton.isHidden = singleton ?? true
        
        protocols!.downloadSuccess.bind {
            self.checkDownload(downloaded: $0 )
        }
        
        protocols?.fetchProtocols(address: addresss!, protocolList: authprotocols!)
    }
    
    ///Extracting the protocols and singleton info from the extension package
    func showToken() {
        
        self.token = TokenModel()
        self.authprotocols = [String]()
        if !(token?.fetchDatabase())! {
            return
        }
        
        let textItem = self.exContext?.inputItems.first as! NSExtensionItem
        
        let group = DispatchGroup()
        
        for i in 0..<textItem.attachments!.count {
            group.enter()
            let itemProvider = textItem.attachments?[i]
            let textItemProvider = itemProvider as! NSItemProvider
            if  textItemProvider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                
                textItemProvider.loadItem(forTypeIdentifier: String(kUTTypeText), options: nil, completionHandler: { (result, error) in
                    let text = result as! String
                    print(text)
                    if(i != textItem.attachments!.count - 1){
                        self.authprotocols?.append(text)
                    }else{
                        if let b = text.toBool() {
                            self.singleton = b
                        }else { self.singleton = true }
                        self.selectedServices = self.singleton! ? nil : [String]()
                        self.response = self.singleton! ? nil : [String:Any]()
                    }
                    group.leave()
                })
            }
            
            self.fetchedSuccess = true
            
            group.notify(queue: .main) {
                self.showProtocols()
            }
        }
    }
    
    
    
}

// MARK: Extension to handle IGListKit adapter and search delegate

extension ServiceViewController : ListAdapterDataSource, SearchSectionControllerDelegate {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        if self.services == nil {
            return []
        }else {
            //            self.services?.serviceName.append("Search Bar")
            if filterString == "" {
                return ["Search Bar" , self.services!] as! [ListDiffable]
            }else{
                let filtered = self.services?.serviceName.filter{$0.lowercased().contains(filterString.lowercased()) }
                    .map{$0 as ListDiffable }
                let filteredServices = Service.init(filtered! as! [String])
                print("FILTERED  = " , filteredServices)
                return ["Search Bar" , filteredServices] as! [ListDiffable]
            }
        }
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        
        print(object)
        if let str = object as? String, str == "Search Bar"{
            let sectionCon = SearchSectionController()
            sectionCon.delegate = self
            return sectionCon
        }else {
            guard let serviceTmp : Service = (object as? Service) else {
                fatalError()
            }
            if !singleton! {
                return ServiceSectionController(entry: serviceTmp, token: self.token!, protocolsModel: self.protocols!, authToken: self.authToken, aud: self.apString!, sessionKeys: self.sessionKey!)
            }else {
                
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
                return ServiceSectionSingletonController(entry: serviceTmp, token: self.token!, protocolsModel: self.protocols!, authToken: self.authToken, aud: self.apString!, sessionKeys: self.sessionKey!)
            }
        }
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
        
    }
    
    // MARK: SearchSection Delegate
    func searchSectionController(_ sectionController: SearchSectionController, didChangeText text: String) {
        filterString = text
        adapter.performUpdates(animated: true, completion: nil)
    }
    
}
