//
//  Downloader.swift
//  Shaban
//
//  Created by Ming Ying on 11/10/16.
//  Copyright © 2016 University at Albany. All rights reserved.
//

import Foundation

class Downloader: NSObject, URLSessionDownloadDelegate  {
    fileprivate var progressCB: ((Float) -> Void)?
    fileprivate var remoteURL: URL?
    fileprivate var localURL: URL?
    
    fileprivate var session: Foundation.URLSession?
    fileprivate var task: URLSessionDownloadTask?
    fileprivate var resumeData: Data?
    
    init(remoteURL: String, localURL: String, progressCB: ((Float) -> Void )?) {
        self.remoteURL = URL(string:  remoteURL)
        self.localURL = URL(string: localURL)
        self.progressCB = progressCB
    }
    
    func start() {
        guard let remoteURL = self.remoteURL,
        let localURL = self.localURL
            else {
                return
        }
        
        if task != nil {
            print("Downloader: already downloading, can't download again")
            return
        }
        
        //resume a download
        if let data = resumeData {
            print("resume download for \(remoteURL)")
            task = session?.downloadTask(withResumeData: data)
            task!.resume()
        } else {
            //new download
            if session == nil {
                session = Foundation.URLSession(configuration: URLSessionConfiguration.default,
                                       delegate: self,
                                       delegateQueue: OperationQueue.main)
            }
            
            task = session?.downloadTask(with: remoteURL, completionHandler: {
                location, res, error in
                if error != nil {
                    print("download \(self.remoteURL!) failed")
//                    self.resumeData = error?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
//                   _ = try? FileManager.default.removeItem(at: localURL)
                }
                
                if let httpRes = res as? HTTPURLResponse {
                    if httpRes.statusCode != 200 {
                        print("download \(self.remoteURL!) failed")
                        self.task = nil
                    } else {
                        print("download \(self.remoteURL!) succeed")
                        self.progressCB?(1.0)
                        guard let localURL = self.localURL
                            else {
                                self.task = nil
                                return
                        }
                        do {
                            try FileManager.default.moveItem(at: location!, to: localURL)
                        } catch {
                            print("Move file \(location!.path) failed")
                        }
                        
                        self.task = nil
                        self.resumeData = nil
                        self.progressCB?(1.0)
                    }
                }
                
            })
            task!.resume()
        }
    }
    
    
    fileprivate func cancelDownload() {
        if let task = self.task {
            print("Cancel download for \(remoteURL)")
            task.cancel() {
                resumeData in
                self.resumeData = resumeData
                self.task = nil
            }
        }
    }
    
    //download resume
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didResumeAtOffset fileOffset: Int64,
                                      expectedTotalBytes: Int64) {
        self.progressCB?(Float(fileOffset)/Float(expectedTotalBytes))
    }
    
    //progress report
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.progressCB?(Float(totalBytesWritten)/Float(totalBytesExpectedToWrite))
    }
    
    //download finished
    @objc func urlSession(_ session: URLSession,
                      downloadTask: URLSessionDownloadTask,
                                   didFinishDownloadingTo location: URL) {
        print("URLSession downloadTask didFinishDownloadingToURL")
//        guard let localURL = self.localURL
//            else {
//                return
//        }
//        do {
//            try NSFileManager.defaultManager().moveItemAtURL(location, toURL: localURL)
//        } catch {
//            print("Move file \(location.path!) failed")
//        }
//        
//        self.task = nil
//        self.resumeData = nil
//        self.progressCB?(1.0)
    }
    
    //download finished
    func urlSession(_ session: URLSession,
                      task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        print(session)
        print(task)
        guard let localURL = self.localURL
            else {
                return
        }
        if error != nil {
            print("download \(remoteURL!) failed")
            resumeData = error?._userInfo?[NSURLSessionDownloadTaskResumeData] as? Data
           _ = try? FileManager.default.removeItem(at: localURL)
        } else {
            print("download \(remoteURL!) succeed")
        self.progressCB?(1.0)
        }
        self.task = nil
    }
}
