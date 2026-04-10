//
//  CoreDataStack.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

import CoreData

final class CoreDataStack {

	static let shared = CoreDataStack()

	let container: NSPersistentContainer

	init(inMemory: Bool = false) {
		container = NSPersistentContainer(name: "MarketPulseModel")

		if inMemory {
			container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
		}

		container.loadPersistentStores { _, error in
			if let error {
				fatalError("Failed to load persistent stores: \(error)")
			}
		}

		container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		container.viewContext.automaticallyMergesChangesFromParent = true
	}

	var viewContext: NSManagedObjectContext {
		container.viewContext
	}
}
