//
//  ChatViewController.swift
//  Example
//
//  Created by CrazyWisdom on 15/12/24.
//  Copyright © 2015年 emqtt.io. All rights reserved.
//

import UIKit
import CocoaMQTT
import ESPullToRefresh

enum ChatToType {
    case toGroup
    case toCircle
    case toContact
}

class ChatViewController: UIViewController {
    
    var chatTo: ChatToType = .toContact
    var chatToId: String = ""
    
    private var _messages: [ChatMessage]?
    var messages: [ChatMessage] {
        get {
            if _messages == nil {
                guard let passport = MavlMessage.shared.passport else {
                    _messages = []
                    return []
                }
                
                if chatTo == .toContact {
                    _messages = MessageDao.fetchAllMesgs(local: passport.uid, remote: chatToId).map { ChatMessage(status: .send, mesg: $0)}
                }else {
                    _messages = MessageDao.fetchAllMesgs(fromGroup: chatToId).map { ChatMessage(status: .send, mesg: $0) }
                }
            }
            return _messages!
        }
        
        set {
            _messages = newValue
        
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                self?.scrollToBottom()
            }
        }
    }
    
    private var slogan: String {
        if chatTo == .toContact {
            guard let contact = ContactsDao.fetchContact(imAccount: chatToId) else {
                return "Invalid Contact"
            }
            
            return "ImAccount: \(contact.name)";
        }else if chatTo == .toGroup {
            return "Gid: \(chatToId)";
        }else {
            return "Circle: \(chatToId)"
        }
    }
        
    private var isOnline: Bool = false {
        didSet {
            if isOnline {
                statusView.backgroundColor = .green
                statusLabel.text = "online"
            }else {
                statusView.backgroundColor = .darkGray
                statusLabel.text = "offline"
            }
        }
    }
    
    private var latestMessagesId: String {
        guard let lastestMessage = messages.first else { return "" }
        
        return lastestMessage.uuid
    }
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextView: UITextView! {
        didSet {
            messageTextView.layer.cornerRadius = 5
        }
    }
    @IBOutlet weak var animalAvatarImageView: UIImageView!
    @IBOutlet weak var sloganLabel: UILabel!
    
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputBaseView: UIView!
    
    @IBOutlet weak var sendMessageButton: UIButton! {
        didSet {
            sendMessageButton.isEnabled = false
        }
    }
    
    @IBAction func sendMessage() {
        guard let message = messageTextView.text else { return }
        
        let localId = "\(MessageDao.fetchLastOne() + 1)"
        
        if chatTo == .toGroup {
            MavlMessage.shared.send(message: message, toGroup: chatToId, localId:localId)
        }else if chatTo == .toCircle {
            let friends = CirclesDao.fetchAllMembers(fromCircle: chatToId)
            MavlMessage.shared.send(message: message, toGroup: chatToId, localId: localId, withFriends: friends)
        }else {
            MavlMessage.shared.send(message: message, toFriend: chatToId, localId:localId)
        }
        messageTextView.text = ""
        sendMessageButton.isEnabled = false
        messageTextViewHeightConstraint.constant = messageTextView.contentSize.height
        messageTextView.layoutIfNeeded()
        view.endEditing(true)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageTextView.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.es.addPullToRefresh { [weak self] in
            
            guard self?.chatTo != .toCircle else {
                self?.tableView.es.stopPullToRefresh()
                return
            }
            let type: FetchMessagesType = self?.chatTo == .toGroup ? .more : .one

            print("====>从\((self?.latestMessagesId).value)开始请求")

            MavlMessage.shared.fetchMessages(msgId: (self?.latestMessagesId).value, from: (self?.chatToId).value, type: type, offset: 10)
        }
        
        if chatTo == .toContact {
            animalAvatarImageView.image = #imageLiteral(resourceName: "cn_single_default")
        }else if chatTo == .toCircle {
            animalAvatarImageView.image = #imageLiteral(resourceName: "cn_circle_default")
        }else {
            animalAvatarImageView.image = #imageLiteral(resourceName: "cn_chatroom_default")
        }
        sloganLabel.text = slogan
        
        NotificationCenter.default.addObserver(self, selector: #selector(receivedMessage(notification:)), name: .didReceiveMesg, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedWillSendMessage(notification:)), name: .willSendMesg, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveDidSendMessageFailed(notification:)), name: .didSendMesgFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveDidSendMessage(notification:)), name: .didSendMesg, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveDidChangedUserStatus), name: .userStatusDidChanged, object: nil)
        
        if chatTo == .toContact {
            isOnline = StatusQueue.shared.isOnline(withImAccount: chatToId)
        }else {
            statusView.isHidden = true
            statusLabel.isHidden = true
        }
        
        if chatTo == .toGroup  {
            if GroupsDao.fetchGroup(gid: chatToId) == nil {
                inputBaseView.isHidden = true
            }
        }else if chatTo == .toCircle {
            
        }else {
            if ContactsDao.fetchContact(imAccount: chatToId) == nil {
                inputBaseView.isHidden = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: Notification Action
    @objc func keyboardChanged(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let keyboardValue = userInfo["UIKeyboardFrameEndUserInfoKey"]
        let bottomDistance = UIScreen.main.bounds.size.height - keyboardValue!.cgRectValue.origin.y - UIScreen.bottomEdge
        
        if bottomDistance > 0 {
            inputViewBottomConstraint.constant = bottomDistance
        } else {
            inputViewBottomConstraint.constant = 0
        }
        view.layoutIfNeeded()
    }
    
    @objc func receivedWillSendMessage(notification: NSNotification) {
        guard let object = notification.object as? [String: Mesg],
            let msg = object["msg"] else { return }
        
        let message = ChatMessage(status: .sending, mesg: Message(msg))
        messages.append(message)
        tableView.reloadData()
        
        print("将要发送:\(msg.text)")
    }
    
    @objc func receiveDidSendMessage(notification: NSNotification) {
        guard let object = notification.object as? [String: Mesg],
            let msg = object["msg"] else { return }
        messages = messages.map {
            if $0.localId == msg.localId.value {
//                return ChatMessage(status: .send, mesg: msg)
                return $0
            }else {
                return $0
            }
        }
        
        tableView.reloadData()
        print("发送成功:\(msg.text)")
    }
    
    @objc func receiveDidSendMessageFailed(notification: NSNotification) {
        guard let object = notification.object as? [String: Any],
            let _ = object["err"] as? Error,
            let msg = object["msg"] as? Mesg else { return }
        
        messages = messages.map {
            if $0.localId == msg.localId.value {
                return ChatMessage(status: .sendfail, mesg: Message(msg))
            }else {
                return $0
            }
        }
    }
    
    @objc func receivedMessage(notification: NSNotification) {
        
        let object = notification.object as! [String: Any]
        let receivedMsgs = object["msg"] as? [Mesg]
        let isLoadMore = object["isLoadMore"] as! Bool
        
        if isLoadMore {
            tableView.es.stopPullToRefresh()
        }
        
        guard let msgs = receivedMsgs else { return }
        let sortedMsgs = msgs.filter {
            $0.conversationId == chatToId
        }.map{
            ChatMessage(status: .sendSuccess, mesg: Message($0))
        }.reversed()
        
        if isLoadMore {
            messages.insert(contentsOf: sortedMsgs, at: 0)
            scrollToTop()
        }else {
            messages.append(contentsOf: sortedMsgs)
            var dict: [String: ChatMessage] = [:]
            for message in messages {
                dict[message.localId] = message
            }
            messages = Array(dict.values).sorted(by: <)
        }
    }
    
    @objc func receiveDidChangedUserStatus() {
        if chatTo == .toContact {
            isOnline = StatusQueue.shared.isOnline(withImAccount: chatToId)
        }
    }
    
    func scrollToBottom() {
        guard messages.count > 3 else { return }
        
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    func scrollToTop() {
        guard messages.count > 0 else { return }
        
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}


extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.contentSize.height != textView.frame.size.height {
            let textViewHeight = textView.contentSize.height
            if textViewHeight < 100 {
                messageTextViewHeightConstraint.constant = textViewHeight
                textView.layoutIfNeeded()
            }
        }
        
        sendMessageButton.isEnabled = textView.text.count > 0
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        if message.isOutgoing {
            let cell = tableView.dequeueReusableCell(withIdentifier: "rightMessageCell", for: indexPath) as! ChatRightMessageCell
            cell.contentLabel.text = messages[indexPath.row].content
            cell.avatarImageView.image = #imageLiteral(resourceName: "iv_chat_local")
            if message.status == .sending {
                cell.labelStatus.text = "Sending..."
                cell.labelStatus.textColor = UIColor.gray
            }else if message.status == .sendfail {
                cell.labelStatus.text = "Send fail"
                cell.labelStatus.textColor = UIColor.red
            }else if message.status == .sendSuccess {
                cell.labelStatus.text = "Send success"
                cell.labelStatus.textColor = UIColor.blue
            }else if message.status == .send {
                cell.labelStatus.text = "Send"
                cell.labelStatus.textColor = UIColor.black
            }else {
                cell.labelStatus.isHidden = true
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "leftMessageCell", for: indexPath) as! ChatLeftMessageCell
            cell.contentLabel.text = messages[indexPath.row].content
            cell.avatarImageView.image = #imageLiteral(resourceName: "iv_chat_remote")
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
    }
}
