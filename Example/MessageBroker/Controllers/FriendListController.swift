//
//  FriendListController.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

enum MultipleSelectedType {
    case forGroup
    case forCircle
}

class FriendListController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnConfirm: UIButton!
    
    var type: MultipleSelectedType = .forGroup
    
    var btnConfirmEnable: Bool {
        getSelectedContacts().count > 0
    }
    
    lazy var contacts: [ContactCellModel] = {
        UserCenter.center.fetchContactsList().map{ ContactCellModel.contact($0) }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnConfirm.isEnabled = btnConfirmEnable
        tableView.setEditing(true, animated: true)
    }

    @IBAction func btnConfirmAction(_ sender: Any) {
        let selectedContacts = getSelectedContacts()
        if type == .forGroup {
            NotificationCenter.default.post(name: .selectedContactsForGroups, object: ["contacts": selectedContacts])
        }else {
            NotificationCenter.default.post(name: .selectedContactsForCircles, object: ["contacts": selectedContacts])
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    private func getSelectedContacts() -> [String] {
        return contacts.enumerated().filter { index, element -> Bool in
            let indexPath = IndexPath(row: index, section: 0)
            let cell = tableView.cellForRow(at: indexPath)
            return cell?.isSelected ?? false
        }.compactMap { $1.imAccount }
    }
}

extension FriendListController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactCell
        let contact = contacts[indexPath.row]
        cell.updateData(contact)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle(rawValue: UITableViewCell.EditingStyle.delete.rawValue | UITableViewCell.EditingStyle.insert.rawValue)!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.btnConfirm.isEnabled = btnConfirmEnable
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.btnConfirm.isEnabled = btnConfirmEnable
    }
}
