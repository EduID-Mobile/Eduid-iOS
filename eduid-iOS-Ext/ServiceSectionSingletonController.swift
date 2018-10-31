//
//  ServiceSectionController.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 02.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import IGListKit
import JWTswift
import BEMCheckBox

class ServiceSectionSingletonController: ListSectionController {
    
    private weak var entry : Service!
    private weak var token : TokenModel!
    private weak var protocolsModel : ProtocolsModel!
    private weak var authToken : AuthorizationTokenModel!
    private var audience : String!
    private var sessionKeys : [String: Key]!
    private var encryptKey : Key?
    private var selectedIndex : Int = -1
    private var cells : [UICollectionViewCell] = []
    
    init(entry : Service, token: TokenModel, protocolsModel : ProtocolsModel, authToken : AuthorizationTokenModel, aud : String, sessionKeys : [String: Key], encKey : Key?){
        super.init()
        self.entry = entry
        self.token = token
        self.audience = aud
        self.sessionKeys = sessionKeys
        self.protocolsModel = protocolsModel
        self.authToken = authToken
        self.encryptKey = encKey
    }
    
    override func numberOfItems() -> Int {
        if entry == nil {
            return 0
        } else {
            return entry.serviceName.count
        }
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        //TODO: MAKE HEIGHT RELATIVE
        
        return index != selectedIndex ? CGSize(width: collectionContext!.containerSize.width - 20 , height: 50) : CGSize(width: collectionContext!.containerSize.width - 20 , height: 150)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let cell : UICollectionViewCell
        
        guard let vc = self.viewController as? ServiceViewController else{
            print("error getting view controller on request method")
            return UICollectionViewCell()
        }
        
        if selectedIndex != index {
            guard let celltmp = collectionContext?.dequeueReusableCell(withNibName: "ServiceSingletonCell", bundle: nil, for: self, at: index) as? ServiceSingleTonCell else{
                fatalError()
            }
            celltmp.switchButton.tag = index
            celltmp.switchButton.delegate = self
            celltmp.serviceLabel.text = entry.serviceName[index]
            celltmp.switchButton.on = false
            cell = celltmp
        } else {
            guard let celltmp = collectionContext?.dequeueReusableCell(withNibName: "ConsentCell", bundle: nil, for: self, at: index) as? ConsentCell else {
                fatalError()
            }
            celltmp.consentLabel.text = NSLocalizedString("ConsentMessage", comment: "Show user the consent text")
            celltmp.switchButton.tag = index
            celltmp.switchButton.delegate = self
            celltmp.serviceLabel.text = entry.serviceName[index]
            celltmp.switchButton.on = true //(vc.selectedServices?.contains(entry.serviceName[index]))! ? true : false
            
            cell = celltmp
        }
        
        
        
        let border = CALayer()
        border.backgroundColor = UIColor.gray.cgColor
        border.frame = CGRect(x: 0, y: cell.frame.size.height - 1.0, width: cell.frame.size.width, height: 1.0)
        cell.layer.addSublayer(border)
        cells.append(cell)
        return cell
    }
    
    override func didSelectItem(at index: Int) {
        print("did select item : \(index)")
        
        guard let cell = cells[index] as? ServiceSingleTonCell else {
            return
        }
        DispatchQueue.main.async {
            cell.switchButton.setOn(!cell.switchButton.on, animated: true)
            self.didTap(cell.switchButton)
        }
        
    }
    
    func authRequest(adress : URL , homepageLink : String){
        
        
        print(self.token?.giveAccessToken()! as Any)
        let idToken = self.token?.giveTokenID()?.last
        print(self.token?.giveTokenID()?.first! as Any)
        print(self.token?.giveTokenID()?.last! as Any)
        let assert = authToken.createAssert(addressToSend: adress.absoluteString, subject: idToken!["sub"] as! String, audience: self.audience , accessToken: (token?.giveAccessToken()!)!, kidToSend: (self.sessionKeys!["public"]?.getKid())! , keyToSign: self.sessionKeys!["private"]!, keyToEncrypt: encryptKey)
        print("ASSERT : \(assert!)")
        
        authToken.fetch(address: adress, assertionBody: assert!)
    }
    
    func getSelectedIndex() -> Int?{
        return selectedIndex
    }
    /*
     func generateConsentCell() -> UICollectionViewCell {
     
     let cell = UICollectionViewCell(frame: CGRect.init(x: 0, y: 0, width: (collectionContext?.containerSize.width)!, height: (collectionContext?.containerSize.height)!))
     let consentLabel : UILabel = UILabel.init(frame: cell.frame)
     cell.addSubview(consentLabel)
     consentLabel.text = NSLocalizedString("ConsentMessage", comment: "Show user the consent text")
     return cell
     }*/
}

extension ServiceSectionSingletonController : BEMCheckBoxDelegate {
    
    func didTap(_ checkBox: BEMCheckBox) {
        guard let vc = self.viewController as? ServiceViewController else{
            print("error getting view controller on request method")
            return
        }
        
        print("CheckBox is \(checkBox.on)")
        // Remove all the selected services since it is singleton mode.
        //vc.selectedServices!.removeAll()
        let cellCount = self.entry.serviceName.count
        
        /*
         for i in 0..<cellCount {
         //guard let cell = self.cellForItem(at: i) as? ServiceSingleTonCell else {continue}
         guard let cell = cells[i] as? ServiceSingleTonCell else {
         continue
         }
         
         // Turning off the other checkbox: since it is a singleton mode.
         if cell.switchButton.tag != checkBox.tag && cell.switchButton.on {
         DispatchQueue.main.async{
         //cell.switchButton.setOn(false, animated: true)
         cell.switchButton.on = false
         //self.selectedIndex = -1
         }
         }else if cell.switchButton.tag == checkBox.tag {
         //cell.switchButton.setOn(!cell.switchButton.on, animated: true)
         print("Check box = \(checkBox.on )")
         if checkBox.on {
         // Remove all the selected services since it is singleton mode.
         vc.selectedServices!.removeAll()
         vc.selectedServices?.append(entry.serviceName[i])
         print("SELECTED SERVICES = " , vc.selectedServices ?? "")
         selectedIndex = i
         print("Selected index : \(String(describing: selectedIndex))")
         break
         } else {
         selectedIndex = -1
         }
         }
         }*/
        
        for i in 0..<cellCount {
            // Clean all the cell
            if i == checkBox.tag {
                continue
            }
            guard let cell = cells[i] as? ServiceSingleTonCell else {
                print("Cell at index \(i) is not ServiceSingletonCell.")
                continue
            }
            cell.switchButton.setOn(false, animated: true)
        }
        
        selectedIndex = -1
        let indexCell = checkBox.tag
        print("Button tap :: \(indexCell)")
        
        vc.selectedServices?.removeAll()
        
        if checkBox.on {
            vc.selectedServices?.append(entry.serviceName[indexCell])
            selectedIndex = indexCell
            print("SELECTED SERVICES = " , vc.selectedServices ?? "")
            print("Selected index : \(String(describing: selectedIndex))")
        } else {
            guard let cell = cells[indexCell] as? ServiceSingleTonCell else {
                print("Cell at index \(indexCell) is not ServiceSingletonCell.")
                return
            }
            cell.switchButton.setOn(false, animated: true)
            print("turn off the cell")
        }
        DispatchQueue.main.async{
            self.collectionContext?.performBatch(animated: true, updates: { (batchContext) in
                batchContext.reload(self)
            })
        }
    }
    
}
