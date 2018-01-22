//
//  CDLecture+CoreDataProperties.swift
//  Shaban
//
//  Created by Ming Ying on 11/23/16.
//  Copyright © 2016 University at Albany. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CDLecture {

    @NSManaged var createdAt: Date?
    @NSManaged var fileName: String?
    @NSManaged var id: NSNumber?
    @NSManaged var localFileUrl: String?
    @NSManaged var name: String?
    @NSManaged var remoteUrl: String?
    @NSManaged var serial_number: NSNumber?
    @NSManaged var transcript_url: String?
    @NSManaged var updatedAt: Date?
    @NSManaged var course: CDCourse?
    @NSManaged var videos: NSSet?

}
