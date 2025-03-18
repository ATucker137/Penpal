//
//  Topic.swift
//  Penpal
//
//  Created by Austin William Tucker on 1/9/25.
//

struct Topic: Codable, Identifiable {
    var id: String
    var name: String
    var subcategories: [Subcategory]
    
    // Firestore initializer
    init(id: String, name: String, subcategories: [Subcategory]) {
        self.id = id
        self.name = name
        self.subcategories = subcategories
    }

    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let subcategoriesArray = dictionary["subcategories"] as? [[String: Any]] else {
            return nil
        }
        
        let subcategories = subcategoriesArray.compactMap { Subcategory(dictionary: $0) }
        self.init(id: id, name: name, subcategories: subcategories)
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
