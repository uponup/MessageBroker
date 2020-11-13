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
}

public struct LocationMedia: MultiMedia {
    public var type: MediaType
    public var latitude: Double
    public var longitude: Double
    public var content: String {
        return "\(type.scheme)location?lantitude=\(latitude)&longitude=\(longitude)"
    }
}

// MARK: - 解析消息
/**
    返回元祖（多媒体消息类型，消息内容）
 */
func parseMediaMesg(content: String) -> (String, String)? {
    guard let url = URL(string: content), let scheme = url.scheme else { return nil }
    guard let type = MediaType(rawValue: scheme) else {
        return (MediaType.invalid.rawValue, content)
    }
    let msg = (url.host ?? "").URLDecoding() ?? ""
    return (type.rawValue, msg)
}
