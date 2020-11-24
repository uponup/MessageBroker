//
//  MultiMedia.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/11/13.
//

import Foundation

public enum MediaType: String {
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case file = "file"
    case richtext = "richtext"
    case location = "location"
    case invalid = "invalid"
    
    var scheme: String {
        return "\(self.rawValue)://"
    }
}

public protocol MultiMedia {
    var type: MediaType { get set }
    var content: String { get }
}

public struct NormalMedia: MultiMedia {
    public var type: MediaType
    public var mesg: String
    public var content: String {
        return "\(type.scheme)\(mesg.URLEncoding() ?? "")"
    }
    
    public init(type: MediaType, mesg: String) {
        self.type = type
        self.mesg = mesg
    }
}

public struct LocationMedia: MultiMedia {
    public var type: MediaType
    public var latitude: Double
    public var longitude: Double
    public var content: String {
        return "\(type.scheme)location?latitude=\(latitude)&longitude=\(longitude)"
    }
    
    public init(type: MediaType, latitude: Double, longitude: Double) {
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - 解析消息
/**
    返回元祖（多媒体消息类型，消息内容）
 */
func parseMediaMesg(content: String) -> MultiMedia {
    guard let type = content.components(separatedBy: "://").first, let schema = MediaType(rawValue: type) else {
        return NormalMedia(type: .invalid, mesg: content)
    }
    
    if schema == .location {
        
    }else {
        
    }
//
//    guard let url = URL(string: content), let scheme = url.scheme else {
//        return (MediaType.invalid.rawValue, content)
//    }
//    guard let type = MediaType(rawValue: scheme) else {
//        return (MediaType.invalid.rawValue, content)
//    }
//
//    if type == .location {
//        let msg = url.query.value
//        return (type.rawValue, msg)
//    }else {
//        let msg = url.host.value.URLDecoding() ?? ""
//        return (type.rawValue, msg)
//    }
}
