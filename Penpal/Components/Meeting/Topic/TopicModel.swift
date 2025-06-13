//
//  TopicModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 1/9/25.
//

struct TopicModel: Codable, Identifiable {
    var id: String
    var name: String
    var subcategories: [Subcategory]
    var isSynced: Bool
    
    // Firestore initializer
    init(id: String, name: String, subcategories: [Subcategory], isSynced: Bool) {
        self.id = id
        self.name = name
        self.subcategories = subcategories
        self.isSynced = isSynced
        
    }

    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let subcategoriesArray = dictionary["subcategories"] as? [[String: Any]],
              let isSynced = dictionary["isSynced"] as Bool
        else {
            return nil
        }
        
        let subcategories = subcategoriesArray.compactMap { Subcategory(dictionary: $0) }
        self.init(id: id, name: name, subcategories: subcategories, isSynced: isSynced)
    }

    
}


struct Subcategory: Codable, Identifiable{
    var id: String
    var name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String else {
            return nil
        }
        self.init(id: id, name: name)
    }
        
}
