//
//  Settings.swift
//  Course App
//
//  Created by Ming Ying on 10/31/16.
//  Copyright © 2016 University at Albany. All rights reserved.
//

import Foundation

open class Settings {
//    static let apiServer = "http://104.236.56.153:1337" //Ocean2
//    static let apiServer = "http://192.168.10.10:1337" //local vagrant
//    static let apiServer = "http://localhost:1337" //localhost
    static let apiServer = "https://shaban.rit.albany.edu" //production
//    static let apiServer = "https://shaban-test.rit.albany.edu" //testing
//    static let apiServer = "https://shaban-stage.rit.albany.edu" //staging
    
    static let socketServer = apiServer
    static let coursePath = "/course"
    static let lecturePath = "/lecture"
    static let messagePath = "/messages"
    static let userPath = "/users"
    
    static let USER_NAME = "userName"
    static let USER_ID = "phone"
    static let SETTINGS_TAB_INDEX = 1 //tab index of settings tab
    static let COURSES_TAB_INDEX = 0 //tab index of courses tab
    static let UPDATE_INTERVAL: Double = 30 // Minimal seconds interval for updating courses
    
    static fileprivate let defaults = UserDefaults.standard
    
    fileprivate static var phone: String?
    fileprivate static var userName: String?
    fileprivate static var server = APIClient(baseURL: apiServer)
    
    
    static func getPhone() -> String? {
        if phone == nil {
            phone = defaults.string(forKey: USER_ID)
        }
        return phone
    }
    
    static func setPhone(_ phone: String, succeed: @escaping (String) -> Void, fail: @escaping () -> Void) {
        self.phone = phone
        defaults.set( phone, forKey: USER_ID)
        self.userName = nil
        defaults.set( self.userName, forKey: USER_NAME)
        defaults.synchronize()
        
        let path = userPath + "?\(USER_ID)=\(phone)"
        server.get(path) {success, data in
            if success {
                guard let users = data as? [[String: AnyObject]], users.count > 0
                    else {
                        fail()
                        return
                    }
                let user = users[0]
                guard let firstName = user["firstName"],
                    let lastName = user["lastName"]
                    else {
                        fail()
                        return
                    }
                
                self.userName = "\(firstName) \(lastName)"
                defaults.set( self.userName, forKey: USER_NAME)
                defaults.synchronize()
                succeed(self.userName!)
            } else {
                fail()
            }
        }
    }
    
    static func getUserName() -> String? {
        if userName == nil {
            userName = defaults.string(forKey: USER_NAME)
        }
        return userName
    }
}
