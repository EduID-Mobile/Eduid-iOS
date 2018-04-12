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
    @IBOutlet weak var cancelButton: RoundCornerButton!
    @IBOutlet weak var cancelButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var cancelButtonDoubleWidth: NSLayoutConstraint!
    @IBOutlet weak var institutionButton: UIButton!
    
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
        
        //        filterButton = DropDownButton(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        //        self.view.addSubview(filterButton)
        self.setUIelements()
        //        self.showLoadUI()
        //        self.removeLoadUI()
    }
    //   MARK: -- BUTTON ACTIONS
    
    @IBAction func cancel(_ sender: Any) {
        self.exContext?.completeRequest(returningItems: [], completionHandler: nil)
        //        self.navigationController?.popToRootViewController(animated: true)
        //        showLoadUI()
    }
    
    @IBAction func done(_ sender: Any) {
        showLoadUI()
        if singleton! {
            self.authToken.downloadSuccess.listener = nil
            let item = authToken.giveResponseAsDict()
            var singleDict = [String : Any]()
            singleDict[(selectedServices!.first)!] = item
            let completedRSD = protocols?.applyAuthorization(authorization: singleDict)
            
            let returnProvider = NSItemProvider(item: completedRSD! as NSSecureCoding, typeIdentifier: kUTTypeJSON as String)
            let returnItem = NSExtensionItem()
            
            returnItem.attachments = [returnProvider]
            self.exContext?.completeRequest(returningItems: [returnItem], completionHandler: nil)
            self.navigationController?.popToRootViewController(animated: true)
        } else{
            //            put the getAllRequest in background thread so the main thread can update the loadUI
            self.performSelector(inBackground: #selector(getAllRequests), with: nil)
        }
    }
    
    func sendExtensionPacket(){
        DispatchQueue.main.async {
            self.removeLoadUI()
            self.navigationController?.popToRootViewController(animated: true)
        }
        if self.response?.count == 0 {
            self.exContext?.completeRequest(returningItems: nil, completionHandler: nil)
            //            self.navigationController?.popToRootViewController(animated: true)
        }else{
            
            let completedRSD = protocols?.applyAuthorization(authorization: response!)
            
            let returnProvider = NSItemProvider(item: completedRSD! as NSSecureCoding, typeIdentifier: kUTTypeJSON as String)
            let returnItem = NSExtensionItem()
            returnItem.attachments = [returnProvider]
            self.exContext?.completeRequest(returningItems: [returnItem], completionHandler: nil)
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
        let alertmessage = NSLocalizedString("TimeoutMessage", comment: "Message appears on the connection timeout")
        let tryagainText = NSLocalizedString("TryAgain", comment: "Try again text")
        let closeText = NSLocalizedString("Close", comment: "Close text")
        
        let alert = UIAlertController(title: "Timeout", message: alertmessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryagainText, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: closeText, style: .default, handler: { (alertAction) in
//            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
            self.exContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }))
       
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    //    FIX: NOT SHOWN in 1:N schema (Assumption: Threading)
    func showLoadUI(){
        let tmpFrame = self.view.frame
        let loadview = UIView(frame: tmpFrame)
        loadview.tag = 9999
        loadview.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        
        indicator.startAnimating()
        indicator.center = CGPoint(x: loadview.center.x, y: loadview.center.y)
        loadview.addSubview(indicator)
        self.view.addSubview(loadview)
        
    }
    
    func removeLoadUI(){
        indicator.stopAnimating()
        let loadview  = self.view.viewWithTag(9999)
        loadview?.removeFromSuperview()
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
        let alertTitle = NSLocalizedString("RequestAlertTitle", comment: "Title for the alert view when request is rejected")
        let alertMessage = NSLocalizedString("RequestAlertMessage", comment: "Message for the alert view when request is rejected")
        let tryagainTxt = NSLocalizedString("TryAgain", comment: "Try again text")
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryagainTxt, style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showProtocols() {
        let addresss = URL.init(string: loadProtocolURLFromPlist()! )
        
        self.protocols = self.singleton != nil ? ProtocolsModel(singleton: singleton!) : ProtocolsModel()
        doneButton.isHidden = singleton ?? true
        
        if doneButton.isHidden{
            doneButton.removeFromSuperview()
            cancelButtonWidth.isActive = false
            cancelButtonDoubleWidth.isActive = true
        }
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
        group.enter()
        for i in 0..<textItem.attachments!.count {
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
                        self.selectedServices = [String]()
                        self.response = self.singleton! ? nil : [String:Any]()
                        group.leave()
                    }
                })
            }
            
            self.fetchedSuccess = true
        }
        group.notify(queue: .main) {
            self.showProtocols()
        }
    }
    
    @objc func getAllRequests(){
        //Section 0 = Search Bar, Section 1 = Filter Section
        guard let secCon = self.adapter.sectionController(forSection: 2) as? ServiceSectionController else {
            return
        }
        
        let group = DispatchGroup()
        
        for service in selectedServices! {
            print("SERVICE: \(service), from selectedServices")
            group.enter()
            guard let adress = self.protocols?.getApisLink(serviceName: service),
                let homelink = self.protocols?.getHomepageLink(serviceName: service) else {
                    print("No APIs Link Found")
                    return
            }
            authToken.downloadSuccess.bind{ (dlbool) in
                if dlbool == nil || dlbool == false {
                    print("Error request for the following service : \(service)")
                }else{
                    self.authToken.downloadSuccess.listener = nil
                    self.response![service] = self.authToken.giveResponseAsDict()
                }
                group.leave()
            }
            
            secCon.authRequest(adress: adress, homepageLink: homelink)
            group.wait()
        }
        sendExtensionPacket()
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
                return ["Search Bar", "Sort Cell" , self.services!] as! [ListDiffable]
            }else{
                let filtered = self.services?.serviceName.filter{$0.lowercased().contains(filterString.lowercased()) }
                    .map{$0 as ListDiffable }
                let filteredServices = Service.init(filtered! as! [String])
                print("FILTERED  = " , filteredServices)
                return ["Search Bar", "Sort Cell" , filteredServices] as! [ListDiffable]
            }
        }
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        
        print(object)
        if let str = object as? String, str == "Search Bar"{
            let sectionCon = SearchSectionController()
            sectionCon.delegate = self
            return sectionCon
        }else if let str = object as? String, str == "Sort Cell" {
            return SortSectionController()
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
