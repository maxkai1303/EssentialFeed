//
//  ValidateFeedCacheUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Max Kai on 2023/3/9.
//

import XCTest
import EssentialFeed

class ValidateFeedCacheUseCaseTest: XCTestCase {
    
    func testInitDoesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func testValidateCacheDeletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func testValidateCacheDoesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func testValidateCacheDoseNotDeleteLessThenSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date.now
        let lessThenSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(second: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: lessThenSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func testValidateCacheDeletesSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date.now
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: sevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func testValidateCacheDeletesMoreThenSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date.now
        let moreThenSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(second: -1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: feed.local, timestamp: moreThenSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    // MARK: - Helper
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackFromMemoryLeak(store, file: file, line: line)
        trackFromMemoryLeak(sut, file: file, line: line)
        
        return (sut, store)
    }
}
