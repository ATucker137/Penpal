//
//  PenpalsView.swift
//  Penpal
//
//  Created by Austin William Tucker on 11/29/24.
//

struct PenpalsView: View {
    @StateObject private var viewModel = PenpalsViewModel()
    let userId: String
    @Binding var selectedTab: Tab

}
