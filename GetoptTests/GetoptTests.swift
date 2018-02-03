//
//  GetoptTests.swift
//  GetoptTests
//
//  Created by Dieter Baron on 2018/02/03.
//  Copyright © 2018 NiH. All rights reserved.
//

import XCTest
@testable import Getopt

class GetoptTests: XCTestCase {
    func testNoOptions() {
        let getopt = Getopt()

        let arguments = ["a", "b"]
        do {
            let result = try getopt.parse(arguments: arguments)

            XCTAssert(result.shortOptions.isEmpty, "shortOptions empty")
            XCTAssert(result.longOptions.isEmpty, "longOptions empty")
            XCTAssertEqual(result.arguments, arguments, "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testShortOption() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", description: "test option")

            let result = try getopt.parse(arguments: ["-a", "b"])

            XCTAssertEqual(result.shortOptions, ["a" : .Set], "shortOptions")
            XCTAssert(result.longOptions.isEmpty, "longOptions empty")
            XCTAssert(result.arguments == ["b"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testMultipleShortOptions() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", description: "test option")
            try getopt.add(shortName: "b", description: "test option")

            let result = try getopt.parse(arguments: ["-ab", "arg1"])

            XCTAssertEqual(result.shortOptions, ["a": .Set, "b": .Set], "shortOptions")
            XCTAssert(result.longOptions.isEmpty, "longOPtions empty")
            XCTAssert(result.arguments == ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUnknownShortOption() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", description: "test option")

            let _ = try getopt.parse(arguments: ["-c", "arg1"])
            XCTFail("no exception")
        }
        catch Getopt.ParseError.IllegalOption(_) {
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testKeepOrder() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", description: "test option")

            let result = try getopt.parse(arguments: ["--", "-a", "arg1"])
            XCTAssert(result.shortOptions.isEmpty, "shortOptions empty")
            XCTAssert(result.longOptions.isEmpty, "longOptions empty")
            XCTAssertEqual(result.arguments, ["-a", "arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testShortOptionalWithArgument() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", argumentType: .Optional, description: "test option")

            let result = try getopt.parse(arguments: ["-aoptarg", "arg1"])

            XCTAssertEqual(result.shortOptions, ["a": .One("optarg")], "shortOptions")
            XCTAssert(result.longOptions.isEmpty, "longOptions empty")
            XCTAssertEqual(result.arguments, ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testShortOptionalNoArgument() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", argumentType: .Optional, description: "test option")

            let result = try getopt.parse(arguments: ["-a", "arg1"])

            XCTAssertEqual(result.shortOptions, ["a": .Set], "shortOptions")
            XCTAssert(result.longOptions.isEmpty, "longOptions empty")
            XCTAssertEqual(result.arguments, ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDefaultArgumentGiven() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", argumentType: .Required, description: "test option", defaultArgument: "default")

            let result = try getopt.parse(arguments: ["-a", "optarg", "arg1"])

            XCTAssertEqual(result.shortOptions, ["a": .One("optarg")], "shortOptions")
            XCTAssert(result.longOptions.isEmpty, "longOptions empty")
            XCTAssertEqual(result.arguments, ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDefaultArgumentAbsent() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", argumentType: .Required, description: "test option", defaultArgument: "default")

            let result = try getopt.parse(arguments: ["arg1"])

            XCTAssertEqual(result.shortOptions, ["a": .One("default")], "shortOptions")
            XCTAssert(result.longOptions.isEmpty, "longOptions empty")
            XCTAssertEqual(result.arguments, ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testMultiple() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", argumentType: .Multiple, description: "test option", defaultArgument: "default")

            let result = try getopt.parse(arguments: ["-a", "one", "-a", "two", "arg1"])

            XCTAssertEqual(result.shortOptions, ["a": .Multiple(["one", "two"])], "shortOptions")
            XCTAssert(result.longOptions.isEmpty, "longOptions empty")
            XCTAssertEqual(result.arguments, ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testMultipleDefault() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", argumentType: .Multiple, description: "test option", defaultArgument: "default")

            let result = try getopt.parse(arguments: ["arg1"])

            XCTAssertEqual(result.shortOptions, ["a": .Multiple(["default"])], "shortOptions")
            XCTAssert(result.longOptions.isEmpty, "longOptions empty")
            XCTAssertEqual(result.arguments, ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testLongOption() {
        do {
            var getopt = Getopt()
            try getopt.add(longName: "aa", description: "test option")

            let result = try getopt.parse(arguments: ["--aa", "b"])

            XCTAssert(result.shortOptions.isEmpty, "shortOptions empty")
            XCTAssertEqual(result.longOptions, ["aa" : .Set], "longOptions")
            XCTAssert(result.arguments == ["b"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testLongOptionRequired() {
        do {
            var getopt = Getopt()
            try getopt.add(longName: "aa", argumentType: .Required, description: "test option")

            let result = try getopt.parse(arguments: ["--aa", "b", "arg1"])

            XCTAssert(result.shortOptions.isEmpty, "shortOptions empty")
            XCTAssertEqual(result.longOptions, ["aa" : .One("b")], "longOptions")
            XCTAssert(result.arguments == ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testLongOptionRequiredEqual() {
        do {
            var getopt = Getopt()
            try getopt.add(longName: "aa", argumentType: .Required, description: "test option")

            let result = try getopt.parse(arguments: ["--aa=b", "arg1"])

            XCTAssert(result.shortOptions.isEmpty, "shortOptions empty")
            XCTAssertEqual(result.longOptions, ["aa" : .One("b")], "longOptions")
            XCTAssert(result.arguments == ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testLongOptionOptionalAbsent() {
        do {
            var getopt = Getopt()
            try getopt.add(longName: "aa", argumentType: .Optional, description: "test option")

            let result = try getopt.parse(arguments: ["--aa", "b", "arg1"])

            XCTAssert(result.shortOptions.isEmpty, "shortOptions empty")
            XCTAssertEqual(result.longOptions, ["aa" : .Set], "longOptions")
            XCTAssert(result.arguments == ["b", "arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testLongOptionOptionalGiven() {
        do {
            var getopt = Getopt()
            try getopt.add(longName: "aa", argumentType: .Optional, description: "test option")

            let result = try getopt.parse(arguments: ["--aa=b", "arg1"])

            XCTAssert(result.shortOptions.isEmpty, "shortOptions empty")
            XCTAssertEqual(result.longOptions, ["aa" : .One("b")], "longOptions")
            XCTAssert(result.arguments == ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testShortAndLong() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", longName: "aa", argumentType: .Required, description: "test option")
            try getopt.add(shortName: "b", longName: "bb", argumentType: .Required, description: "test option")

            let result = try getopt.parse(arguments: ["--aa", "a", "-b", "b", "arg1"])

            XCTAssertEqual(result.shortOptions, ["a" : .One("a"), "b" : .One("b")], "shortOptions")
            XCTAssertEqual(result.longOptions, ["aa" : .One("a"), "bb" : .One("b")], "longOptions")
            XCTAssertEqual(result.arguments, ["arg1"], "arguments")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSubscript() {
        do {
            var getopt = Getopt()
            try getopt.add(shortName: "a", longName: "aa", argumentType: .Required, description: "test option")
            try getopt.add(shortName: "b", longName: "bb", argumentType: .Required, description: "test option")

            let result = try getopt.parse(arguments: ["--aa", "a", "-b", "b", "arg1"])

            XCTAssertEqual(result[Character("a")], .One("a"), "short char")
            XCTAssertEqual(result["a"], .One("a"), "short stsring")
            XCTAssertEqual(result["aa"], .One("a"), "long")
            XCTAssertEqual(result[0], "arg1", "arguments")
            XCTAssertEqual(result.count, 1, "count")
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
}
