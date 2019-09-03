//
//  Set+PubNubTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@testable import PubNub
import XCTest

final class SetPubNubTests: XCTestCase {
  func testAllObjects() {
    let set = Set(["one", "two", "three"])

    XCTAssertEqual(set.allObjects, Array(set))
  }

  func testUpdateContents() {
    let compare = Set(["one", "two", "three", "four", "five"])
    var set = Set(["one", "two", "three"])

    let updated = set.update(with: ["three", "four", "five"])

    XCTAssertEqual(set, compare)
    XCTAssertEqual(updated, ["three"])
  }

  func testRemoveContents() {
    let compare = Set(["one", "two"])
    var set = Set(["one", "two", "three"])

    let removed = set.remove(contentsOf: ["three", "four"])

    XCTAssertEqual(set, compare)
    XCTAssertEqual(removed, ["three"])
  }
}