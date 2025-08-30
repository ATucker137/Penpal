//
//  PenpalsView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

import SwiftUI

// MARK: - Main Penpal View
// This view displays a swipeable list of potential penpals with filters and action buttons.
struct PenpalsView: View {
    @StateObject private var viewModel = PenpalsViewModel()

    // Optional: control which card is visible in the pager
    @State private var showOutOfSwipes: Bool = false
    @State private var selectedId: String?

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Bar: remaining swipes
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Penpals")
                        .font(.title2).bold()
                    Text("Swipes left: \(viewModel.remainingSwipes)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    viewModel.refreshSwipeStatus()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // MARK: - Filter Bar
            HStack {
                // Hobbies Filter
                Picker("Hobby", selection: $viewModel.selectedHobby) {
                    Text("All").tag("All")
                    ForEach(viewModel.allHobbies, id: \.self) { hobby in
                        Text(hobby).tag(hobby)
                    }
                }
                .pickerStyle(.menu)

                // Proficiency Filter (strings via .level.rawValue)
                Picker("Proficiency", selection: $viewModel.selectedProficiency) {
                    Text("All").tag("All")
                    ForEach(viewModel.allProficiencies, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(.menu)

                // Region Filter
                Picker("Region", selection: $viewModel.selectedRegion) {
                    Text("All").tag("All")
                    ForEach(viewModel.allRegions, id: \.self) { region in
                        Text(region).tag(region)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // MARK: - Swipeable Penpal Cards
            if viewModel.filteredPotentialMatches.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 36))
                    Text("No matches right now")
                        .font(.headline)
                    Button("Refresh") { viewModel.fetchPenpals() }
                        .buttonStyle(.borderedProminent)
                    Button("Clear filters") {
                        viewModel.selectedHobby = "All"
                        viewModel.selectedProficiency = "All"
                        viewModel.selectedRegion = "All"
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $selectedId) {
                    ForEach(viewModel.filteredPotentialMatches, id: \.penpalId) { penpal in
                        PenpalCard(
                            penpal: penpal,
                            onAccept: { handleSwipe(accepting: true, penpal: penpal) },
                            onReject: { handleSwipe(accepting: false, penpal: penpal) }
                        )
                        .padding()
                        .tag(penpal.penpalId as String?)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .onChange(of: viewModel.filteredPotentialMatches.map(\.penpalId)) { ids in
                    if selectedId == nil { selectedId = ids.first }
                    else if !ids.contains(selectedId ?? "") {
                        selectedId = ids.first
                    }
                }
            }
        }
        .task {
            viewModel.configureSwipeQuota(maxPerDay: 40, autoRefreshEvery: 10)
            viewModel.fetchPenpals()
            viewModel.startListeningForMatches()
            viewModel.loadLookingFor()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView().scaleEffect(1.2)
            }
        }
        .alert("Out of swipes", isPresented: $showOutOfSwipes) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You’ve hit today’s limit. Come back later, or upgrade / earn bonus swipes.")
        }
    }

    // MARK: - Swipe handler
    private func handleSwipe(accepting: Bool, penpal: PenpalsModel) {
        viewModel.trySwipe(
            perform: {
                if accepting { viewModel.like(penpal, gated: false) }
                else { viewModel.pass(penpal, gated: false) }

                // advance selection to the next card by id
                let list = viewModel.filteredPotentialMatches
                if let i = list.firstIndex(where: { $0.penpalId == penpal.penpalId }) {
                    let next = min(i + 1, max(0, list.count - 1))
                    selectedId = list.indices.contains(next) ? list[next].penpalId : list.first?.penpalId
                } else {
                    selectedId = list.first?.penpalId
                }
            },
            outOfSwipes: { showOutOfSwipes = true }
        )
    }
}

// MARK: - Card
struct PenpalCard: View {
    let penpal: PenpalsModel
    let onAccept: () -> Void
    let onReject: () -> Void

    private let chipColumns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        VStack(spacing: 16) {
            // Image
            if let url = URL(string: penpal.profileImageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.25)
                }
                .frame(width: 240, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Color.gray.opacity(0.25)
                    .frame(width: 240, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(Text("No Image").foregroundColor(.white))
            }

            // First name
            Text(penpal.firstName)
                .font(.title2).bold()
                .multilineTextAlignment(.center)

            // Location
            Text(penpal.region)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Native + Target + Level row
            languageBadges

            // Goal (if present)
            if let goal = penpal.goal {
                HStack(spacing: 6) {
                    Image(systemName: "target").imageScale(.small)
                    Text(goal.title).font(.footnote)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
            }

            // Hobbies
            if !penpal.hobbies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hobbies")
                        .font(.subheadline).bold()
                    LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                        ForEach(penpal.hobbies, id: \.id) { h in
                            HStack(spacing: 6) {
                                Text(h.emoji)
                                Text(h.name).font(.footnote).lineLimit(1)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Actions
            HStack(spacing: 40) {
                Button(action: onReject) {
                    Label("Reject", systemImage: "xmark.circle.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button(action: onAccept) {
                    Label("Accept", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .font(.headline)
            .padding(.top, 6)
        }
        .padding(8)
        .background(.black.opacity(0.25))
        .clipShape(Capsule())
        .shadow(radius: 4)
        .frame(maxWidth: 360)
    }

    // MARK: - Native + Target + Level badges
    private var languageBadges: some View {
        let langName = penpal.proficiency.language.name
        let level     = penpal.proficiency.level
        let nativeLang = penpal.proficiency.isNative ? langName : "—"
        let targetLang = penpal.proficiency.isNative ? "—" : langName

        return HStack(spacing: 8) {
            // Native language (white text)
            Text(nativeLang)
                .font(.subheadline).bold()
                .foregroundColor(.white)

            // “Native” blue pill (show only if we actually have a native language)
            if nativeLang != "—" {
                Text("Native")
                    .font(.caption2).bold()
                    .padding(.vertical, 4).padding(.horizontal, 8)
                    .background(Capsule().fill(Color.blue))
                    .foregroundColor(.white)
            }

            // Target language (white text)
            Text(targetLang)
                .font(.subheadline).bold()
                .foregroundColor(.white)

            // Level pill colored by proficiency
            Text(level.rawValue)
                .font(.caption2).bold()
                .padding(.vertical, 4).padding(.horizontal, 8)
                .background(Capsule().fill(color(for: level)))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .multilineTextAlignment(.center)
    }


    // Helper: color by proficiency level
    private func color(for level: ProficiencyLevel) -> Color {
        switch level {
        case .beginner:          return .green
        case .novice:            return .mint
        case .intermediate:      return .yellow
        case .upperIntermediate: return .orange
        case .advanced:          return .purple
        case .native:            return .blue
        }
    }
}



