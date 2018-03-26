//
//  LogoutViewController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 17.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import JWTswift
/**
 A simple view controller to ask the user's confirmation before the user log out
 */
class LogoutViewController: UIViewController {

    @IBOutlet weak var confirmLogOutButton: UIButton!
    var tokenModel : TokenModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.confirmLogOutButton.backgroundColor = UIColor.black
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Back to the ProfileListViewController if the cancel button is tapped
    @IBAction func cancelLogout(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // This function will make the remove all the view controller inside the navigation controller stack except the root view controller ( LoginViewController )
    // Delete the personal credential data & information from the device at the end.
    @IBAction func confirmLogout(_ sender: Any) {
        
        self.tokenModel?.deleteAll()
        let root = self.navigationController?.viewControllers.first as! LoginViewController
        root.tokenModel?.deleteAll()
        guard let keypair =  KeyChain.loadKeyPair(tagString: "sessionKey") else{
            print("Key pair is not found")
            return
        }
        
        if KeyChain.deleteKeyPair(tagString: "sessionKey", keyPair: keypair) {
            self.navigationController?.popToRootViewController(animated: true)
        }
        
    }
    
    func showAlertUI(){
        
        let alert = UIAlertController(title: "Error", message: "Error occured on the logout process, please contact the support", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close App", style: .default, handler: { (alertAction) in
            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        }))
        alert.addAction(UIAlertAction(title: "Try Again", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
}
