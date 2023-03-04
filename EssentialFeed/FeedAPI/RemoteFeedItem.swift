//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Max Kai on 2023/3/4.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
