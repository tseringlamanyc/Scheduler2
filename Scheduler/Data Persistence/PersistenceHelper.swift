//
//  PersistenceHelper.swift
//  Scheduler
//
//  Created by Alex Paul on 1/23/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation

public enum DataPersistenceError: Error {
    case propertyListEncodingError(Error)
    case propertyListDecodingError(Error)
    case writingError(Error)
    case deletingError
    case noContentsAtPath(String)
}

// step 1 Custom delegation - defining protocol
protocol DataPersistenceDelegate: AnyObject {
    func didDeleteItem<T>(persistenceHelper: DataPersistence<T>, item: T)
}

typealias Writeable = Codable & Equatable

class DataPersistence<T: Writeable> {
    
    private let filename: String
    
    private var items: [T]
    
    // step 2: defining a delegate a reference property that will be registered as the object listening for notifications
    weak var delegate: DataPersistenceDelegate?
    
    public init(filename: String) {
        self.filename = filename
        self.items = []
    }
    
    private func saveItemsToDocumentsDirectory() throws {
        do {
            let url = FileManager.getPath(with: filename, for: .documentsDirectory)
            let data = try PropertyListEncoder().encode(items)
            try data.write(to: url, options: .atomic)
        } catch {
            throw DataPersistenceError.writingError(error)
        }
    }
    
    // Create
    public func createItem(_ item: T) throws {
        _ = try? loadItems()
        items.append(item)
        do {
            try saveItemsToDocumentsDirectory()
        } catch {
            throw DataPersistenceError.writingError(error)
        }
    }
    
    // Read
    public func loadItems() throws -> [T] {
        let path = FileManager.getPath(with: filename, for: .documentsDirectory).path
        if FileManager.default.fileExists(atPath: path) {
            if let data = FileManager.default.contents(atPath: path) {
                do {
                    items = try PropertyListDecoder().decode([T].self, from: data)
                } catch {
                    throw DataPersistenceError.propertyListDecodingError(error)
                }
            }
        }
        return items
    }
    
    // for re-ordering, and keeping date in sync
    public func synchronize(_ items: [T]) {
        self.items = items
        try? saveItemsToDocumentsDirectory()
    }
    
    // Update
    @discardableResult // silences the warning if a the return value is not used
    public func updateEvents(old: T, new: T) -> Bool {
        if let index = items.firstIndex(of: old) {  // old == new (Event must conform to Equatable)
            let result = update(item: new, index: index)
            return result
        }
        return false
    }
    
    @discardableResult
    public func update(item: T, index: Int) -> Bool {
        items[index] = item
        
        // save items to documents directory
        do {
            try saveItemsToDocumentsDirectory()
            return true
        } catch {
            return false
        }
    }
    
    // Delete
    public func deleteItem(at index: Int) throws {
        let deletedItem = items.remove(at: index)
        do {
            try saveItemsToDocumentsDirectory()
            
            // step 3 - use custom delegation reference to notify observer of deletion 
            delegate?.didDeleteItem(persistenceHelper: self, item: deletedItem)
        } catch {
            throw DataPersistenceError.deletingError
        }
    }
    
    public func hasItemBeenSaved(_ item: T) -> Bool {
        guard let items = try? loadItems() else {
            return false
        }
        self.items = items
        if let _ = self.items.firstIndex(of: item) {
            return true
        }
        return false
    }
    
    public func removeAll() {
        guard let loadedItems = try? loadItems() else {
            return
        }
        items = loadedItems
        items.removeAll()
        try? saveItemsToDocumentsDirectory()
    }
}
