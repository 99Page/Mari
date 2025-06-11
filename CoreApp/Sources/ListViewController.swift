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
    private let screens: [String] = [
        "Camera",
        "Map",
        "Post Upload",
        "Settings"
    ]

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
        return screens.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = screens[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let screenName = screens[indexPath.row]
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = screenName
        navigationController?.pushViewController(vc, animated: true)
    }
}
