//
//  ProfileViewController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 11.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import JWTswift

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    var textLabel : String?
    var token : TokenModel?
    var id_Token : [String : Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if token == nil {
            print("TOKEN IS NIL")
            return
        }
        
        id_Token = (token?.giveIdTokenJWS())!
        
        
        profileLabel.text = "Hello " + String(describing: id_Token!["given_name"]!) + " " + String(describing: id_Token!["family_name"]!)
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        logoutButton.backgroundColor = .black
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func giveData(row : Int) -> [String] {
        var result = [String]()
        let keys = Array(id_Token!.keys)
        if(row < keys.count){
            result.append(keys[row])
            result.append( String(describing: id_Token![keys[row]]!) )
        }
        return result
    }
    
    @IBAction func logout(_ sender: Any) {
        
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.id_Token?.count)!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("TAPPED row : \(indexPath.row)")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ExpandTableViewCell
        let dataForRow = giveData(row: indexPath.row)
        cell.titleLabel.text = dataForRow.first
        cell.detailLabel.text = dataForRow.last
        
        return cell
    }
    
}
