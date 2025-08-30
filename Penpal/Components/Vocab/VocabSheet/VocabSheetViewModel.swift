//
//  VocabSheetViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import Combine
import FirebaseAuth

@MainActor
class VocabSheetViewModel: ObservableObject {
    @Published var vocabSheets: [VocabSheetModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var vocabSheetService: VocabSheetService
    private let auth = Auth.auth()
    private var cancellables = Set<AnyCancellable>()
    private let sqliteHandler = SQLiteVocabSheetHandler()
    private let category = "vocabSheet ViewModel"

    init(vocabSheetService: VocabSheetService) {
        self.vocabSheetService = vocabSheetService
        // Task to call an async function from the initializer
        Task {
            await fetchVocabSheets()
        }
    }

    // MARK: - Fetch Vocab Sheets
    func fetchVocabSheets() async {
        isLoading = true
        errorMessage = nil
        do {
            let sheets = try await vocabSheetService.fetchVocabSheets()
            self.vocabSheets = sheets
            LoggerService.shared.log(.info, "✅ Successfully fetched vocab sheets from Firestore", category: category)
        } catch {
            LoggerService.shared.log(.error, "❌ Firestore fetch failed: \(error.localizedDescription). Falling back to SQLite.", category: category)
            fetchVocabSheetsSQLite()
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func fetchVocabSheetsSQLite() {
        // Assuming sqliteHandler.fetchAllVocabSheets() returns [VocabSheetModel]
        let sheets = sqliteHandler.fetchAllVocabSheets()
        self.vocabSheets = sheets
        LoggerService.shared.log(.info, "✅ Loaded vocab sheets from SQLite fallback", category: category)
    }


    // MARK: - Add Vocab Sheet
    func addVocabSheet(name: String) async {
        guard let userId = auth.currentUser?.uid else {
            LoggerService.shared.log(.error, "❌ User not logged in", category: category)
            self.errorMessage = "You must be logged in to create a sheet."
            return
        }

        guard isValidSheetName(name) else {
            LoggerService.shared.log(.error, "❌ Invalid sheet name", category: category)
            self.errorMessage = "Invalid sheet name."
            return
        }
        
        isLoading = true
        errorMessage = nil

        let newSheet = VocabSheetModel(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            cards: [],
            createdBy: userId,
            totalCards: 0,
            lastReviewed: nil,
            lastUpdated: Date(),
            createdAt: Date(),
            isSynced: false
        )
        
        do {
            try await vocabSheetService.addVocabSheet(newSheet)
            LoggerService.shared.log(.info, "✅ Added vocab sheet via Firestore", category: category)
        } catch {
            LoggerService.shared.log(.error, "❌ Firestore add failed: \(error.localizedDescription). Falling back to SQLite.", category: category)
            addVocabSheetSQLite(newSheet)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    // MARK: - Add Vocab Sheet SQLite
    // Fallback SQLite insertion function (calls existing SQLite function)
    private func addVocabSheetSQLite(_ sheet: VocabSheetModel) {
        sqliteHandler.createVocabSheet(vocabSheet: sheet)
        LoggerService.shared.log(.info, "✅ Added vocab sheet via SQLite fallback", category: category)
    }

    // MARK: - Edit Vocab Sheet
    func editVocabSheet(sheet: VocabSheetModel) async {
        guard let userId = auth.currentUser?.uid else {
            LoggerService.shared.log(.error, "❌ Unauthorized edit attempt: user not logged in", category: category)
            self.errorMessage = "You must be logged in to edit this sheet."
            return
        }
        
        guard sheet.createdBy == userId else {
            LoggerService.shared.log(.error, "❌ Unauthorized edit attempt", category: category)
            self.errorMessage = "You are not authorized to edit this sheet."
            return
        }
        
        isLoading = true
        errorMessage = nil

        do {
            try await vocabSheetService.updateVocabSheet(sheet)
            LoggerService.shared.log(.info, "✅ Updated vocab sheet via Firestore", category: category)
        } catch {
            LoggerService.shared.log(.error, "❌ Firestore update failed: \(error.localizedDescription). Falling back to SQLite.", category: category)
            updateVocabSheetSQLite(sheet)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    // MARK: - Edit Vocab Sheet SQLite
    /// Better To Add Function For It rather than directly inserting
    private func updateVocabSheetSQLite(_ sheet: VocabSheetModel) {
        sqliteHandler.updateVocabSheet(vocabSheet: sheet)
        LoggerService.shared.log(.info, "✅ Updated vocab sheet via SQLite fallback", category: category)
    }

    // MARK: - Rename Vocab Sheet
    func renameVocabSheet(sheet: VocabSheetModel, newName: String) async {
        guard let userId = auth.currentUser?.uid else {
            LoggerService.shared.log(.error, "❌ Unauthorized rename attempt: user not logged in", category: category)
            self.errorMessage = "You must be logged in to rename this sheet."
            return
        }
        
        guard sheet.createdBy == userId else {
            LoggerService.shared.log(.error, "❌ Unauthorized rename attempt", category: category)
            self.errorMessage = "You are not authorized to rename this sheet."
            return
        }

        guard isValidSheetName(newName) else {
            LoggerService.shared.log(.error, "❌ Invalid sheet name", category: category)
            self.errorMessage = "Invalid sheet name."
            return
        }
        
        isLoading = true
        errorMessage = nil

        var updatedSheet = sheet
        updatedSheet.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSheet.lastUpdated = Date()

        do {
            try await vocabSheetService.updateVocabSheet(updatedSheet)
            LoggerService.shared.log(.info, "✅ Successfully renamed vocab sheet", category: category)
        } catch {
            LoggerService.shared.log(.error, "❌ Error renaming vocab sheet: \(error.localizedDescription)", category: category)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    // MARK: - Delete Vocab Sheet
    func deleteVocabSheet(sheetId: String) async {
        guard let userId = auth.currentUser?.uid else {
            LoggerService.shared.log(.error, "❌ Unauthorized delete attempt: user not logged in", category: category)
            self.errorMessage = "You must be logged in to delete this sheet."
            return
        }
        
        guard let sheet = vocabSheets.first(where: { $0.id == sheetId }), sheet.createdBy == userId else {
            LoggerService.shared.log(.error, "❌ Unauthorized delete attempt", category: category)
            self.errorMessage = "You are not authorized to delete this sheet."
            return
        }
        
        isLoading = true
        errorMessage = nil

        do {
            try await vocabSheetService.deleteVocabSheet(sheetId)
            LoggerService.shared.log(.info, "✅ Deleted vocab sheet via Firestore", category: category)
        } catch {
            LoggerService.shared.log(.error, "❌ Firestore delete failed: \(error.localizedDescription). Falling back to SQLite.", category: category)
            deleteVocabSheetSQLite(sheetId)
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    // MARK: - Delete Vocab Sheet SQLite
    /// Better To Add Function For It rather than directly inserting
    private func deleteVocabSheetSQLite(_ sheetId: String) {
        sqliteHandler.deleteVocabSheet(sheetId)
        LoggerService.shared.log(.info, "✅ Deleted vocab sheet via SQLite fallback", category: category)
    }

    // MARK: - Validation Helpers
    private func isValidSheetName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 50 && !trimmed.contains { $0.isSymbol }
    }
}

