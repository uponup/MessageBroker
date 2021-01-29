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
    
    private var _myTimer = MyTimer()
    private var _currentTime = Date().timeIntervalSince1970
    
    private var _messages: [ChatMessage]?
    var messages: [ChatMessage] {
        get {
            if _messages == nil {
                guard let passport = MavlMessage.shared.passport else {
                    _messages = []
                    return []
                }
                
                if chatTo == .toContact {
                    _messages = MessageDao.fetchAllMesgs(local: passport.uid, remote: chatToId).map {
                        ChatMessage(status: SendingStatus(rawValue: $0.status)!, mesg: $0)
                    }
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
    
    private var localId: String {
        "\(MessageDao.fetchLastOne() + 1)"
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
        NotificationCenter.default.addObserver(self, selector: #selector(receiveDidChangedUserStatus), name: .userStatusDidChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedMessageStateDidChanged(noti:)), name: .mesgStateDidChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedTransparentMesg(noti:)), name: .didReceiveTransparentMesg, object: nil)
        
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tap.numberOfTapsRequired = 2
        tableView.addGestureRecognizer(tap)
    }
    
    @objc func tapAction() {
        MavlMessage.shared.createSingalCipherChannel(toUid: chatToId) { ret in
            if ret {
                print("Signal准备好了")
            }else {
                print("Signal建立失败")
            }
        }
        print("双击")
        self.tableView.backgroundColor = UIColor.darkGray
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
                
        changeMesgStateToRead()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @IBAction func sendMultiMediaMesgAction(_ sender: Any) {
        let alertVc = UIAlertController(title: "You will send", message: "You can choose from the following types of multimedia messages", preferredStyle: .actionSheet)
        let actionText = UIAlertAction(title: "Text", style: .default) { [unowned self] _ in
            self.sendText()
        }
        
        let actionImage = UIAlertAction(title: "Image", style: .default) { [unowned self] _ in
            self.sendImage()
        }

        let actionVideo = UIAlertAction(title: "Video", style: .default) { [unowned self] _ in
            self.sendVideo()
        }

        let actionAudio = UIAlertAction(title: "Audio", style: .default) { [unowned self] _ in
            self.sendAudio()
        }

        let actionFile = UIAlertAction(title: "File", style: .default) { [unowned self] _ in
            self.sendFile()
        }

        let actionLocation = UIAlertAction(title: "Location", style: .default) { [unowned self] _ in
            self.sendLocation()
        }
        
        let actionInvalid = UIAlertAction(title: "Invalid", style: .default) { [unowned self] _ in
            self.sendInvalid()
        }


        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel) {_ in }

        let actions = [actionText, actionImage, actionAudio, actionVideo, actionFile, actionLocation, actionInvalid, actionCancel]
        for action in actions {
            alertVc.addAction(action)
        }
        
        self.present(alertVc, animated: true, completion: nil)
    }

    @IBAction func sendMessage() {
        guard let message = messageTextView.text else { return }

        if chatTo == .toGroup {
           MavlMessage.shared.send(message: message, toGroup: chatToId, localId: localId)
        }else if chatTo == .toCircle {
           let friends = Set(CirclesDao.fetchAllMembers(fromCircle: chatToId))
           MavlMessage.shared.send(message: message, toGroup: chatToId, localId: localId, withFriends: friends)
        }else {
//           MavlMessage.shared.send(message: message, toFriend: chatToId, localId: localId)
            MavlMessage.shared.sendSignal(message: message, toFriend: chatToId, localId: localId)
        }
        messageTextView.text = ""
        sendMessageButton.isEnabled = false
        messageTextViewHeightConstraint.constant = messageTextView.contentSize.height
        messageTextView.layoutIfNeeded()
        view.endEditing(true)
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
    
    @objc func receivedMessage(notification: NSNotification) {
        let object = notification.object as! [String: Any]
        let isLoadMore = object["isLoadMore"] as! Bool
        
        // 在当前会话框，收到消息的话及时设置为已读
        changeMesgStateToRead()
        
        if isLoadMore {
            tableView.es.stopPullToRefresh()
            scrollToTop()
        }else {
            scrollToBottom()
        }
    }
    
    @objc func receivedMessageStateDidChanged(noti: Notification) {
        _messages = nil
        tableView.reloadData()
    }
    
    func numOfElements(arr: Array<ChatMessage>, localId: String) -> Int {
        var count = 0
        
        for chatmessage in arr {
            if chatmessage.localId == localId {
                count += 1
            }
        }
        return count
    }
    
    @objc func receiveDidChangedUserStatus() {
        if chatTo == .toContact {
            isOnline = StatusQueue.shared.isOnline(withImAccount: chatToId)
        }
    }
    
    @objc func receivedTransparentMesg(noti: Notification) {
        guard let object = noti.object as? [String: String],
            let from = object["from"] else {
            return
        }
        
        sloganLabel.text = "\(from.capitalized) is typing..."
        _myTimer.resetDelay(2) { [weak self] in
            DispatchQueue.main.async {
                self?.sloganLabel.text = self?.slogan
            }
        }
    }
    
    func scrollToBottom(_ animated: Bool = true) {
        guard messages.count > 3 else { return }
        
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    func scrollToTop() {
        guard messages.count > 0 else { return }
        
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    private func changeMesgStateToRead() {
        let allUnreadMesgs = MessageDao.fetchUnreadMesgs(fromGroup: chatToId)
        for message in allUnreadMesgs {
            MessageDao.updateMessage(msgServerId: message.serverId, status: SendingStatus.read.rawValue)
            MavlMessage.shared.readMessage(msgFrom: message.remoteAccount, msgTo: message.localAccount, msgServerId: message.serverId)
        }
        
        _messages = nil
        tableView.reloadData()
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
        
        guard chatTo == .toContact else { return }
        
        if Date().timeIntervalSince1970 - _currentTime > 2 {
            if let err = MavlMessage.shared.sendTransparentMessage(msgTo: chatToId, action: TransparentMesg.inputing) {
                print("透传消息发送失败:\(err.localizedDescription)")
            }
        }
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
            cell.contentLabel.text = "\(message.type) | \(message.content)"
            cell.avatarImageView.image = #imageLiteral(resourceName: "iv_chat_local")
            if message.status == .sending {
                cell.labelStatus.text = "Sending..."
                cell.labelStatus.textColor = UIColor.gray
            }else if message.status == .sendFail {
                cell.labelStatus.text = "Fail"
                cell.labelStatus.textColor = UIColor.red
            }else if message.status == .send {
                cell.labelStatus.text = "Sent"
                cell.labelStatus.textColor = UIColor.blue
            }else if message.status == .received {
                cell.labelStatus.text = "Delivered"
                cell.labelStatus.textColor = UIColor.black
            }else if message.status == .read {
                cell.labelStatus.text = "Read"
                cell.labelStatus.textColor = UIColor.gray
            } else {
                cell.labelStatus.isHidden = true
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "leftMessageCell", for: indexPath) as! ChatLeftMessageCell
            cell.contentLabel.text = "\(message.type) | \(message.content)"
            cell.avatarImageView.image = #imageLiteral(resourceName: "iv_chat_remote")
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
    }
}

// MARK: - 发送多媒体消息
extension ChatViewController {
    func sendText() {
        let media = NormalMedia(type: .text, mesg: "hello file server")
        _send(media)
    }
    
    func sendImage() {
        let url = "https://fs.cocomobi.com/api/v1/file?name=d192c0f8162e38cf588bdc7511488fcd.png"
        let media = NormalMedia(type: .image, mesg: url)
        _send(media)
    }
    
    func sendVideo() {
        let url = "https://fs.cocomobi.com/api/v1/file?name=d192c0f8162e38cf588bdc7511488fcd.mp4"
        let media = NormalMedia(type: .video, mesg: url)
        _send(media)
    }
    
    func sendAudio() {
        let url = "https://fs.cocomobi.com/api/v1/file?name=d192c0f8162e38cf588bdc7511488fcd.wav"
        let media = NormalMedia(type: .audio, mesg: url)
        _send(media)
    }
    
    func sendFile() {
        let url = "https://fs.cocomobi.com/api/v1/file?name=d192c0f8162e38cf588bdc7511488fcd.txt"
        let media = NormalMedia(type: .file, mesg: url)
        _send(media)
    }
    
    func sendLocation() {
        let media = LocationMedia(type: .location, latitude: 117.0, longitude: 38)
        _send(media)
    }
    
    func sendInvalid() {
        let media = NormalMedia(type: .invalid, mesg: "")
        _send(media)
    }
    
    private func _send(_ media: MultiMedia) {
        
        if chatTo == .toContact {
            MavlMessage.shared.send(mediaMessage: media, toFriend: chatToId, localId: localId)
        }else if chatTo == .toGroup {
            MavlMessage.shared.send(mediaMessage: media, toGroup: chatToId, localId: localId, withFriends: [])
        }else {
            let friends = Set(CirclesDao.fetchAllMembers(fromCircle: chatToId))
            MavlMessage.shared.send(mediaMessage: media, toGroup: chatToId, localId: localId, withFriends: friends)
        }
    }
}
