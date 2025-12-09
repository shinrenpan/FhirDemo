//
//  HomeView.swift
//  FhirDemo
//
//  Created by Joe Pan on 2025/12/9.
//

import SwiftUI

struct HomeView: View {
  let viewModel: HomeViewModel

  var body: some View {
    contentView()
      .toolbar {
        ToolbarItem(placement: .topBarTrailing, content: trailingButton)
      }
  }
}

// MARK: - Views

private extension HomeView {
  @ViewBuilder
  func trailingButton() -> some View {
    switch viewModel.state.viewStatus {
    case .logout, .failed:
      Button("Login") {
        Task { await viewModel.doAction(.view(.loginButtonDidTap)) }
      }
      
    case .loading:
      ProgressView()
      
    case .loggedIn:
      Button("Logout") {
        Task { await viewModel.doAction(.view(.logoutButtonDidTap)) }
      }
    }
  }
  
  @ViewBuilder
  func contentView() -> some View {
    switch viewModel.state.viewStatus {
    case .loading:
      ProgressView()
      
    case .failed:
      Text("Something wrong!!!")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.red)
      
    case .logout:
      EmptyView()
      
    case .loggedIn:
      list()
    }
  }
  
  @ViewBuilder
  func list() -> some View {
    ScrollView {
      LazyVStack {
        ForEach(viewModel.state.patients, id: \.id) { patient in
          cell(patient)
            .padding()
            .background(.green)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
      }
      .padding()
    }
  }
  
  @ViewBuilder
  func cell(_ patient: HomeViewModel.DisplayPatient) -> some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading) {
        Text("Name:")
        Text("Birthdate:")
      }
      VStack(alignment: .leading) {
        Text(patient.name)
        Text(patient.birthDate)
      }
      Spacer()
    }
  }
}
