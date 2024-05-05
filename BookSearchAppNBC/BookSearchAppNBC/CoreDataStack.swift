//
//  CoreDataStack.swift
//  BookSearchAppNBC
//
//  Created by David Jang on 5/5/24.
//

import CoreData
import UIKit


// MARK: 코어데이터 접근 클래스 (싱글톤)

class CoreDataStack {
    static let shared = CoreDataStack()
    var context: NSManagedObjectContext? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to retrieve the app delegate")
        }
        return appDelegate.persistentContainer.viewContext
    }
}

