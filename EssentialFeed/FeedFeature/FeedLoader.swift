//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Max Kai on 2023/1/1.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
