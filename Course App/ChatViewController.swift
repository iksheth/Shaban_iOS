//
//  ChatViewController.swift
//  Course App
//
//  Created by Ming Ying on 7/17/16.
//  Copyright © 2016 University at Albany. All rights reserved.
//

import UIKit
import SocketIO
import CoreData

class ChatViewController: CDTableViewInViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    let TAB_BAR_HEIGHT = 49
    
    fileprivate let context = ((UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext)!
    
    @IBOutlet weak var messageTableView: UITableView! {
        didSet {
            self.tableView = messageTableView
        }
    }
    
    @IBOutlet weak var textField: UITextField!
    
    var lecture: CDLecture! {
        didSet {
            guard let lecture = self.lecture
                else {
                    return
            }
            
            self.navigationItem.title = lecture.name

            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDMessage")
            request.sortDescriptors = [NSSortDescriptor(
                key: "id",
                ascending: true,
                selector: nil
                )]
            request.predicate = NSPredicate(format: "group == %@", lecture.id!)
            fetchedResultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            CDMessage.fetchMessagesForGroupId(self.lecture.id as! Int, inContext: self.context, callback: nil)
        }
    }
    
    fileprivate var socket = SocketIOClient(socketURL: URL(string: Settings.socketServer)!, config: [SocketIOClientOption.connectParams(["__sails_io_sdk_version":"0.11.0"])])

    
    // MARK: ViewController Lift cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Chatting: \(self.lecture.name!)"

        socket.on("connect") {data, ack in
            print("socket connected")
            let url = "/groups/join/\(self.lecture.id!)"
            self.socket.emit("post", ["url": url])
        }
        
        socket.on("message") { data, ack in
            self.context.perform() {
                for msg in data {
                    _ = CDMessage.messageFromSocketJSON(msg as AnyObject, inContext: self.context)
                }
                _ = try? self.context.save()
            }
        }
        
        textField.delegate = self
        
        socket.connect()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let sections = fetchedResultsController?.sections,
            let row = sections.first?.numberOfObjects, row > 0
            else {
                return
        }
        
        let indexPath = IndexPath(row: row - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    // MARK: UITextFieldDelegate
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func keyboardWillShow(_ notification: Notification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.view.frame.origin.y -= keyboardSize.height - CGFloat(TAB_BAR_HEIGHT)
        }
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.view.frame.origin.y += keyboardSize.height - CGFloat(TAB_BAR_HEIGHT)
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Actions
    @IBAction func send(_ sender: UIButton) {
        guard let text = textField.text, text != "",
            let phone = Settings.getPhone(), phone != "",
            let userName = Settings.getUserName(), userName != ""
            else {
                let alert = UIAlertController(title: "Couldn't send message", message: "Please enter your registered phone number in \"Settings\" tab!", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                self.tabBarController?.selectedIndex = Settings.SETTINGS_TAB_INDEX
                return
        }
        
        socket.emit("post", [
            "url": "/messages",
            "data": [
                "group": self.lecture.id as! Int,
                "author": phone,
                "content": text
            ]
            ])
        textField.text = ""
        textField.resignFirstResponder()
    }
    
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Message", for: indexPath)
        if let message = fetchedResultsController?.object(at: indexPath) as? CDMessage {
            cell.textLabel?.text = message.author! + ":"
            cell.detailTextLabel?.text = message.content
        }
        
        return cell
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    override func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        
        guard let sections = fetchedResultsController?.sections,
            let row = sections.first?.numberOfObjects, row > 0
            else {
                return
        }
        
        let indexPath = IndexPath(row: row - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}
