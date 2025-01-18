//
//  Topic.swift
//  Penpal
//
//  Created by Austin William Tucker on 1/9/25.
//

class Topic: Codable, Identifiable {
    var id: String
    var name: String
    var subcategories: [Subcategory]
    
    init(id: String, name: String, subcategories: [Subcategory]) {
        self.id = id
        self.name = name
        self.subcategories = subcategories
    }
    
}


class Subcategory {
    var id: String
    var name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
        
}
