//
//  OnboardingView.swift
//  Penpal
//
//  Created by Austin William Tucker on 8/23/25.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var vm: OnboardingViewModel
    let onFinished: () -> Void

    /// Pass the shared ProfileViewModel and current userId from the parent (e.g., ContentView).
    init(profileVM: ProfileViewModel, userId: String?, onFinished: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: OnboardingViewModel(profileVM: profileVM, userId: userId))
        self.onFinished = onFinished
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Progress
                ProgressView(value: vm.progress)
                    .tint(.blue)
                    .padding(.horizontal)

                // Step content
                Group {
                    switch vm.step {
                    case .welcome:
                        WelcomeStep(next: vm.next)
                    case .name:
                        NameStep(first: $vm.draft.firstName, last: $vm.draft.lastName)
                    case .region:
                        RegionStep(region: $vm.draft.region, country: $vm.draft.country)
                    case .hobbies:
                        HobbiesStep(selected: $vm.draft.hobbies)
                    case .languages:
                        LanguagesStep(fluent: $vm.draft.fluent, learning: $vm.draft.learning)
                    case .review:
                        ReviewStep(draft: vm.draft)
                    }
                }
                .padding(.horizontal)

                if let err = vm.errorMessage {
                    Text(err).foregroundColor(.red).font(.footnote)
                }

                // Nav buttons
                HStack {
                    if !vm.isFirstStep {
                        Button("Back", action: vm.back)
                            .buttonStyle(.bordered)
                    }
                    Spacer()
                    if vm.isLastStep {
                        Button {
                            vm.submit { ok in
                                if ok { onFinished() }
                            }
                        } label: {
                            if vm.isSubmitting { ProgressView() }
                            else { Text("Finish").bold() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isSubmitting)
                    } else {
                        Button("Next", action: vm.next)
                            .buttonStyle(.borderedProminent)
                            .disabled(!vm.canAdvance())
                    }
                }
                .padding()
            }
            .navigationTitle("Set up your profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Step Views

private struct WelcomeStep: View {
    let next: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to Penpal!").font(.title).bold()
            Text("Let’s set up your profile in a few quick steps.")
                .foregroundStyle(.secondary)
            Button("Get started", action: next)
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
        .padding(.top, 24)
    }
}

private struct NameStep: View {
    @Binding var first: String
    @Binding var last: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What’s your name?").font(.headline)
            TextField("First name", text: $first).textFieldStyle(.roundedBorder)
            TextField("Last name", text: $last).textFieldStyle(.roundedBorder)
        }
    }
}

private struct RegionStep: View {
    @Binding var region: String
    @Binding var country: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where are you from?").font(.headline)
            TextField("Region (e.g., California)", text: $region).textFieldStyle(.roundedBorder)
            TextField("Country (e.g., USA)", text: $country).textFieldStyle(.roundedBorder)
        }
    }
}

// Uses your typed Hobbies model
private struct HobbiesStep: View {
    @Binding var selected: Set<Hobbies>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick your hobbies").font(.headline)

            ForEach(Hobbies.all) { hobby in
                let isOn = selected.contains(hobby)
                Button {
                    if isOn { selected.remove(hobby) } else { selected.insert(hobby) }
                } label: {
                    HStack {
                        Text("\(hobby.emoji)  \(hobby.name)")
                        Spacer()
                        if isOn { Image(systemName: "checkmark.circle.fill") }
                    }
                    .padding(10)
                    .background(isOn ? Color.blue.opacity(0.12) : Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

// Uses typed Language + LanguageProficiency
private struct LanguagesStep: View {
    @Binding var fluent: [LanguageProficiency]
    @Binding var learning: [LanguageProficiency]
    private let languages = Language.predefinedLanguages

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Languages").font(.headline)

            Text("Fluent in").font(.subheadline)
            LanguageList(available: languages, items: $fluent)

            Divider().padding(.vertical, 8)

            Text("Learning").font(.subheadline)
            LanguageList(available: languages, items: $learning)
        }
    }
}

private struct LanguageList: View {
    let available: [Language]
    @Binding var items: [LanguageProficiency]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(available) { lang in
                let idx = items.firstIndex { $0.language.id == lang.id }
                let selected = idx != nil
                let level = idx.flatMap { items[$0].level } ?? .beginner
                let isNative = idx.flatMap { items[$0].isNative } ?? false

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Button(selected ? "Remove" : "Add") {
                            if selected {
                                items.removeAll { $0.language.id == lang.id }
                            } else {
                                items.append(LanguageProficiency(language: lang, level: .beginner, isNative: false))
                            }
                        }
                        .buttonStyle(.bordered)

                        Text(lang.name).font(.body)
                        Spacer()
                    }

                    if selected {
                        Picker("Level", selection: Binding(
                            get: { level },
                            set: { new in
                                if let i = items.firstIndex(where: { $0.language.id == lang.id }) {
                                    items[i].level = new
                                }
                            }
                        )) {
                            ForEach(ProficiencyLevel.allCases, id: \.self) { lvl in
                                Text(lvl.rawValue).tag(lvl)
                            }
                        }
                        .pickerStyle(.menu)

                        Toggle("Native speaker", isOn: Binding(
                            get: { isNative },
                            set: { new in
                                if let i = items.firstIndex(where: { $0.language.id == lang.id }) {
                                    items[i].isNative = new
                                }
                            }
                        ))
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

private struct ReviewStep: View {
    let draft: OnboardingViewModel.Draft
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Review").font(.headline)
            Group {
                Text("Name: \(draft.firstName) \(draft.lastName)")
                Text("Region: \(draft.region), \(draft.country)")

                let hobbyNames = draft.hobbies.map(\.name).sorted()
                Text("Hobbies: \(hobbyNames.joined(separator: ", "))")

                let fluentList = draft.fluent
                    .map { "\($0.language.name) (\($0.level.rawValue))" }
                    .joined(separator: ", ")
                Text("Fluent: \(fluentList)")

                let learningList = draft.learning
                    .map { "\($0.language.name) (\($0.level.rawValue))" }
                    .joined(separator: ", ")
                Text("Learning: \(learningList)")
            }
            .foregroundStyle(.secondary)
        }
    }
}
