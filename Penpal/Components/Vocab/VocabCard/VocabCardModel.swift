//
//  VocabCardModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

class VocabCardModel: Codable, Identifiable {
    
    // MARK: - Properties
    var id: String
    var name: String
    
    
    // MARK: - Initializer
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    
    
    //MARK: - Send To FireStore
    
    
    //MARK: - Get From FireStore
}
