//
//  ExtensionLoginViewController.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 23.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import JWTswift
import TextFieldEffects
import NVActivityIndicatorView
import BEMCheckBox

/**
 An intial view controller of the extension app.
 This view controller is working with the EduidConfigModel, and TokenModel.
 
 ## Functions:
 - The configuration data will be fetched first from the server
 - After the config data is successfully fetched, user could interact with the UI to enter the login data
 - Manage the Login process, if the user hasn't logged in yet
 */
class ExtensionLoginViewController: UIViewController {

    /**
     * View Objects
     */
    @IBOutlet weak var imageView : UIImageView!
    private var indicator : NVActivityIndicatorView!
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var usernameLine: UIView!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var passwordLine: UIView!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var checkBox: BEMCheckBox!
    
    /**
    * Additional variables
    */
    private var reqConfigUrl : URL?
    private var userDev : String?
    private var passDev : String?
    
    private var tokenEnd: URL?
    private var signingKey : Key?
    private var sessionKey : [String : Key]?
    private var encKey : Key?
    
    private var configmodel : EduidConfigModel?
    var tokenModel : TokenModel?
    private let groupID = "group.htwchur.eduid.share"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUIelements()
            
        self.loadPlist()
        
        let keystore = KeyStore()
        
        //assume if there isn't any session key yet, config data is also unavailable
        if !checkSessionKey() {
            
            //create a pair & save if it's not exist yet
            sessionKey = KeyStore.generateKeyPair(keyType: .RSAkeys)!
            let x = KeyChain.saveKeyPair(tagString: "sessionKey", keyPair: sessionKey!)
            print("Save new key : \(x)")
        }
        
        self.checkConfig()
        
        
        var urlPathKey = Bundle.main.url(forResource: "ios_priv", withExtension: "jwks")
        let keyID = keystore.getPrivateKeyIDFromJWKSinBundle(resourcePath: (urlPathKey?.relativePath)!)
        urlPathKey = Bundle.main.url(forResource: "ios_priv", withExtension: "pem")
        guard let privateKeyID = keystore.getPrivateKeyFromPemInBundle(resourcePath: (urlPathKey?.relativePath)!, identifier: keyID!) else {
            print("ERROR getting private key")
            return
        }
        
        //key object always save the kid in base64url
        signingKey = keystore.getKey(withKid: privateKeyID)!
        
        //get Enc Key for JWE
        urlPathKey = Bundle.main.url(forResource: "eduid_pub", withExtension: "jwks")
        let keys = keystore.jwksToKeyFromBundle(jwksPath: urlPathKey!.path)
        
        if keys != nil && keys!.count > 0 {
            encKey = keys!.first
        }
        
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if loadAccount() != "" {
            usernameTF.text = loadAccount()
            checkBox.setOn(true, animated: true)
        }
    }
    

    @IBAction func login(_ sender: Any) {
        guard let userSub : String = usernameTF.text , let pass : String  = passwordTF.text else{
            return
        }
        
        showLoadUI()
        
        tokenModel?.downloadSuccess.bind (listener: { (dlBool) in
            DispatchQueue.main.async {
                self.checkDownload(downloaded: dlBool)
            }
        })
        // JWE 
        let userAssert = tokenModel?.createUserAssert(userSub: userSub, password: pass, issuer: userDev!, audience: (configmodel?.getIssuer())!, keyToSend: sessionKey!["public"]!, keyToSign: signingKey!, keyToEncrypt: encKey)
        
        do{
            try tokenModel?.fetchServer(username: userDev!, password: passDev!, assertionBody: userAssert!)
        } catch {
            print(error.localizedDescription)
            return
        }
        //simpler solutions instead of timer solution, using boxbinding
        
    }
    
// Load some data from the Setting plist
    func loadPlist(){
        if let path = Bundle.main.path(forResource: "Setting", ofType: "plist") {
            if let dic = NSDictionary(contentsOfFile: path) as? [String : Any] {
                self.userDev = dic["ClientID"] as? String
                self.passDev = dic["ClientPass"] as? String
                self.reqConfigUrl = URL(string: (dic["ConfigURL"] as? String)!)
            }
        }
    }
    
    func checkDownload(downloaded : Bool?) {
        
        print("checkDownload LoginExtension : \(String(describing: downloaded))")
        
        self.removeLoadUI()
        
        if downloaded == nil {
            showAlertUILogin()
        } else if !downloaded!{
            loginUnsuccessful()
        }else {
            loginSuccessful()
        }
        
    }
    
    // A listener function to check if the fetching process of the config data successful or not
    func checkDownloadConfig(downloaded : Bool?) {
        
        print("checkDownloadConfig LoginExtension : \(String(describing: downloaded))")
        DispatchQueue.main.async {
            if downloaded == nil {
                self.showAlertUI()
            } else if !downloaded!{
                //todo handle it differently for rejected request
                self.showAlertUI()
            }else {
                self.downloadFinished()
                //            self.tokenEnd = self.configmodel?.getTokenEndpoint()
            }
        }
        
        
    }
    
    func checkSessionKey() -> Bool {
        
        sessionKey = KeyChain.loadKeyPair(tagString: "sessionKey")
//        sessionKey!["public"] = KeyChain.loadKey(tagString: "sessionPublic")
//        sessionKey!["private"] = KeyChain.loadKey(tagString: "sessionPrivate")
        if sessionKey != nil  {
            print("Keys already existed")
            return true
        } else {
            return false
        }

    }
    
    func checkConfig(){
        
        configmodel = EduidConfigModel(serverUrl: self.reqConfigUrl! )
        configmodel?.deleteAll()
        showLoadUI()
        configmodel?.downloadedSuccess.bind {
            self.checkDownloadConfig(downloaded: $0)
        }
        
        if configmodel?.getTokenEndpoint() != nil {
            self.tokenEnd = configmodel?.getTokenEndpoint()
            return
        }
        
        configmodel?.fetchServer()
        
        /*
        var timeoutCounter = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timerTmp in
            timeoutCounter += 1
            print(timeoutCounter)
            if (self.configmodel?.downloadedSuccess.value)!  {
                timerTmp.invalidate()
                self.downloadFinished()
                self.tokenEnd = self.configmodel?.getTokenEndpoint()
            } else if timeoutCounter == 3 {
                self.showAlertUI()
                timerTmp.invalidate()
            }
        }
        timer.fire()
        */
    }
    
    func downloadFinished () {
        self.removeLoadUI()
        self.tokenEnd = self.configmodel?.getTokenEndpoint()
        tokenModel = TokenModel(tokenURI: self.tokenEnd!)
        
        if (tokenModel?.fetchDatabase())! {
            self.loginSuccessful()
            return
        }
    }
    
    func saveAccount(){
        if checkBox.on{
            let userDef = UserDefaults(suiteName: groupID)
            userDef?.set(usernameTF.text, forKey: "username")
            //UserDefaults.standard.set(usernameTF.text, forKey: "username")
        }
    }
    
    func loadAccount()-> String {
        let userDef = UserDefaults(suiteName: groupID)
        guard let res = userDef?.string(forKey: "username") else { //UserDefaults.standard.string(forKey: "username") else {
            return ""
        }
        return res
    }
    
    func clearAccount(){
        let userDef = UserDefaults(suiteName: groupID)
        userDef?.removeObject(forKey: "username")
        //UserDefaults.standard.removeObject(forKey: "username")
    }
    
    //    MARK: -- UI Functions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != "toProfileExtension"{
            return
        }
        
        let destinationVC = segue.destination as! ServiceViewController
        autoreleasepool{
            destinationVC.exContext = self.extensionContext
            destinationVC.apString = self.configmodel?.getIssuer()
        }
    }
    @IBAction func showHidePass(_ sender: Any) {
        showButton.isSelected = !showButton.isSelected
        if showButton.isSelected {
            passwordTF.isSecureTextEntry = false
        }else {
            passwordTF.isSecureTextEntry = true
        }
    }
    
    @IBAction func forgotPassword(_ sender: Any) {
        if let url = URL(string: "https://google.com") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func loginSuccessful(){
        self.tokenModel?.downloadSuccess.listener = nil
        saveAccount()
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toProfileExtension", sender: self)
        }
    }
    
    func loginUnsuccessful(){
        let rejectedTitle = NSLocalizedString("LoginRejectedTitle", comment: "Login rejected")
        let rejectedMsg = NSLocalizedString("LoginRejectedMessage", comment: "Login rejected message")
        let tryagainTxt = NSLocalizedString("TryAgain", comment: "try again text")
        
        let alert = UIAlertController(title: rejectedTitle, message: rejectedMsg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryagainTxt, style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlertUI(){
        let alertmessage = NSLocalizedString("TimeoutMessage", comment: "Message appears on the connection timeout")
        let tryagainText = NSLocalizedString("TryAgain", comment: "Try again text")
        let closeText = NSLocalizedString("Close", comment: "Close text")
        
        let alert = UIAlertController(title: "Timeout", message: alertmessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryagainText, style: .cancel, handler: {
            (alertAction) in
            self.checkConfig()
        }))
        alert.addAction(UIAlertAction(title: closeText, style: .default, handler: { (alertAction) in
            //UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }))
        
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showAlertUILogin(){
        let alertmessage = NSLocalizedString("TimeoutMessage", comment: "Message appears on the connection timeout")
        let tryagainText = NSLocalizedString("TryAgain", comment: "Try again text")
        let closeText = NSLocalizedString("Close", comment: "Close text")
        
        let alert = UIAlertController(title: "Timeout", message: alertmessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryagainText, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: closeText, style: .default, handler: { (alertAction) in
            //UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }))
        
        
        self.present(alert, animated: true, completion: nil)
        
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
    
    @IBAction func gestureDidSwipeDown(_ sender: UISwipeGestureRecognizer) {
        
        if self.usernameTF.isFirstResponder || self.passwordTF.isFirstResponder {
            self.view.endEditing(true)
        }
        
    }
    
    func setUIelements(){
        
        //        backgroundView.loadGif(name: "testGif")
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        usernameTF.delegate = self
        usernameTF.keyboardType = .emailAddress
        passwordTF.delegate = self
        passwordTF.text = ""
        showButton.setImage(UIImage(named: "eyeShowE"), for: .selected)
        
        indicator = NVActivityIndicatorView(frame: CGRect(x: self.view.center.x,
                                                          y: self.view.center.y,
                                                          width: self.view.bounds.width / 5, height: self.view.bounds.height / 7))
        indicator!.color = UIColor(red: 85/255, green: 146/255, blue: 193/255, alpha: 1.0)
        indicator!.type = .lineScaleParty
        indicator.isHidden = false
        indicator.center = self.view.center
        
        checkBox.boxType = BEMBoxType.square
        checkBox.onTintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        checkBox.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        checkBox.delegate = self
    }
    
    @objc func keyboardWillShow(){
        self.view.frame.origin.y = -150 //move upward 150
    }
    
    @objc func keyboardWillHide(){
        self.view.frame.origin.y = 0
    }
}

extension ExtensionLoginViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.autocorrectionType = .no
        
        if textField == self.passwordTF {
            textField.isSecureTextEntry = true
            if textField.text == NSLocalizedString("Password", comment: "") {
                textField.text = ""
            }
        } else {
            
            if textField.text == "example@uni-test.com"{//NSLocalizedString("Username", comment: "") {
                textField.text = ""
            }
        }
    }
    
}

extension ExtensionLoginViewController : BEMCheckBoxDelegate {
    func didTap(_ checkBox: BEMCheckBox) {
        if !checkBox.on {
            clearAccount()
        }
    }
}
