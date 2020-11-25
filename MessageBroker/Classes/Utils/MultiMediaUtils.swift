//
//  MultiMediaUtils.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/11/25.
//

import Foundation

// MARK: - 解析消息
func parseMediaMesg(content: String) -> MultiMedia {
    
    guard let urlEncodeStr = content.URLEncoding(),
        let url = URL(string: urlEncodeStr),
        let scheme = url.scheme,
        let mediaType = MediaType(rawValue: scheme) else {
        return NormalMedia(type: .invalid, mesg: content)
    }
    
    if mediaType == .location {
        guard let query = url.query else {
            return NormalMedia(type: .invalid, mesg: content)
        }
        let locationDict = query.queryParameters()
        return LocationMedia(type: .location, latitude: locationDict["latitude"]!, longitude: locationDict["longitude"]!)
    }else {
        let content = content.replacingOccurrences(of: mediaType.scheme, with: "")
        return NormalMedia(type: mediaType, mesg: content.URLDecoding() ?? "")
    }
}
