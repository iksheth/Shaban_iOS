//
//  CourseTableViewController.swift
//  Course App
//
//  Created by Ming Ying on 8/31/16.
//  Copyright © 2016 University at Albany. All rights reserved.
//

import UIKit
import CoreData

class CourseTableViewController: CoreDataTableViewController {
    
    fileprivate let context = ((UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext)!
    
    //MARK: ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDCourse")
        request.sortDescriptors = [NSSortDescriptor(
            key: "id",
            ascending: true,
            selector: nil
            )]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        guard let phone = Settings.getPhone(), phone != ""
            else {
                self.tabBarController?.selectedIndex = Settings.SETTINGS_TAB_INDEX
                return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        CDCourse.fetchCourses(self.context)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CouresCell", for: indexPath)
        if let course = self.fetchedResultsController?.object(at: indexPath) as? CDCourse {
            cell.textLabel?.text = course.name
        }

        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let lectureVC = segue.destination as? LectureTableViewController {
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)
            lectureVC.course = fetchedResultsController!.object(at: indexPath!) as! CDCourse
        }
    }

}
