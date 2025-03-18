//
//  Model.swift
//  FhirDemo
//
//  Created by Joe Pan on 2025/3/17.
//

import UIKit
import ModelsR4

typealias DataSource = UICollectionViewDiffableDataSource<Int, DisplayPatient>
typealias Snapshot = NSDiffableDataSourceSnapshot<Int, DisplayPatient>
typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, DisplayPatient>

enum Action {
    case login(UIWindow?)
    case getPatients
    case logout
}

enum State {
    case none
    case somethingWrong
    case loginSuccess
    case getPatients([DisplayPatient])
    case logoutSuccess
}

struct Token: Decodable {
    let access_token: String
}

struct DisplayPatient: Hashable {
    let id: String
    let name: String
    let birthDate: String
    
    init(patient: ModelsR4.Patient) {
        self.id = patient.id?.value?.string ?? "Unknown"
        self.name = patient.name?.first?.given?.first?.value?.string ?? "Unknown"
        self.birthDate = patient.birthDate?.value?.description ?? "Unknown"
    }
}
