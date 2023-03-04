//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Max Kai on 2023/1/1.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
