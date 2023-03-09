//
//  FeedCacheTestHelper.swift
//  EssentialFeedTests
//
//  Created by Max Kai on 2023/3/9.
//

import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
}

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let local = models.map { LocalFeedImage(id: $0.id,
                                            description: $0.description,
                                            location: $0.location,
                                            url: $0.url) }
    return (models, local)
}

extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(second: TimeInterval) -> Date {
        return self + second
    }
}

