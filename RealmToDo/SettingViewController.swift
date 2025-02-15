//
//  SettingViewController.swift
//  RealmToDo
//
//  Created by Monzy on 15/11/2.
//  Copyright © 2015年 Monzy. All rights reserved.
//

import UIKit
import LocalAuthentication

class SettingViewController: UIViewController {

    @IBOutlet var touchIdSwitch: UISwitch!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var changePasswordButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        print("switcher state: \(touchIdSwitch.on)")
        initSwitchState()
        initGUI()
        // Do any additional setup after loading the view.
    }
    
    func initGUI() {
        changePasswordButton.layer.cornerRadius = changePasswordButton.frame.width / 10
    }
    
    func initSwitchState() {
        let userDefault = NSUserDefaults.standardUserDefaults()
        if userDefault.objectForKey("AuthenticationSwitch") == nil {
            AuthenticationSetter.setAuthenticationSwitchUserDefault(false)
            touchIdSwitch.setOn(false, animated: false)
            print("AuthenticationSwitch set")
        } else {
            touchIdSwitch.setOn(userDefault.boolForKey("AuthenticationSwitch"), animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func changePassword(sender: UIButton) {
        
        if let password = passwordField.text {
            if password == "" {
                MZToastView().configure((self.revealViewController().view)!, content: "password is empty", position: .Middle, length: .Short, lightMode: .Dark).show()
                return
            }
        } else {
            MZToastView().configure((self.revealViewController().view)!, content: "password is empty", position: .Middle, length: .Short, lightMode: .Dark).show()
            return
        }
        let password = passwordField.text ?? ""
        let userDefault = NSUserDefaults.standardUserDefaults()
        if userDefault.stringForKey("Password") == nil {
            self.passwordSetSuccess(password)
        } else {
            AuthenticationSetter.touchIdAuthentication() {
                isSuccess, error in
                if isSuccess == true {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.passwordSetSuccess(password)
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        AuthenticationSetter.showPasswordAlert("Changing Password", message: "Enter old password", rootViewController: self,
                            onSuccess: {
                                self.passwordSetSuccess(password)
                            },
                            onFail: {
                                MZToastView().configure((self.revealViewController().view)!, content: "Wrong password", position: .Middle, length: .Short, lightMode: .Dark).show()
                            },
                            onCancel: nil
                        )
                    }
                }
            }
        }
        self.view.endEditing(true)
        passwordField.text = ""
    }
    
    private func passwordSetSuccess(password: String) {
        AuthenticationSetter.setPassword(password)
        AuthenticationSetter.setAuthenticationSwitchUserDefault(true)
        if touchIdSwitch.on == false {
            touchIdSwitch.setOn(self.touchIdSwitch.on, animated: false)
        }
        MZToastView().configure((self.revealViewController().view)!, content: "Password changed", position: .Middle, length: .Short, lightMode: .Dark).show()
    }
    
    
    @IBAction func swichTouchIdState(sender: UISwitch) {
        print("newState:\(sender.on)")
        if sender.on == false {
            AuthenticationSetter.touchIdAuthentication() {
                isSuccess, error in
                if isSuccess == true {
                    AuthenticationSetter.setAuthenticationSwitchUserDefault(false)
                    dispatch_async(dispatch_get_main_queue(), {
                        MZToastView().configure((self.revealViewController().view)!, content: "Security closed", position: .Middle, length: .Short, lightMode: .Dark).show()
                    })
                } else {
                    if let laError = error as? LAError {
                        print("error happened in authenticating: \(laError)")
                        switch laError {
                        case .UserCancel, .SystemCancel, .AppCancel:
                            print("LAError: \(laError.rawValue)")
                            dispatch_async(dispatch_get_main_queue(), {
                                self.touchIdSwitch.setOn(true, animated: true)
                            })
                            break
                        case .UserFallback, .TouchIDNotAvailable, .TouchIDNotEnrolled:
                            AuthenticationSetter.showPasswordAlert("Closing Secure", message: "please enter password", rootViewController: self,
                                onSuccess: {
                                AuthenticationSetter.setAuthenticationSwitchUserDefault(false)
                                MZToastView().configure((self.revealViewController().view)!, content: "Security closed", position: .Middle, length: .Short, lightMode: .Dark).show()
                                },
                                onFail: {
                                MZToastView().configure((self.revealViewController().view)!, content: "Wrong Password", position: .Middle, length: .Short, lightMode: .Dark).show()
                                self.touchIdSwitch.setOn(true, animated: true)
                                },
                                onCancel: {
                                self.touchIdSwitch.setOn(true, animated: true)
                                }
                            )
                            break
                        default:
                            sender.setOn(true, animated: true)
                            break
                        }
                    } else {
                        print("no error")
                    }
                }
            }
        } else {
            if AuthenticationSetter.hasPassword() {
                AuthenticationSetter.setAuthenticationSwitchUserDefault(true)
            } else {
                AuthenticationSetter.showPasswordAlert("Set Password", message: "Enter Password", rootViewController: self, onSuccess: {
                    AuthenticationSetter.setAuthenticationSwitchUserDefault(true)
                    MZToastView().configure((self.revealViewController().view)!, content: "Password set success", position: .Middle, length: .Short, lightMode: .Dark).show()
                    }, onFail: nil,
                    onCancel: {
                        self.touchIdSwitch.setOn(false, animated: true)
                })
            }
        }
        self.view.endEditing(true)
    }
    
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
