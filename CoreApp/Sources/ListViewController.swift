//
//  ListViewController.swift
//  CoreApp
//
//  Created by 노우영 on 6/11/25.
//

import Foundation
import UIKit

class ListViewController: UIViewController {

    private let tableView = UITableView()

    // Example screens
    private let cores = Core.cores()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = .orange

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension ListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cores.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = cores[indexPath.row].title
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let screenName = cores[indexPath.row].title
        let vc = cores[indexPath.row].viewController
        vc.view.backgroundColor = .systemBackground
        vc.title = screenName
        navigationController?.pushViewController(vc, animated: true)
    }
}
