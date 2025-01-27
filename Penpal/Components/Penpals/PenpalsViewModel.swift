//
//  PenpalsViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

class PenpalsViewModel: ObservableObject {
    
    // MARK: - Properties
    @Published var penpals: [PenpalsViewModel]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    //MARK: - Private Properties
    private let penpalsService = PenpalsService
    
    //MARK: - Initializer
    init(penpalsService: PenpalsService = PenpalsService()) {
        self.penpalsService = penpalsService
    }
    
    
    
    

}
