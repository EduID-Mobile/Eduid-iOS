//
//  ServiceSectionController.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 19.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import IGListKit
import JWTswift
import BEMCheckBox

class ServiceSectionController : ListSectionController {
    
    private weak var entry : Service!
    private weak var token : TokenModel!
    private weak var protocolsModel : ProtocolsModel!
    private weak var authToken : AuthorizationTokenModel!
    private var audience : String!
    private var sessionKeys : [String: Key]!
    private lazy var cells = [ServiceCell]()
    
    init(entry: Service, token: TokenModel, protocolsModel : ProtocolsModel, authToken: AuthorizationTokenModel, aud : String, sessionKeys: [String: Key]){
        super.init()
        self.entry = entry
        self.token = token
        self.audience = aud
        self.sessionKeys = sessionKeys
        self.protocolsModel = protocolsModel
        self.authToken = authToken
    }
    
    override func numberOfItems() -> Int {
        if entry == nil {
            return 0
        }
        return entry.serviceName.count
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width - 20 , height: collectionContext!.containerSize.height / 9)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let cell = collectionContext?.dequeueReusableCell(withNibName: "ServiceCell", bundle: nil, for: self, at: index) as? ServiceCell else{
            fatalError()
        }
        let vc = self.viewController as! ServiceViewController
        cell.serviceLabel.text = entry.serviceName[index]
        cell.switchButton.on = false
        let border = CALayer()
        border.backgroundColor = UIColor.gray.cgColor
        border.frame = CGRect(x: 0, y: cell.frame.size.height - 1.0, width: cell.frame.size.width, height: 1.0)
        cell.layer.addSublayer(border)
        cell.switchButton.tag = index
        
        if  (vc.selectedServices?.contains(cell.serviceLabel.text!))! {
            cell.switchButton.on = true
        }
        //even handler if switch changed
        cell.switchButton.addTarget(self, action: #selector(self.switchChanged), for: .valueChanged)
        
        self.cells.append(cell)
        
        return cell
        
    }
    
    override func didSelectItem(at index: Int) {
//        let vc = self.viewController as! ServiceViewController
        let add = self.entry.serviceName[index]
        
        print("SELECTED : index \(index), \(add)")
        let cell = cells[index]
        cell.switchButton.setOn(!cell.switchButton.on, animated: true)
        self.switchChanged(sender: cell.switchButton)
        
//        vc.showLoadUI()
        
        /*
        print("did select item : \(index)")
        guard let adress = self.protocolsModel.getApisLink(serviceName: self.entry.serviceName[index]), let homeLink = self.protocolsModel.getHomepageLink(serviceName: self.entry.serviceName[index]) else {
            print("no apis found")
            return
        }
        
        authRequest(adress: adress, homepageLink: homeLink)
         */
    }
    
    @objc func switchChanged(sender: Any){
        let vc = self.viewController as! ServiceViewController
        let switchBtn = sender as! BEMCheckBox
        let cell = cells[switchBtn.tag]
        
        self.authToken.downloadSuccess.listener = nil
        self.authToken.downloadSuccess.value = nil
        if switchBtn.on == false {
            //DELETE THE SELECTED SERVICES AND RESPONDS
            if (vc.selectedServices?.contains(cell.serviceLabel.text!))! {
                let index = vc.selectedServices?.index(of: cell.serviceLabel.text!)
                vc.selectedServices?.remove(at: index!)
//                vc.response?.removeValue(forKey: cell.serviceLabel.text!)
                print("off  : selectedServices : \(vc.selectedServices!.count) , response : \(vc.response!.count)")
            }
            return
        }
        vc.selectedServices?.append(cell.serviceLabel.text!)
        guard let adress = self.protocolsModel.getApisLink(serviceName: cell.serviceLabel.text!) ,
            let homeLink = self.protocolsModel.getHomepageLink(serviceName: cell.serviceLabel.text!) else {
                print("No apis found")
                return
        }
        print("SWITCH CHANGED : \(switchBtn.on), address : \(adress.absoluteString) , home: \(homeLink), selected Services : \(String(describing: vc.selectedServices?.count))")
        
        /*
        self.authToken.downloadSuccess.bind { (dlbool) in
            DispatchQueue.main.async{
                vc.removeLoadUI()
                self.authToken.downloadSuccess.listener = nil

                if dlbool == nil {
                    print("LISTENER NIL")
                    switchBtn.setOn(false, animated: true)
                    vc.showAlertUILogin()
                }
                else if dlbool == false {
                    print("LISTENER FALSE")
                    switchBtn.setOn(false, animated: true)
                    vc.requestUnsuccessful()
                } else {
                    print("REQUEST SUCCESS")
                    self.authToken.downloadSuccess.listener = nil
                    vc.selectedServices?.append(cell.serviceLabel.text!)
                    vc.response![cell.serviceLabel.text!] = self.authToken.giveResponseAsDict()
                    print("CURRENT response: " , vc.response!)
                    
                    print("on  : selectedServices : \(vc.selectedServices!.count) , response : \(vc.response!.count)")
                }
            }
        }*/
//        authRequest(adress: adress, homepageLink: homeLink)
    }
    
    
    
    func authRequest(adress : URL , homepageLink : String){
        
        
//        print(self.token?.giveAccessToken()! as Any)
        let idToken = self.token?.giveTokenID()?.last
//        print(self.token?.giveTokenID()?.first! as Any)
//        print(self.token?.giveTokenID()?.last! as Any)
        let assert = authToken.createAssert(addressToSend: adress.absoluteString, subject: idToken!["sub"] as! String, audience: self.audience , accessToken: (token?.giveAccessToken()!)!, kidToSend: (self.sessionKeys!["public"]?.getKid())! , keyToSign: self.sessionKeys!["private"]!)
//        print("ASSERT : \(assert!)")
        
//        guard let vc = self.viewController as? ServiceViewController else{
//            print("error getting view controller on request method")
//            return
//        }
//        vc.showLoadUI()
        authToken.fetch(address: adress, assertionBody: assert!)
    }
    
    
    
}
