//
//  SettingsViewController.swift
//  Course App
//
//  Created by Ming Ying on 8/31/16.
//  Copyright © 2016 University at Albany. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var promptLabel: UILabel!
    
    //MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phoneField.text = Settings.getPhone()
        let userName = Settings.getUserName()
        if userName != nil && userName != "" {
            self.promptLabel.text = "Name: \(userName!)"
            self.promptLabel.textColor = UIColor.blue
            self.phoneField.textColor = UIColor.blue
        }

        saveButton.isEnabled = false
    }

    // MARK: Actions
    
    @IBAction func savePhone(_ sender: UIButton) {
        if let phone = phoneField.text{
            if phone != Settings.getPhone() {
                Settings.setPhone(phone,
                    succeed: { userName in
                        DispatchQueue.main.async {
                            self.promptLabel.text = "Name: \(userName)"
                            self.promptLabel.textColor = UIColor.blue
                            self.phoneField.textColor = UIColor.blue
                        }
                    },
                    fail: {
                        DispatchQueue.main.async {
                            self.promptLabel.text = "Phone number not registered!"
                            self.promptLabel.textColor = UIColor.red
                            self.phoneField.textColor = UIColor.red
                        }
                })
            }
        }
        saveButton.isEnabled = false
        phoneField.resignFirstResponder()
    }
    
    //MARK: TextFiel delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        saveButton.isEnabled = false
        if let temp = phoneField.text{
            let phone = temp.trimmingCharacters(
                in: CharacterSet.whitespacesAndNewlines
            )
            phoneField.text = phone
            if phone != Settings.getPhone() {
                saveButton.isEnabled = true
            }
        }
    }
}
