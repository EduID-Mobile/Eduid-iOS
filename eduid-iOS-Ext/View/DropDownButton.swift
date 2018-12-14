//
//  DropDownButton.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 19.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import Foundation
import UIKit

//Currently not used

protocol DropDownProtocol{
    func dropDownPressed(string: String)
}

class DropDownButton : UIButton, DropDownProtocol {
    
    var dropView = DropDownView()
    var height = NSLayoutConstraint()
    var isOpen = false
    
    init(){
        super.init(frame: CGRect.zero)
        dropView = DropDownView(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        dropView.delegate = self
        dropView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        dropView = DropDownView(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        dropView.delegate = self
        dropView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        self.superview?.addSubview(dropView)
        self.superview?.bringSubview(toFront: dropView)
        
        dropView.topAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
//        dropView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        dropView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        dropView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 3).isActive = true
        
        height = dropView.heightAnchor.constraint(equalToConstant: 0)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isOpen {
            isOpen = true
            
            NSLayoutConstraint.deactivate([self.height])
            if self.dropView.tableView.contentSize.height > 150 {
                self.height.constant = 150
            }else {
                self.height.constant = self.dropView.tableView.contentSize.height
            }
            
            NSLayoutConstraint.activate([self.height])
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.dropView.layoutIfNeeded()
                self.dropView.center.y += self.dropView.frame.height / 2
                }, completion: nil)
        }else {
            dismissDropDown()
        }
    }
    
    func dismissDropDown(){
        isOpen = false
        
        NSLayoutConstraint.deactivate([self.height])
        self.height.constant = 0
        NSLayoutConstraint.activate([self.height])
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            //apply the constraints
            self.dropView.center.y -= self.dropView.frame.height / 2
            self.dropView.layoutIfNeeded()
        }, completion: nil)
    }
    
    func dropDownPressed(string: String) {
        print("OPTION PRESSED : \(string)")
        self.dismissDropDown()
    }
    
}

class DropDownView : UIView, UITableViewDelegate, UITableViewDataSource {
    
    var dropdownOptions = [String]()
    var tableView = UITableView()
    var delegate : DropDownProtocol!
    
    override init(frame: CGRect){
        super.init(frame: frame)
        
        self.tableView.backgroundColor = UIColor.lightGray
        self.backgroundColor = UIColor.lightGray
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(tableView)
        
        tableView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        tableView.separatorStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dropdownOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.text = dropdownOptions[indexPath.row]
        cell.backgroundColor = UIColor.lightGray
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.delegate.dropDownPressed(string: dropdownOptions[indexPath.row])
        self.tableView.deselectRow(at: indexPath, animated: true)
        
    }
}
