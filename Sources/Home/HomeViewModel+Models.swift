//
//  HomeViewModel+Models.swift
//  FhirDemo
//
//  Created by Joe Pan on 2025/12/9.
//

import Foundation
import ModelsR4

// MARK: - State

extension HomeViewModel {
  struct State: Sendable {
    var patients: [Patient] = []
    var viewStatus: ViewStatus = .logout
  }

  enum ViewStatus: Equatable, Sendable {
    case logout
    case loading
    case loggedIn
    case failed
  }
}

// MARK: - Domain Models

extension HomeViewModel {
  struct Patient: Identifiable, Sendable {
    let id: String
    let name: String
    let birthDate: String

    init(patient: ModelsR4.Patient) {
      self.id = patient.id?.value?.string ?? UUID().uuidString
      self.name = patient.name?.first?.given?.first?.value?.string ?? "Unknown"
      self.birthDate = patient.birthDate?.value?.description ?? "Unknown"
    }

    static func with(_ data: Data) throws -> [Patient] {
      let bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: data)
      let patients = bundle.entry?
        .compactMap { $0.resource?.get(if: ModelsR4.Patient.self) } ?? []
      return patients.compactMap { .init(patient: $0) }
    }
  }
}

// MARK: - DTOs

extension HomeViewModel {
  struct TokenDTO: Decodable, Sendable {
    let access_token: String

    func toDomain() -> String? {
      access_token.isEmpty ? nil : access_token
    }
  }
}
