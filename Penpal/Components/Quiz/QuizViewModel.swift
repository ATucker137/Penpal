//
//  QuizViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//


class QuizViewModel {
    @Published var quiz: [Quiz] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private let service: QuizService
    
    
    init(service: QuizService = QuizService()) {
        self.service = service
        //fetchQuiz(quiz: <#T##Quiz#>, completion: <#T##(Result<Void, Error>) -> Void#>)
    }
    
    // MARK: - Fetch Quiz
    func fetchQuiz() {
        isLoading = true
        service.fetchQuiz { [weak self] reuslt in DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let quiz):
                    self?.quiz = quiz
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Update Quiz
    func updateQuiz() {
        isLoading = true
        service.updateQuiz {[weak self] result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let quiz):
                    self?.quiz = quiz
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Delete Quiz
    func deleteQuiz() {
        isLoading = true
        service.deleteQuiz {[weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let quiz):
                    self?.quiz = quiz
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Save Quiz
    func saveQuiz() {
        isLoading = false
        service.saveQuiz {[weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let quiz):
                    self?.quiz = quiz
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
}
