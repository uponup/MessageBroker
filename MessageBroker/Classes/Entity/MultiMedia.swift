//
//  MultiMedia.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/11/13.
//

import Foundation

@objc public enum MediaType: Int, RawRepresentable {
    case text = 0
    case image = 1
    case video = 2
    case audio = 3
    case file = 4
    case richtext = 5
    case location = 6
    case invalid = 7
    
    var scheme: String {
        return "\(self.rawValue)://"
    }
    
    public typealias RawValue = String

    public init?(rawValue: RawValue) {
        switch rawValue {
            case "text": self = .text
            case "image": self = .image
            case "video": self = .video
            case "audio": self = .audio
            case "file": self = .file
            case "richtext": self = .richtext
            case "location": self = .location
            case "invalid": self = .invalid
            default: self = .text
        }
    }
    
    public var rawValue: String {
        switch self {
        case .text:
            return "text"
        case .image:
            return "image"
        case .video:
            return "video"
        case .audio:
            return "audio"
        case .file:
            return "file"
        case .richtext:
            return "richtext"
        case .location:
            return "location"
        case .invalid:
            return "invalid"
        }
    }
    
}

public protocol MultiMedia {
    var type: MediaType { get set }
    var content: String { get }
}

@objcMembers public class NormalMedia: NSObject, MultiMedia {
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

@objcMembers public class LocationMedia: NSObject, MultiMedia {
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
