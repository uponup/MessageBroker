//
//  ViewController.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var tfUserName: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var itemClose: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    private var _sessions: [ChatSession]?
    var sessions: [ChatSession] {
        get {
            if _sessions == nil {
                _sessions = UserCenter.center.fetchSessionList()
            }
            return _sessions!
        }
        set {
            _sessions = newValue
        }
    }
    
    private var isLogin: Bool = false {
        didSet {
            view.endEditing(true)
            if isLogin {
                navigationItem.title = "Online"
                loginView.isHidden = true
                itemClose.isEnabled = true
                _sessions = nil
                
                let passport = Passport(tfUserName.text.value, tfPassword.text.value)
                UserCenter.center.login(passport: passport)
                
                refreshData()
                
                checkStatus()
            }else {
                navigationItem.title = "Offline"
                tfUserName.text = ""
                tfPassword.text = "xxxxxx"
                loginView.isHidden = false
                itemClose.isEnabled = false
                
                UserCenter.center.logout()
            }
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        isLogin = false
        tableView.tableFooterView = UIView()
        view.bringSubviewToFront(loginView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didSelectedContacts(noti:)), name: .selectedContactsForGroups, object: nil)
        
        StatusQueue.shared.delegate = self
        launchAnimation()
    }
    
    func refreshData() {
        _sessions = nil
        tableView.reloadData()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @objc func didSelectedContacts(noti: Notification) {
        guard let object = noti.object as? [String: [String]], let contacts = object["contacts"] else { return }
        MavlMessage.shared.createAGroup(withUsers: contacts)
    }

    @IBAction func loginAction(_ sender: Any) {
        guard let username = tfUserName.text,
            let password = tfPassword.text else { return }
        MavlMessage.shared.delegateMsg = self
        MavlMessage.shared.delegateLogin = self
        MavlMessage.shared.login(userName: username, password: password)
        
        // 添加默认联系人
        let _ = UserDefaults.executeOnce(withKey: "\(username.lowercased())_AddDefaultFriends") {
            ContactsDao.addContact(owner: username.lowercased(), name: "bob", imAccount: "bob")
            ContactsDao.addContact(owner: username.lowercased(), name: "peter", imAccount: "peter")
        }
    }
    
    @IBAction func logout(_ sender: Any) {
        MavlMessage.shared.logout()
    }
    
    // MARK: - Private Method
    private func checkStatus() {
        guard let passport = MavlMessage.shared.passport else { return }
        for contact in ContactsDao.fetchAllContacts(owner: passport.uid) {
            MavlMessage.shared.checkStatus(withUserName: contact.imAccount)
        }
    }
}

extension ViewController: MavlMessageDelegate {
    func beginLogin() {
        TRACE("start login...")
    }
    
    func loginSuccess() {
        TRACE("login success")
        isLogin = true
        
        NotificationCenter.default.post(name: .loginSuccess, object: nil)
    }
    
    func logout(withError: Error?) {
        isLogin = false
        
        guard let err = withError else {
            NotificationCenter.default.post(name: .logoutSuccess, object: nil)
            return
        }
        // 如果有err，说明是异常断开连接
        let alert = UIAlertController(title: "Warning", message: err.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController: MavlMessageStatusDelegate {
    func mavl(willSend: Mesg) {
        NotificationCenter.default.post(name: .willSendMesg, object: ["msg": willSend])
    }
    
    func mavl(didSend: Mesg, error: Error?) {
        if let err = error {
            NotificationCenter.default.post(name: .didSendMesgFailed, object: ["msg": didSend, "err": err])
        }else {
            NotificationCenter.default.post(name: .didSendMesg, object: ["msg": didSend])
        }
    }
    
    func mavl(didRevceived messages: [Mesg], isLoadMore: Bool) {
        NotificationCenter.default.post(name: .didReceiveMesg, object: ["msg": messages, "isLoadMore": isLoadMore])
        
        for mesg in messages.map({ Message($0) }) {
            MessageDao.addMesg(msg: mesg)
        }
        refreshData()
    }
}

extension ViewController: StatusQueueDelegate {
    func statusQueue(didOnline user: String) {
        print("\(user) 上线了！！！")
        NotificationCenter.default.post(name: .userStatusDidChanged, object: nil)
    }
    
    func statusQueue(didOfflineUsers: [String]) {
        print("这些人下线了:\(didOfflineUsers)")
        NotificationCenter.default.post(name: .userStatusDidChanged, object: nil)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatSessionCell", for: indexPath) as! ChatSessionCell
        let sessionModel = sessions[indexPath.row]
        cell.updateData(session: sessionModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let sessionModel = sessions[indexPath.row]
        
        guard let chatVc = storyboard?.instantiateViewController(identifier: "ChatViewController") as? ChatViewController else { return }
        chatVc.hidesBottomBarWhenPushed = true
        //TODO: 1、add Circle    2、传给chatVc的参数可能会画有问题
        chatVc.chatTo = sessionModel.isGroup ?  .toGroup : .toContact
        chatVc.chatToId = sessionModel.toId
        navigationController?.pushViewController(chatVc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = sessions[indexPath.row]
        
        guard session.isGroup  else { return UISwipeActionsConfiguration(actions: []) }
        
        let actionDelete = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] (action, view, block) in
            self.sessions.remove(at: indexPath.row)
            self.refreshData()
            
            UserCenter.center.deleteChatSession(gid: session.toId)
        }
        
        return UISwipeActionsConfiguration(actions: [actionDelete])
    }
}

extension ViewController {
    public func TRACE(_ msg: String) {
        print(">>>: \(msg)")
    }
}

extension ViewController {
    private func launchAnimation() {
        let launchVc = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateViewController(withIdentifier: "launch")
        
        guard let keyWindow = UIApplication.shared.windows.last else {
            TRACE("没有视图")
            return
        }
        keyWindow.addSubview(launchVc.view)
        
        guard let label = launchVc.view.viewWithTag(101),
           let _ = launchVc.view.viewWithTag(100) else { return }
        
        UIView.animate(withDuration: 0.8, animations: {
            label.transform = CGAffineTransform(scaleX: 1.2,y: 1.2)
            launchVc.view.alpha = 0.3
        }) { finished  in
            launchVc.view.removeFromSuperview()
        }
    }
}
