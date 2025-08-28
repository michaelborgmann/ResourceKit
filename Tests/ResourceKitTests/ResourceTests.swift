//
//  ResourceTests.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 28/08/2025.
//

import Testing
@testable import ResourceKit
import Foundation

struct ResourceTests {
    @Test
    func urlAndData_success() throws {
        let url = try Resource.url(name: "hello", ext: "json", in: .module)
        let data = try Resource.data(for: url)
        let value: Hello = try JSON.decode(data: data)
        #expect(value == Hello(msg: "hi"))
    }

    @Test
    func url_notFound() {
        do {
            _ = try Resource.url(name: "nope", ext: "json", in: .module)
            Issue.record("Expected ResourceError.resourceNotFound")
        } catch let error as ResourceError {
            switch error {
            case .resourceNotFound(let name, let ext):
                #expect(name == "nope"); #expect(ext == "json")
            default:
                Issue.record("Wrong case: \(error)")
            }
        } catch { Issue.record("Unexpected error: \(error)") }
    }

    @Test
    func data_loadingFailed() {
        let bogus = URL(fileURLWithPath: "/definitely/not/here/ghost.json")
        do {
            _ = try Resource.data(for: bogus)
            Issue.record("Expected ResourceError.dataLoadingFailed")
        } catch let error as ResourceError {
            if case .dataLoadingFailed(let url, _) = error { #expect(url == bogus) }
            else { Issue.record("Wrong case: \(error)") }
        } catch { Issue.record("Unexpected error: \(error)") }
    }
}
