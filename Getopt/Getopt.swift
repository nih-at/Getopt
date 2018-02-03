/*
 GetOpt.swift -- command line options parsing for Swift
 Copyright (C) 2018 Dieter Baron

 The author can be contacted at <dillo@nih.at>

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 3. The name of the author may not be used to endorse or promote
 products derived from this software without specific prior
 written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
 OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

public struct Getopt {
    enum OptionError: Error {
        case NoName
        case Duplicate(String)
        case TypeNoneDefaultArgument(String)

        var localizedDescription: String {
            switch self {
            case .NoName:
                return "option has no name"
            case .Duplicate(let name):
                return "duplicate option \(name)"
            case .TypeNoneDefaultArgument(let name):
                return "defaultArgument for option \(name) with type None"
            }
        }
    }

    enum ParseError: Error {
        case ExtraneousArgument(String)
        case MissingArgument(String)
        case IllegalOption(String)

        var localizedDescription: String {
            switch self {
            case .ExtraneousArgument(let option):
                return "\(option) takes no argument"
            case .MissingArgument(let option):
                return "missing argument for \(option)"
            case .IllegalOption(let name):
                return "illegal option \(name)"
            }
        }
    }

    enum ArgumentType {
        case None
        case Optional
        case Required
        case Multiple
    }

    fileprivate struct Option: Comparable {
        var shortName: Character?
        var longName: String?
        var argumentType: ArgumentType
        var description: String
        var argumentName: String?
        var defaultArgument: String?

        var name: String {
            if let shortName = shortName {
                return String(shortName)
            }
            return longName ?? ""
        }

        static func <(lhs: Getopt.Option, rhs: Getopt.Option) -> Bool {
            return lhs.name < rhs.name
        }

        static func ==(lhs: Getopt.Option, rhs: Getopt.Option) -> Bool {
            return lhs.name == rhs.name
        }
    }

    enum Argument: Equatable {
        case Set
        case One(String)
        case Multiple([String])

        static func ==(lhs: Getopt.Argument, rhs: Getopt.Argument) -> Bool {
            switch lhs {
            case .Set:
                if case .Set = rhs {
                    return true
                }
                else {
                    return false
                }
            case .One(let a):
                if case .One(let b) = rhs {
                    return a == b
                }
                return false
            case .Multiple(let a):
                if case .Multiple(let b) = rhs {
                    return a == b
                }
                else {
                    return false
                }
            }
        }
    }

    struct ParseResult { // TODO: better name
        var arguments = [String]()
        var shortOptions = [Character : Argument]()
        var longOptions = [String : Argument]()

        subscript(shortName: Character) -> Argument? {
            return shortOptions[shortName]
        }
        subscript(name: String) -> Argument? {
            if name.count == 1, let first = name.first, let shortArgument = shortOptions[first] {
                return shortArgument
            }
            return longOptions[name]
        }
        subscript(index: Int) -> String {
            return arguments[index]
        }
        var count: Int {
            return arguments.count
        }

        fileprivate mutating func add(argument value: String?, for option: Option, name optionName: String) throws {
            var argument: Argument?

            if let shortName = option.shortName {
                argument = shortOptions[shortName]
            }
            else if let longName = option.longName {
                argument = longOptions[longName]
            }

            switch option.argumentType {
            case .None:
                argument = .Set
            case .Optional:
                if let value = value {
                    argument = .One(value)
                }
                else {
                    argument = .Set
                }
            case .Required:
                guard let value = value else { throw ParseError.MissingArgument(optionName) }
                argument = .One(value)
            case .Multiple:
                guard let value = value else { throw ParseError.MissingArgument(optionName) }
                if case var .Multiple(previousValue)? = argument {
                    previousValue.append(value)
                    argument = .Multiple(previousValue)
                }
                else {
                    argument = .Multiple([value])
                }
            }

            if let shortName = option.shortName {
                shortOptions[shortName] = argument
            }
            if let longName = option.longName {
                longOptions[longName] = argument
            }
        }
    }

    var programName: String?
    var argumentsDescription: String?
    var helpHeader: String?
    var helpFooter: String?

    mutating func add(shortName: Character? = nil, longName: String? = nil, argumentType: ArgumentType = .None, description: String, argumentName: String? = nil, defaultArgument: String? = nil) throws {
        if (shortName == nil && longName == nil) {
            throw OptionError.NoName
        }

        if let shortName = shortName {
            if (shortOptions[shortName] != nil) {
                throw OptionError.Duplicate(String(shortName))
            }
        }
        if let longName = longName {
            if (longOptions[longName] != nil) {
                throw OptionError.Duplicate(longName)
            }
        }

        let option = Option(shortName: shortName, longName: longName, argumentType: argumentType, description: description, argumentName: argumentName, defaultArgument: defaultArgument)

        if(argumentType == .None && defaultArgument != nil) {
            throw OptionError.TypeNoneDefaultArgument(option.name)
        }

        if let shortName = shortName {
            shortOptions[shortName] = option
        }
        if let longName = longName {
            longOptions[longName] = option
        }
        options.append(option)
    }

    func usage() -> String {
        var usage = "Usage: " + (programName ?? CommandLine.arguments[0])
        if (shortOptions.count > 0 || longOptions.count > 0) {
            usage += " [options]"
        }
        if let argumentsDescription = argumentsDescription {
            usage += " " + argumentsDescription
        }
        if let helpHeader = helpHeader {
            usage += "\n" + helpHeader + "\n"
        }

        for option in options.sorted() {
            if let shortName = option.shortName {
                usage += optionUsage(name: "-" + String(shortName), option: option)
            }
            if let longName = option.longName {
                usage += optionUsage(name: "--" + longName, option: option)
            }
            usage += "          " + option.description
            if let defaultArgument = option.defaultArgument {
                usage += " (default: \(defaultArgument))"
            }
            usage += "\n"
        }

        if let helpFooter = helpFooter {
            usage += "\n" + helpFooter + "\n"
        }

        return usage
    }

    func parse(arguments: [String]) throws -> ParseResult {
        var result = ParseResult()

        enum State {
            case Start
            case OptionArgument(Option, String)
            case Arguments
        }
        var state = State.Start
        let equal = CharacterSet(charactersIn: "=")

        for argument in arguments {
            switch state {
            case .Start:
                if argument.first == "-" {
                    var index = argument.index(argument.startIndex, offsetBy: 1)
                    if (index == argument.endIndex) { // "-"
                        state = .Arguments
                        result.arguments.append(argument)
                        continue
                    }

                    let second = argument[index]

                    if (second == "-") { // "--"
                        index = argument.index(after: index)
                        if (index == argument.endIndex) {
                            state = .Arguments
                            continue
                        }

                        if let range = argument.rangeOfCharacter(from: equal, options: [], range: Range(index ..< argument.endIndex)) {
                            let longName = String(argument[index ..< range.lowerBound])
                            let optionName = "--\(longName)"
                            guard let option = longOptions[longName] else { throw ParseError.IllegalOption(optionName) }

                            if option.argumentType == .None {
                                throw ParseError.ExtraneousArgument(optionName)
                            }
                            try result.add(argument: String(argument[range.upperBound ..< argument.endIndex]), for: option, name: optionName)
                        }
                        else {
                            let longName = String(argument[index ..< argument.endIndex])
                            let optionName = "--\(longName)"
                            guard let option = longOptions[longName] else { throw ParseError.IllegalOption(optionName) }

                            switch option.argumentType {
                            case .None, .Optional:
                                try result.add(argument: nil, for: option, name: optionName)
                            case .Multiple, .Required:
                                state = .OptionArgument(option, optionName)
                            }
                        }
                    }
                    else {
                        while (index != argument.endIndex) {
                            let shortName = argument[index]
                            let optionName = "-\(shortName)"
                            guard let option = shortOptions[shortName] else { throw ParseError.IllegalOption(optionName)}
                            index = argument.index(after: index)

                            if option.argumentType == .None {
                                try result.add(argument: nil, for: option, name: optionName)
                            }
                            else if index == argument.endIndex {
                                if option.argumentType == .Optional {
                                    try result.add(argument: nil, for: option, name: optionName)
                                }
                                else {
                                    state = .OptionArgument(option, optionName)
                                }
                            }
                            else {
                                let value = String(argument[index ..< argument.endIndex])
                                try result.add(argument: value, for: option, name: optionName)
                                break
                            }
                        }
                    }
                }
                else {
                    state = .Arguments
                    result.arguments.append(argument)
                }
            case .OptionArgument(let option, let optionName):
                try result.add(argument: argument, for: option, name: optionName)
                state = .Start
            case .Arguments:
                result.arguments.append(argument)
            }
        }

        for option in options {
            if let defaultArgument = option.defaultArgument {
                let argument: Argument?
                switch option.argumentType {
                case .None:
                    argument = nil
                case .Optional, .Required:
                    argument = .One(defaultArgument)
                case .Multiple:
                    argument = .Multiple([defaultArgument])
                }
                if let shortName = option.shortName, result.shortOptions[shortName] == nil {
                    result.shortOptions[shortName] = argument
                }
                if let longName = option.longName, result.longOptions[longName] == nil {
                    result.longOptions[longName] = argument
                }
            }
        }

        return result
    }

    private var options = [Option]()
    private var shortOptions = [Character : Option]()
    private var longOptions = [String : Option]()

    private func optionUsage(name: String, option: Option) -> String {
        var usage = "  " + name
        if let argumentName = option.argumentName {
            usage += " " + argumentName
        }
        usage += "\n"

        return usage
    }
}
