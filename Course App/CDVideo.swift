//
//  CDVideo.swift
//  Course App
//
//  Created by Ming Ying on 11/7/16.
//  Copyright © 2016 University at Albany. All rights reserved.
//

import Foundation
import CoreData


class CDVideo: NSManagedObject {
    fileprivate static let server = APIClient(baseURL: Settings.apiServer)
    fileprivate static var updatedAt: Date = Date(timeIntervalSince1970: 0)
    
    class func deleteVideosForLecture(_ lecture: CDLecture ,inContext context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDVideo")
        request.predicate = NSPredicate(format: "lecture = %@", argumentArray: [lecture])
        
        if let videos = (try? context.fetch(request)) as? [CDVideo] {
            for video in videos {
                context.delete(video)
            }
        }
    }
    
    fileprivate class func truncate(inContext context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDVideo")
        
        if let videos = (try? context.fetch(request)) as? [CDVideo] {
            for video in videos {
                context.delete(video)
            }
        }
    }
    
    class func upsertFromApiJSON(_ json: [String: AnyObject], inContext context: NSManagedObjectContext, tryUpdate: Bool) -> CDVideo?{
        
        guard
            let id = json["id"] as? Int,
            let title = json["title"] as? String,
            let createdAt = json["createdAt"] as? String,
            let updatedAt = json["updatedAt"] as? String,
            let url = json["url"] as? String
            
            else {
                return nil
        }
        
        var vid: CDVideo? = nil
        if tryUpdate {
            vid = getVideoById(id, inContext: context) ??
                NSEntityDescription.insertNewObject(forEntityName: "CDVideo", into: context) as? CDVideo
        } else {
            vid = NSEntityDescription.insertNewObject(forEntityName: "CDVideo", into: context) as? CDVideo
        }
        
        guard let video = vid
            else {
                return nil
        }
        
        video.id = id as NSNumber
        video.title = title
        video.url = url
        video.createdAt = JSONDate.dateFromJSONString(createdAt)
        video.updatedAt = JSONDate.dateFromJSONString(updatedAt)
        if let lecture = json["lecture"] as? [String: AnyObject] {
            video.lecture = CDLecture.getLectureByApiJSON(lecture, inContext: context)
        }
        
        video.remoteUrl = Settings.apiServer  + url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard
            
            let fileExtention = URL(string: video.remoteUrl!)?.pathExtension
            else {
                print("Video url wrong: \(String(describing: video.url))")
                return nil
        }
        
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        video.localFileUrl = folder.appendingPathComponent("video_\(video.id!).\(fileExtention)").absoluteString
        
        return video
    }
    
    class func getVideoById(_ id: Int, inContext context: NSManagedObjectContext?) -> CDVideo? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDVideo")
        request.predicate = NSPredicate(format: " id = %@ ", argumentArray: [id])
        
        return (try? context?.fetch(request))??.first as? CDVideo
    }
}
