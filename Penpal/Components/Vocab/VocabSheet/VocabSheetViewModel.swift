//
//  VocabSheetViewModel.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//
import Foundation
import Combine

class VocabSheetViewModel: ObservableObject {
    @Published var vocabSheets: [VocabSheetModel] = []
    private var vocabSheetService: VocabSheetService
    private var cancellables = Set<AnyCancellable>()
    private let sqliteHandler = SQLiteVocabSheetHandler()

    init(vocabSheetService: VocabSheetService) {
        self.vocabSheetService = vocabSheetService
        fetchVocabSheets()
    }

    // MARK: - Fetch Vocab Sheets
    func fetchVocabSheets() {
        vocabSheetService.fetchVocabSheets()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("❌ Firestore fetch failed, falling back to SQLite: \(error.localizedDescription)")
                    self?.fetchVocabSheetsSQLite()
                }
            }, receiveValue: { [weak self] sheets in
                self?.vocabSheets = sheets
            })
            .store(in: &cancellables)
    }

    private func fetchVocabSheetsSQLite() {
        // Assuming sqliteHandler.fetchAllVocabSheets() returns [VocabSheetModel]
        let sheets = sqliteHandler.fetchAllVocabSheets()
        DispatchQueue.main.async {
            self.vocabSheets = sheets
            print("✅ Loaded vocab sheets from SQLite fallback")
        }
    }


    // MARK: - Add Vocab Sheet
    func addVocabSheet(name: String, createdBy: String) {
        guard isValidSheetName(name) else {
            print("❌ Invalid sheet name")
            return
        }
        
        let newSheet = VocabSheetModel(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            cards: [],
            createdBy: createdBy,
            totalCards: 0,
            lastReviewed: nil,
            lastUpdated: Date(),
            createdAt: Date(),
            isSynced: false
        )
        
        vocabSheetService.addVocabSheet(newSheet)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    print("✅ Added vocab sheet via Firestore")
                case .failure(let error):
                    print("❌ Firestore add failed, falling back to SQLite: \(error.localizedDescription)")
                    // Fallback to SQLite
                    self?.addVocabSheetSQLite(newSheet)
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }

    // Fallback SQLite insertion function (calls existing SQLite function)
    private func addVocabSheetSQLite(_ sheet: VocabSheetModel) {
        // Call your SQLite method here:
        // Assuming you have a SQLite handler instance `sqliteHandler`
        sqliteHandler.createVocabSheet(vocabSheet: sheet)
        print("✅ Added vocab sheet via SQLite fallback")
    }

    // MARK: - Edit Vocab Sheet
    func editVocabSheet(sheet: VocabSheetModel, userId: String) {
        guard sheet.createdBy == userId else {
            print("❌ Unauthorized")
            return
        }
        
        vocabSheetService.updateVocabSheet(sheet)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    print("✅ Updated via Firestore")
                case .failure(let error):
                    print("❌ Firestore update failed, falling back to SQLite: \(error.localizedDescription)")
                    self?.updateVocabSheetSQLite(sheet)
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }

    // MARK: - Edit Vocab Sheet SQLite
    /// Better To Add Function For It rather than directly inserting
    private func updateVocabSheetSQLite(_ sheet: VocabSheetModel) {
        sqliteHandler.updateVocabSheet(vocabSheet: sheet)
        print("✅ Updated via SQLite fallback")
    }

    // MARK: - Rename Vocab Sheet
    func renameVocabSheet(sheet: VocabSheetModel, newName: String, userId: String) {
        guard sheet.createdBy == userId else {
            print("❌ Unauthorized: User cannot rename this sheet")
            return
        }

        guard isValidSheetName(newName) else {
            print("❌ Invalid sheet name")
            return
        }

        var updatedSheet = sheet
        updatedSheet.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSheet.lastUpdated = Date()

        vocabSheetService.updateVocabSheet(updatedSheet)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Error renaming vocab sheet: \(error.localizedDescription)")
                }
            }, receiveValue: {
                print("✅ Successfully renamed vocab sheet")
            })
            .store(in: &cancellables)
    }

    // MARK: - Delete Vocab Sheet
    func deleteVocabSheet(sheetId: String, userId: String) {
        guard let sheet = vocabSheets.first(where: { $0.id == sheetId }), sheet.createdBy == userId else {
            print("❌ Unauthorized")
            return
        }

        vocabSheetService.deleteVocabSheet(sheetId)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    print("✅ Deleted via Firestore")
                case .failure(let error):
                    print("❌ Firestore delete failed, falling back to SQLite: \(error.localizedDescription)")
                    self?.deleteVocabSheetSQLite(sheetId)
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }

    // MARK: - Delete Vocab Sheet SQLite
    /// Better To Add Function For It rather than directly inserting
    private func deleteVocabSheetSQLite(_ sheetId: String) {
        sqliteHandler.deleteVocabSheet(sheetId)
        print("✅ Deleted via SQLite fallback")
    }

    // MARK: - Validation Helpers
    private func isValidSheetName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 50 && !trimmed.contains { $0.isSymbol }
    }
}

