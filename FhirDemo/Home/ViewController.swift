//
//  ViewController.swift
//  FhirDemo
//
//  Created by Joe Pan on 2025/3/17.
//

import UIKit
import Combine
import SwiftUI

final class ViewController: UIViewController {
    private let viewModel = ViewModel()
    private var binding: Set<AnyCancellable> = []
    private lazy var list = makeList()
    private lazy var dataSorce = makeDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSelf()
        setupBinding()
    }
}

private extension ViewController {
    
    // MARK: - Setup Something
    
    func setupSelf() {
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = makeLoginItem()
        list.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(list)
        NSLayoutConstraint.activate([
            list.topAnchor.constraint(equalTo: view.topAnchor),
            list.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            list.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    func setupBinding() {
        viewModel.$state.receive(on: DispatchQueue.main).sink { [weak self] state in
            self?.contentUnavailableConfiguration = nil
            
            guard let self else { return }
            
            switch state {
            case .none:
                handleStateNone()
            case .loginSuccess:
                handleStateLoginSuccess()
            case .logoutSuccess:
                handleStateLogoutSuccess()
            case .somethingWrong:
                handleStateSomethingWrong()
            case let .getPatients(patients):
                handleStateGetPatients(patients)
            }
        }.store(in: &binding)
    }
    
    // MARK: - Handle Something
    
    func handleStateNone() {}
    
    func handleStateLoginSuccess() {
        navigationItem.rightBarButtonItem = makeLogoutItem()
        doGetPatients()
    }
    
    func handleStateLogoutSuccess() {
        navigationItem.rightBarButtonItem = makeLoginItem()
        var snapshot = dataSorce.snapshot()
        snapshot.deleteAllItems()
        dataSorce.apply(snapshot)
    }
    
    func handleStateSomethingWrong() {
        navigationItem.rightBarButtonItem = makeLoginItem()
        
        contentUnavailableConfiguration = UIHostingConfiguration {
            Text("Something wrong...")
                .font(.largeTitle)
                .foregroundStyle(.red)
        }
    }
    
    func handleStateGetPatients(_ patients: [DisplayPatient]) {
        navigationItem.rightBarButtonItem = makeLogoutItem()
        
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(patients, toSection: 0)
        dataSorce.apply(snapshot)
    }
    
    // MARK: - Make Something
    
    func makeLoginItem() -> UIBarButtonItem {
        return .init(title: "Login", style: .plain, target: self, action: #selector(doLogin))
    }
    
    func makeLogoutItem() -> UIBarButtonItem {
        return .init(title: "Logout", style: .plain, target: self, action: #selector(doLogout))
    }
    
    func makeLoadingItem() -> UIBarButtonItem {
        let loading = UIActivityIndicatorView(style: .medium)
        let result = UIBarButtonItem(customView: loading)
        loading.startAnimating()
        return result
    }
    
    func makeList() -> UICollectionView {
        .init(frame: .zero, collectionViewLayout: makeListLayout())
    }
    
    func makeCell() -> CellRegistration {
        .init { cell, indexPath, itemIdentifier in
            cell.contentConfiguration = UIHostingConfiguration {
                VStack {
                    Text(itemIdentifier.name)
                        .bold()
                        .font(.headline)
                    Text(itemIdentifier.birthDate)
                        .font(.subheadline)
                }
            }
        }
    }
    
    func makeDataSource() -> DataSource {
        let cell = makeCell()
        
        return .init(collectionView: list) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: cell, for: indexPath, item: itemIdentifier)
        }
    }
    
    func makeListLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout.list(using: .init(appearance: .plain))
    }
    
    // MARK: - Do Something
    
    @objc func doLogin() {
        navigationItem.rightBarButtonItem = makeLoadingItem()
        viewModel.doAction(.login(view.window))
    }
    
    @objc func doLogout() {
        viewModel.doAction(.logout)
    }
    
    func doGetPatients() {
        navigationItem.rightBarButtonItem = makeLoadingItem()
        
        contentUnavailableConfiguration = UIHostingConfiguration {
            ProgressView()
        }
        
        viewModel.doAction(.getPatients)
    }
}
