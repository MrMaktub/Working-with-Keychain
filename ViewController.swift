//
//  ViewController.swift
//  Project28SecretSwift
//
//  Created by Bryce Hawkins on 1/10/23.
//

import LocalAuthentication
import UIKit

class ViewController: UIViewController {

    @IBOutlet var secret: UITextView!
    @IBOutlet var save: UIButton!
    
    var alreadyCreatedPassword: Bool = false
    var passWord: String?
    var userName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Nothing to see here"
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
        
    }

    @IBAction func authenticateTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "identify yourself"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified. Please try again", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "Ok", style: .default))
                        if self?.alreadyCreatedPassword == false {
                            ac.addAction(UIAlertAction(title: "Create Password", style: .default) { action in
                                self?.createPasswordAndUsername()
                            })
                        } else {
                            ac.addAction(UIAlertAction(title: "Enter Password Instead", style: .default) { action in
                                self?.authenticatePasswordAndUsername()
                            })
                        }
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authenticaion", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Ok", style: .default))
            present(ac, animated: true)
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndframe = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndframe, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    func unlockSecretMessage() {
        secret.isHidden = false
        title = "Secret Stuff!"
        
        save.isHidden = false
        
        secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
    }
    
    @objc func saveSecretMessage() {
        save.isHidden = true
        guard secret.isHidden == false else { return }
        
        KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
        secret.resignFirstResponder()
        secret.isHidden = true
        title = "Nothing to see here"
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        saveSecretMessage()
    }
    
    func authenticatePasswordAndUsername() {
        userName = KeychainWrapper.standard.string(forKey: "Username")
        passWord = KeychainWrapper.standard.string(forKey: "Password")
        
        let ac = UIAlertController(title: "Login", message: nil, preferredStyle: .alert)
        ac.addTextField { (textfield) in
            textfield.placeholder = "Username"
        }
        ac.addTextField { (textfield) in
            textfield.placeholder = "Password"
        }
        
        ac.addAction(UIAlertAction(title: "Login", style: .default) { _ in
            guard let textFields = ac.textFields else { return }
            
            if let enteredUsername = textFields[0].text, let enteredPassword = textFields[1].text {
                let tempUsername = enteredUsername.trimmingCharacters(in: .whitespaces)
                let tempPassword = enteredPassword.trimmingCharacters(in: .whitespaces)
                
                if tempUsername == self.userName && tempPassword == self.passWord {
                    self.unlockSecretMessage()
                } else if tempUsername == self.userName && tempPassword != self.passWord {
                    let ac2 = UIAlertController(title: "Invalid password", message: nil, preferredStyle: .alert)
                    ac2.addAction(UIAlertAction(title: "Ok", style: .default) { action in
                        self.authenticatePasswordAndUsername()
                    })
                    self.present(ac2, animated: true)
                } else if tempUsername != self.userName && tempPassword == self.passWord {
                    let ac2 = UIAlertController(title: "Invalid username", message: nil, preferredStyle: .alert)
                    ac2.addAction(UIAlertAction(title: "Ok", style: .default) { action in
                        self.authenticatePasswordAndUsername()
                    })
                    self.present(ac2, animated: true)
                } else {
                    let ac2 = UIAlertController(title: "Invalid username and password", message: nil, preferredStyle: .alert)
                    ac2.addAction(UIAlertAction(title: "Ok", style: .default) { action in
                        self.authenticatePasswordAndUsername()
                    })
                    self.present(ac2, animated: true)
                }
            }
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func createPasswordAndUsername() {
        let ac = UIAlertController(title: "Enter Password and Username", message: "Username and password should each contain atleast one character", preferredStyle: .alert)
        ac.addTextField { (textfield) in
            textfield.placeholder = "Username"
        }
        ac.addTextField { (textfield) in
            textfield.placeholder = "Password"
        }
        
        ac.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            guard let textFields = ac.textFields else { return }
            
            let tempUserName = textFields[0].text
            let tempPassWord = textFields[1].text
                    
            self.userName = tempUserName?.trimmingCharacters(in: .whitespaces)
            self.passWord = tempPassWord?.trimmingCharacters(in: .whitespaces)
            
            print(self.userName!)
            print(self.passWord!)
            if self.userName! != "" && self.passWord! != "" {
                KeychainWrapper.standard.set(self.userName!, forKey: "Username")
                KeychainWrapper.standard.set(self.passWord!, forKey: "Password")
                self.alreadyCreatedPassword = true
            } else {
                let ac2 = UIAlertController(title: "Please enter atleast one character for username and password", message: nil, preferredStyle: .alert)
                ac2.addAction(UIAlertAction(title: "Ok", style: .default) { action in
                    self.createPasswordAndUsername()
                })
                self.present(ac2,animated: true)
            }
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(ac, animated: true)
    }
    
}

