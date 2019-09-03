//
//  RequestOperator.swift
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

import Foundation

// MARK: - RequestMutator

public protocol RequestMutator {
  func mutate(
    _ urlRequest: URLRequest,
    for session: Session,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  )
}

// MARK: - Retry

public enum RetryResult {
  case retry
  case retryWithDelay(TimeInterval)
  case doNotRetry
  case doNotRetryWithError(Error)
}

extension RetryResult {
  var isRequired: Bool {
    switch self {
    case .retry, .retryWithDelay:
      return true
    default:
      return false
    }
  }

  var delay: TimeInterval? {
    switch self {
    case let .retryWithDelay(delay):
      return delay
    default:
      return nil
    }
  }

  var error: Error? {
    guard case let .doNotRetryWithError(error) = self else { return nil }
    return error
  }
}

public protocol RequestRetrier {
  func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void)
}

// MARK: - Operator

public protocol RequestOperator: RequestMutator, RequestRetrier {}

extension RequestOperator {
  public func mutate(
    _ urlRequest: URLRequest,
    for _: Session,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    completion(.success(urlRequest))
  }

  public func retry(
    _: Request,
    for _: Session,
    dueTo _: Error,
    completion: @escaping (RetryResult) -> Void
  ) {
    completion(.doNotRetry)
  }

  public func merge(operators: [RequestOperator]) -> RequestOperator {
    var mergedOperators: [RequestOperator] = [self]
    mergedOperators.append(contentsOf: operators)
    return MultiplexRequestOperator(operators: mergedOperators)
  }

  public func merge(requestOperator: RequestOperator?) -> RequestOperator {
    if let requestOperator = requestOperator {
      return merge(operators: [requestOperator])
    }
    return self
  }
}

// MARK: - Multiplexor Operator

public struct MultiplexRequestOperator: RequestOperator {
  public let operators: [RequestOperator]

  public init(requestOperator: RequestOperator? = nil) {
    if let requestOperator = requestOperator {
      self.init(operators: [requestOperator])
    } else {
      self.init(operators: [])
    }
  }

  public init(operators: [RequestOperator] = []) {
    var flatOperators = [RequestOperator]()
    // Flatten out any nested multiplex operators
    operators.forEach { requestOperator in
      if let multiplex = requestOperator as? MultiplexRequestOperator {
        flatOperators.append(contentsOf: multiplex.operators)
      } else {
        flatOperators.append(requestOperator)
      }
    }
    self.operators = operators
  }

  public func mutate(
    _ urlRequest: URLRequest,
    for session: Session,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    mutate(urlRequest, for: session, using: operators, completion: completion)
  }

  private func mutate(
    _ urlRequest: URLRequest,
    for session: Session,
    using mutators: [RequestOperator],
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    var pendingMutators = mutators

    guard !pendingMutators.isEmpty else {
      completion(.success(urlRequest))
      return
    }

    let mutator = pendingMutators.removeFirst()

    mutator.mutate(urlRequest, for: session) { result in
      switch result {
      case let .success(urlRequest):
        self.mutate(urlRequest, for: session, using: pendingMutators, completion: completion)
      case .failure:
        completion(result)
      }
    }
  }

  public func retry(
    _ request: Request,
    for session: Session,
    dueTo error: Error,
    completion: @escaping (RetryResult) -> Void
  ) {
    retry(request, for: session, dueTo: error, using: operators, completion: completion)
  }

  private func retry(
    _ request: Request,
    for session: Session,
    dueTo error: Error,
    using retriers: [RequestOperator],
    completion: @escaping (RetryResult) -> Void
  ) {
    var pendingRetriers = retriers

    guard !pendingRetriers.isEmpty else {
      completion(.doNotRetry)
      return
    }

    let retrier = pendingRetriers.removeFirst()

    retrier.retry(request, for: session, dueTo: error) { result in
      switch result {
      case .retry, .retryWithDelay, .doNotRetryWithError:
        completion(result)
      case .doNotRetry:
        // Only continue to the next retrier if retry was not triggered and no error was encountered
        self.retry(request, for: session, dueTo: error, using: pendingRetriers, completion: completion)
      }
    }
  }
}