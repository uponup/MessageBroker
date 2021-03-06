//
//  ContactsController.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/26.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit
import NotificationBannerSwift

class ContactsController: UITableViewController {

    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    var dataArr: [[ContactCellModel]] {
        [circles, groups, contacts].filter{ $0.count > 0 }
    }
    
    private var _circles: [ContactCellModel]?
    private var circles: [ContactCellModel] {
        get {
            if _circles == nil {
                _circles = UserCenter.center.fetchCirclesList().map { ContactCellModel.circle($0) }
            }
            return _circles!
        }
        set {
            _circles = newValue
        }
    }
    
    private var _groups: [ContactCellModel]?
    private var groups: [ContactCellModel] {
        get {
            if _groups == nil {
                _groups =  UserCenter.center.fetchGroupsList().map { ContactCellModel.group($0) }
            }
            return _groups!
        }
        set {
            _groups = newValue
        }
    }
    
    private var _contacts: [ContactCellModel]?
    private var contacts: [ContactCellModel] {
        get {
            if _contacts == nil {
                _contacts = UserCenter.center.fetchContactsList().map{ ContactCellModel.contact($0) }
            }
            return _contacts!
        }
        set {
            _contacts = newValue
        }
    }
    
    
    private var addGid: String = ""
    private var isLogin: Bool? {
        didSet {
            itemAdd.isEnabled = isLogin ?? false
            _contacts = nil
            _groups = nil
            _circles = nil
            
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemAdd.isEnabled = MavlMessage.shared.isLogin
        MavlMessage.shared.delegateGroup = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(didLoginSuccess), name: .loginSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didLogoutSuccess), name: .logoutSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didSelectedFriends(noti:)), name: .selectedContactsForCircles, object: nil)
    }
    
    // MARK: BarItem Action
    
    @IBAction func addAction(_ sender: Any) {
        let alert = UIAlertController(title: "What do you want to do?", message: nil, preferredStyle: .actionSheet)
        let actionAddFriend = UIAlertAction(title: "Add a friend", style: .default) { [unowned self] _  in
            self.showTextFieldAlert()
        }
        alert.addAction(actionAddFriend)
        
        let actionJoinGroup = UIAlertAction(title: "Join a group chat", style: .default) { [unowned self] _ in
            self.showTextFieldAlert(isAddFriend: false)
        }
        alert.addAction(actionJoinGroup)
        
        let actionCreateGroup = UIAlertAction(title: "Create a group chat", style: .default) { _ in
            if #available(iOS 13.0, *) {
                guard let friendListVc = self.storyboard?.instantiateViewController(identifier: "FriendListController") as? FriendListController else { return }
                self.present(friendListVc, animated: true, completion: nil)

            } else {
                guard let friendListVc = self.storyboard?.instantiateViewController(withIdentifier: "FriendListController") as? FriendListController else { return }
                self.present(friendListVc, animated: true, completion: nil)
            }
        }
        alert.addAction(actionCreateGroup)
        
        let actionCreateCircle = UIAlertAction(title: "Create a circle chat", style: .default) { _ in
            if #available(iOS 13.0, *) {
                guard let friendListVc = self.storyboard?.instantiateViewController(identifier: "FriendListController") as? FriendListController else { return }
                friendListVc.type = .forCircle
                self.present(friendListVc, animated: true, completion: nil)
            }else {
                guard let friendListVc = self.storyboard?.instantiateViewController(withIdentifier: "FriendListController") as? FriendListController else { return }
                friendListVc.type = .forCircle
                self.present(friendListVc, animated: true, completion: nil)
            }
        }
        alert.addAction(actionCreateCircle)
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(actionCancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showTextFieldAlert(isAddFriend type: Bool = true) {
        let title = type ? "Friend someone" : "Join a group"
    
        let alert = UIAlertController(title: title, message: "Please input \(type ? " UserID" : "GroupID") you want", preferredStyle: .alert)
        alert.addTextField { [unowned self] tf in
            NotificationCenter.default.addObserver(self, selector: #selector(self.alertTextFieldDidChanged(noti:)), name: UITextField.textDidChangeNotification, object: nil)
        };
        
        let ok = UIAlertAction(title: "OK", style: .cancel) { [unowned self] _ in
            guard self.addGid.count > 0 else { return }
            
            let isExist = self.contacts.compactMap{ $0.imAccount }.contains(self.addGid.lowercased())
            guard !isExist else {
                self.showHudFailed(title: "Tips", msg: "Already exist this \(type ? "friend" : "group")")
                return
            }
            
            if type {
                let friendId = self.addGid
                MavlMessage.shared.addFriend(withUserName: friendId)
            }else {
                MavlMessage.shared.joinGroup(withGroupId: self.addGid)
            }
        }
        alert.addAction(ok)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Notification Action
    @objc func alertTextFieldDidChanged(noti: Notification) {
        guard let alert = self.presentedViewController as? UIAlertController,
        let textfield = alert.textFields?.first,
        let text = textfield.text else { return }
       
        self.addGid = text
    }
       
    @objc func didLoginSuccess() {
        isLogin = true
    }
    
    @objc func didLogoutSuccess() {
        isLogin = false
    }
    
    @objc func didSelectedFriends(noti: Notification) {
        guard let object = noti.object as? [String: [String]], let contacts = object["contacts"] else { return }
        
        guard let passport = MavlMessage.shared.passport else { return }
        guard let c = CirclesDao.joinCircles(users: contacts, owner: passport.uid) else {
            showHudFailed(title: "Failed:", msg: "Circle create failed!")
            return
        }
        showHudSuccess(title: "Congratulations!", msg: "You have created a circle!")

        circles.append(ContactCellModel.circle(c))
        tableView.reloadData()
    }
}

// MARK: - MavlMessageGroupDelegate
extension ContactsController: MavlMessageGroupDelegate {
    
    func createGroupSuccess(groupId gid: String, isLauncher: Bool) {
        _addGroup(gid)
        
        if isLauncher {
            showHudSuccess(title: "Create Success", msg: "You have created a group chat, now you can chat!")
        }else {
            showHudSuccess(title: "Invitation received", msg: "You are invited to a group chat")
        }
    }
    
    func joinedGroup(groupId gid: String, someone: String) {
        if someone == MavlMessage.shared.passport?.uid {
            showHudSuccess(title: "Tips", msg: "Success in joining new groups")
            _addGroup(gid)
        }else {
            showHudInfo(title: "Tips", msg: "\(someone) has joined the group")
        }
    }
    
    func quitGroup(gid: String, error: Error?) {
        groups = groups.filter{ $0.groupId != gid }
        tableView.reloadData()
        
        UserCenter.center.quit(groupId: gid)
        showHudSuccess(title: "Tip", msg: "You have quit the group：\(gid)")
    }
    
    func addFriendSuccess(friendName name: String) {
        guard let passport = UserCenter.center.passport else {  return  }

        let friend = Contact(name: name, imAccount: name.lowercased())
        contacts.append(ContactCellModel.contact(friend))
        tableView.reloadData()

        // 添加成功后，需要监听好友状态
        StatusQueue.shared.checkStatus(name.lowercased())
        ContactsDao.addContact(owner: passport.uid, name: name.lowercased(), imAccount: name.lowercased())
    }
    
    private func _addGroup(_ gid: String) {
        guard let passport = MavlMessage.shared.passport else { return }
        guard let group = GroupsDao.createGroup(gid: gid, owner: passport.uid) else { return  }
        
        let model = ContactCellModel.group(group)
        groups.append(model)
        tableView.reloadData()
    }
}

// MARK: - Table view data source
extension ContactsController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataArr.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr[section].count
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionView = UIView()
        sectionView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        let label = UILabel(frame: CGRect(x: 12, y: 0, width: 200, height: 32))
        
        let cellModel = dataArr[section]
        if let _ = cellModel.first!.groupId {
            label.text = "Groups"
        }else if let _ = cellModel.first!.circleId {
            label.text = "Circles"
        }else if let _ = cellModel.first!.imAccount {
            label.text = "Friends"
        }else {
            label.text = ""
        }
        sectionView.addSubview(label)
        return sectionView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactCell
        let contact = dataArr[indexPath.section][indexPath.row]
        cell.updateData(contact)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cellModel = self.dataArr[indexPath.section][indexPath.row]
            
        var actionTitle: String = ""
        var execute: ()->Void = {}
        
        if let gid = cellModel.groupId {
            actionTitle = "Quit"
            execute = {
                MavlMessage.shared.quitGroup(withGroupId: gid)
            }
        }else if let circleId = cellModel.circleId {
            actionTitle = "Quit"
            execute = {  [unowned self] in
                self.circles = self.circles.filter {
                    guard let cid = $0.circleId else { return false}
                    return cid != circleId
                }
                tableView.reloadData()
            }
        }else {
            return UISwipeActionsConfiguration(actions: [])
        }
        
        let actionDelete = UIContextualAction(style: .destructive, title: actionTitle) { (action, view, block) in
            execute()
        }
        
        return UISwipeActionsConfiguration(actions: [actionDelete])
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellModel = self.dataArr[indexPath.section][indexPath.row]
              
        if #available(iOS 13.0, *) {
            guard let chatVc = self.storyboard?.instantiateViewController(identifier: "ChatViewController") as? ChatViewController else { return }
            chatVc.hidesBottomBarWhenPushed = true
            if let gid = cellModel.groupId {
                chatVc.chatTo = .toGroup
                chatVc.chatToId = gid
            }else if let circleId = cellModel.circleId {
                chatVc.chatTo = .toCircle
                chatVc.chatToId = circleId
            }else if let contactId = cellModel.imAccount {
                chatVc.chatTo = .toContact
                chatVc.chatToId = contactId
            }
            
            if isMe(cellModel.imAccount)  {
                showHudInfo(title: "Tips:", msg: "Sending yourself a message is not expected")
                return
            }
            self.navigationController?.pushViewController(chatVc, animated: true )
        }else {
            guard let chatVc = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController else { return }
            chatVc.hidesBottomBarWhenPushed = true
            if let gid = cellModel.groupId {
                chatVc.chatTo = .toGroup
                chatVc.chatToId = gid
            }else if let circleId = cellModel.circleId {
                chatVc.chatTo = .toCircle
                chatVc.chatToId = circleId
            }else if let contactId = cellModel.imAccount {
                chatVc.chatTo = .toContact
                chatVc.chatToId = contactId
            }
            
            if isMe(cellModel.imAccount)  {
                showHudInfo(title: "Tips:", msg: "Sending yourself a message is not expected")
                return
            }
            self.navigationController?.pushViewController(chatVc, animated: true )
        }
    }
}

extension ContactsController {
    func showHudSuccess(title: String, msg: String) {
        let banner = NotificationBanner(title: title, subtitle: msg, leftView: nil, rightView: nil, style: .success, colors: self)
        banner.duration = 1.8
        banner.show()
    }
    
    func showHudFailed(title: String, msg: String) {
        let banner = NotificationBanner(title: title, subtitle: msg, leftView: nil, rightView: nil, style: .danger, colors: self)
        banner.duration = 1.8
        banner.show()
    }
    
    func showHudInfo(title: String, msg: String) {
        let banner = NotificationBanner(title: title, subtitle: msg, leftView: nil, rightView: nil, style: .info, colors: self)
        banner.duration = 1.8
        banner.show()
    }
}

extension ContactsController: BannerColorsProtocol {
    public func color(for style: BannerStyle) -> UIColor {
        switch style {
        case .danger: return UIColor(hex: 0xCC1100)
        case .info: return UIColor(hex: 0x878787)
        case .customView:  return UIColor(hex: 0x4F4F4F)
        case .success: return UIColor(hex: 0x01C5BB)
        case .warning: return UIColor(hex: 0xDD7500)
        }
    }
}

extension UIColor {
    @objc public convenience init(hex hexValue: Int, alpha: CGFloat = 1) {
        let red = (CGFloat((hexValue & 0xFF0000) >> 16)) / 255
        let green = (CGFloat((hexValue & 0xFF00) >> 8)) / 255
        let blue = (CGFloat(hexValue & 0xFF)) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
