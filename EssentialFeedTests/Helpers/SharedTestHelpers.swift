//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Max Kai on 2023/3/9.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 1)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}
