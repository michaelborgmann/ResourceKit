//
//  JSONTests.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 28/08/2025.
//

import Testing
@testable import ResourceKit
import Foundation

struct JSONTests {
    @Test
    func load_success() throws {
        let value: Hello = try JSON.load(name: "hello", in: .module)
        #expect(value == Hello(msg: "hi"))
    }

    @Test
    func decode_failureWrapped() {
        let invalid = Data("{}".utf8)
        do {
            let _: Hello = try JSON.decode(data: invalid)
            Issue.record("Expected ResourceError.jsonDecodingFailed")
        } catch let error as ResourceError {
            if case .jsonDecodingFailed(let underlying) = error {
                #expect(underlying is DecodingError)
            } else {
                Issue.record("Wrong case: \(error)")
            }
        } catch { Issue.record("Unexpected error: \(error)") }
    }
}
