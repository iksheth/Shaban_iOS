//
//  CDCourse.swift
//  Course App
//
//  Created by Ming Ying on 11/7/16.
//  Copyright © 2016 University at Albany. All rights reserved.
//

import Foundation
import CoreData


class CDCourse: NSManagedObject {
    
    fileprivate static let server = APIClient(baseURL: Settings.apiServer)
    fileprivate static var updatedAt: Date = Date(timeIntervalSince1970: 0)

    class func fetchCourses(_ context: NSManagedObjectContext) {
        let interval = abs(updatedAt.timeIntervalSinceNow)
        if interval <= Settings.UPDATE_INTERVAL { //update at most once every x seconds
            print("Downloaded courses \(interval) seconds ago, skip this time")
            return
        }
        
        server.get(Settings.coursePath) {success, data in
            if success {
                guard let courses = data as? [[String:AnyObject]]
                    else {
                        return
                }
                
                print("Downloaded \(courses.count) courses")
                self.updatedAt = Date()
                
                context.perform() {
                    self.truncate(context)
                    
                    for element in courses {
                        upsertFromApiJSON(element, context: context, tryUpdate: false)
                    }
                    _ = try? context.save()
                }
            }
        }
    }
    
    fileprivate class func truncate(_ context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDCourse")
        
        if let courses = (try? context.fetch(request)) as? [CDCourse] {
            for course in courses {
                context.delete(course)
            }
            
        }
    }
    
    class func upsertFromApiJSON(_ json: [String: AnyObject], context: NSManagedObjectContext, tryUpdate: Bool) {
        
        guard
            let id = json["id"] as? Int,
            let name = json["name"] as? String,
            let createdAt = json["createdAt"] as? String,
            let updatedAt = json["updatedAt"] as? String
            else {
                return
        }
        
        var cs: CDCourse? = nil
        if tryUpdate {
            cs = getCourseById(id, inContext: context) ??
                NSEntityDescription.insertNewObject(forEntityName: "CDCourse", into: context) as? CDCourse
        } else {
            cs = NSEntityDescription.insertNewObject(forEntityName: "CDCourse", into: context) as? CDCourse
        }
        
        guard
            let course = cs
            else {
                return
        }
        
        course.id = id as NSNumber
        course.name = name
        course.createdAt = JSONDate.dateFromJSONString(createdAt)
        course.updatedAt = JSONDate.dateFromJSONString(updatedAt)
        
        if let lectures = json["lectures"] as? [[String: AnyObject]] {
            for lec in lectures {
                if let cdLecture = CDLecture.upsertFromApiJSON(lec, inContext: context, tryUpdate: true) {
                    cdLecture.course = course
                }
            }
        }
    }
    
    class func getCourseById(_ id: Int, inContext context: NSManagedObjectContext?) -> CDCourse? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDCourse")
        request.predicate = NSPredicate(format: " id = %@ ", argumentArray: [id])
        
        return (try? context?.fetch(request))??.first as? CDCourse
    }
    
    class func getCourseByApiJSON(_ json: [String: AnyObject], inContext context: NSManagedObjectContext) -> CDCourse? {
        guard
            let id = json["id"] as? Int
            else {
                return nil
        }
        return getCourseById(id, inContext: context)
    }
}
