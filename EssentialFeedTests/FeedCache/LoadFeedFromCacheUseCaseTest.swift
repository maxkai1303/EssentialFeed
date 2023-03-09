//
//  LoadFeedFromCacheUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Max Kai on 2023/3/4.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTest: XCTestCase {
    
    func testInitDoesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func testLoadRequestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func testLoadRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        
        expect(sut, toCompletion: .failure(retrievalError), when: {
            store.completeRetrieval(with: retrievalError)
        })
    }
    
    func testLoadDeliversNoImageOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompletion: .success([]), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }
    
    func testLoadDeliversCachedImagesOnLessThenSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date.now
        let lessThenSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(second: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut, toCompletion: .success(feed.models), when: {
            store.completeRetrieval(with: feed.local, timestamp: lessThenSevenDaysOldTimestamp)
        })
    }
    
    func testLoadDeliversNoImagesOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date.now
        let moreThenSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(second: -1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut, toCompletion: .success([]), when: {
            store.completeRetrieval(with: feed.local, timestamp: moreThenSevenDaysOldTimestamp)
        })
    }
    
    func testLoadDeliversNoImagesOnMoreThenSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date.now
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompletion: .success([]), when: {
            store.completeRetrieval(with: feed.local, timestamp: sevenDaysOldTimestamp)
        })
    }
    
    func testLoadHasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func testLoadDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func testLoadDoseNotDeleteCacheOnLessThenSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date.now
        let lessThenSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(second: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: lessThenSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func testLoadDeletesCacheOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date.now
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: sevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func testLoadDeletesCacheOnMoreThenSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date.now
        let moreThenSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(second: -1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: moreThenSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func testLoadDoesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }
        
        sut = nil
        store.completeRetrievalWithEmptyCache()
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: - Helper
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackFromMemoryLeak(store, file: file, line: line)
        trackFromMemoryLeak(sut, file: file, line: line)
        
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompletion expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { receivedResult  in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImage), .success(expectedImage)):
                XCTAssertEqual(receivedImage, expectedImage, file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let models = [uniqueImage(), uniqueImage()]
        let local = models.map { LocalFeedImage(id: $0.id,
                                                description: $0.description,
                                                location: $0.location,
                                                url: $0.url) }
        return (models, local)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }
    
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(second: TimeInterval) -> Date {
        return self + second
    }
}
