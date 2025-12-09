//
//  HomeViewModel+Model.swift
//  FhirDemo
//
//  Created by Joe Pan on 2025/12/9.
//

import Foundation
import ModelsR4

extension HomeViewModel {
  struct State: Equatable {
    var patients: [DisplayPatient] = []
    var viewStatus: ViewStatus = .logout
  }
}

extension HomeViewModel {
  enum ViewStatus: Equatable {
    case logout
    case loading
    case loggedIn
    case failed
  }
}

extension HomeViewModel {
  struct DisplayPatient: Equatable, Identifiable {
    let id: String
    let name: String
    let birthDate: String
    
    init(patient: ModelsR4.Patient) {
      self.id = patient.id?.value?.string ?? UUID().uuidString
      self.name = patient.name?.first?.given?.first?.value?.string ?? "Unknown"
      self.birthDate = patient.birthDate?.value?.description ?? "Unknown"
    }

    static func with(_ data: Data) throws -> [DisplayPatient] {
      let bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: data)
      let patients = bundle.entry?
        .compactMap {
          $0.resource?.get(if: ModelsR4.Patient.self)
        } ?? []

      return patients.compactMap { .init(patient: $0) }
    }
  }
}

extension HomeViewModel {
  struct Token: Decodable {
      let access_token: String
  }
}
