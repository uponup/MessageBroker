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
