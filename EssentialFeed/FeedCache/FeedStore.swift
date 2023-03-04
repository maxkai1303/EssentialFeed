//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Max Kai on 2023/3/4.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletions = (Error?) -> Void
    typealias InsertionCompletions = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletions)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletions)
}
