//
//  LogoutViewController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 17.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit

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
    

    @IBAction func cancelLogout(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func confirmLogout(_ sender: Any) {
        self.tokenModel?.deleteAll()
        let root = self.navigationController?.viewControllers.first as! LoginViewController
        root.tokenModel?.deleteAll()
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}
