//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Max Kai on 2023/1/1.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {
    
    func testInitDoesNotRequestDataFromURL() {
        let (_, client)  = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func testLoadRequestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func testLoadTwiceRequestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func testLoadDeliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithError: .connectivity) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func testLoadDeliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithError: .invalidData) {
                client.complete(withStatusCode: code, at: index)
            }
        }
    }
    
    func testLoadDeliversErrorOn200HTTPResponsWithInvalidJSON() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWithError: .invalidData) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func testLoadDeliversNoItemsOn200HTTPResponseWithEmptyList() {
        let (sut, client) = makeSUT()
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        let emptyListJSON = Data("{\"items\": []}".utf8)
        client.complete(withStatusCode: 200, data: emptyListJSON)
        
        XCTAssertEqual(capturedResults, [.success([])])
    }
    
    //MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        return(sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [.failure(error)], file: file, line: line)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var message = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            return message.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            message.append((url, completion))
        }
        
        func complete(with error: Error, index: Int = 0) {
            message[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            
            message[index].completion(.success(data, response))
        }
    }
}

