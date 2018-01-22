//
//  VideoViewController.swift
//  Course App
//
//  Created by Ming Ying on 8/31/16.
//  Copyright © 2016 University at Albany. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import QuickLook
import CoreData

class VideoViewController: CDTableViewInViewController, UITableViewDataSource, UITableViewDelegate, QLPreviewControllerDataSource {
    fileprivate let context = ((UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext)!
    
    @IBOutlet weak var weakTableView: UITableView! {
        didSet {
            self.tableView = weakTableView
        }
    }
    
    var lecture: CDLecture! {
        didSet {
            guard let lecture = self.lecture
                else {
                    fetchedResultsController = nil
                    return
            }
            
            self.title = lecture.name
            self.navigationItem.title = lecture.name
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDVideo")
            request.sortDescriptors = [NSSortDescriptor(
                key: "id",
                ascending: true,
                selector: nil
                )]
            request.predicate = NSPredicate(format: "lecture == %@", lecture)
            fetchedResultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            if fileExists(lecture.localFileUrl!) {
                let indexPath = IndexPath(row: 0, section: 1)
                progresses[indexPath] = 1.0
            }
        }

    }
    
    fileprivate var progresses = Dictionary<IndexPath, Float>()
    
    // MARK: ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.lecture.name
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: Actions
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            selectPDF(tableView, indexPath: indexPath)
        } else if indexPath.section == 0 {
            selectVideo(tableView, indexPath: indexPath)
        }
    }
    
    fileprivate func selectPDF(_ tableView: UITableView ,indexPath: IndexPath) {
        guard let localFileURL = lecture.localFileUrl
            else {
                return
        }
        
        if fileExists(localFileURL) {
            let preview = QLPreviewController()
            preview.dataSource = self
            if let nvc = self.navigationController {
                nvc.pushViewController(preview, animated: true)
            } else {
                self.present(preview, animated: true, completion: nil)
            }
        } else {
            guard let rUrl = lecture.remoteUrl,
                let lUrl = lecture.localFileUrl
                else {
                  return
            }
            let downloader = Downloader(remoteURL: rUrl, localURL: lUrl) { progress in
                self.progresses[indexPath] = progress
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                })
            }
            if let cell = tableView.cellForRow(at: indexPath) as? VideoTableViewCell {
                cell.progressBar.progress = 0.0
                cell.progressBar.isHidden = false
            }
            
            downloader.start()
        }
    }
    
    fileprivate func selectVideo(_ tableView: UITableView, indexPath: IndexPath) {
        guard
            let video = fetchedResultsController?.object(at: indexPath) as? CDVideo,
            let file = video.localFileUrl
            else {
                return
        }
        
        if fileExists(file) {
            _ = try? playVideo(video)
        } else {
            guard let rUrl = video.remoteUrl,
                let lUrl = video.localFileUrl
                else {
                    return
            }
            let downloader = Downloader(remoteURL: rUrl, localURL: lUrl) { progress in
                self.progresses[indexPath] = progress
                DispatchQueue.main.async(execute: { 
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                })
            }
            if let cell = tableView.cellForRow(at: indexPath) as? VideoTableViewCell {
                cell.progressBar.progress = 0.0
                cell.progressBar.isHidden = false
            }
            downloader.start()
        }
 
    }
    
    fileprivate func playVideo(_ video: CDVideo) throws {
        guard let url = URL(string: video.localFileUrl!)
            else {
                return
        }
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(5, 1), queue: nil) { (currentTime) in
            let seconds = CMTimeGetSeconds(player.currentTime())
            self.context.perform() {
                video.currentTime = seconds as NSNumber
                _ = try? self.context.save()
            }
        }
        
        if let currentTime = video.currentTime as? Double {
            let cmtime = CMTime(seconds: currentTime, preferredTimescale: 1)
            player.seek(to: cmtime)
        }
        
        self.present(playerController, animated: true) {
            player.play()
        }
    }
    
    fileprivate func fileExists(_ localFileURL: String) -> Bool {
        guard let url = URL(string: localFileURL)
            else {
                return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // MARK: QLPreviewControllerDataSource
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController,
                           previewItemAt index: Int) -> QLPreviewItem {
        guard let urlString = lecture?.localFileUrl,
        let url = URL(string: urlString)
        else {
            return URL(string: "x") as! QLPreviewItem
        }
        
        return url as QLPreviewItem
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let chatVC = segue.destination as? ChatViewController {
            chatVC.lecture = self.lecture
        }
    }
    
    // MARK: UITableViewDataSource
    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 2
//    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return super.tableView(tableView, numberOfRowsInSection: section)
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Transcripts"
        } else if section == 0 {
            return "Videos"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath)
        if let videoCell = cell as? VideoTableViewCell {
            if indexPath.section == 0 {
                if let video = self.fetchedResultsController?.object(at: indexPath) as? CDVideo {
                    videoCell.titleLabel?.text = video.title
                    if let localFileUrl = video.localFileUrl {
                        if fileExists(localFileUrl) {
                            progresses[indexPath] = 1.0
                        }
                    }
                }
            } else {
                videoCell.titleLabel?.text = lecture.fileName
            }
            
            let progress = progresses[indexPath] ?? 0
            videoCell.progressBar.setProgress(progress, animated: false)
            
            videoCell.progressBar.isHidden = (progress == 0)
            
            return videoCell
        } else {
            return cell
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}
