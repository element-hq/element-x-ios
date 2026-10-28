//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A shape drawn from SVG path data (the `d` attribute), scaled from its square view box to the proposed rect.
///
/// Arcs (`A`/`a`) are approximated by a straight line to their end point. The rest of the SVG 1.1 path
/// grammar is supported, including relative commands and implicit command repetition.
nonisolated struct SVGPathShape: Shape {
    let pathData: String
    var viewBoxSize: CGFloat = 24
    
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / viewBoxSize
        let transform = CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: scale, y: scale)
        return SVGPathParser.path(from: pathData).applying(transform)
    }
}

private nonisolated enum SVGPathParser {
    private enum Token {
        case command(Character)
        case number(CGFloat)
    }
    
    /// Tracks the pen between commands, as relative coordinates and smooth curves depend on it.
    private struct State {
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        /// The last control point, reflected by the smooth curve commands.
        var lastControl: CGPoint?
        var lastCommand: Character = " "
    }
    
    static func path(from data: String) -> Path {
        var path = Path()
        var state = State()
        var command: Character?
        var numbers = [CGFloat]()
        
        for token in tokenize(data) {
            switch token {
            case .command(let nextCommand):
                if let command {
                    apply(command, numbers, to: &path, state: &state)
                }
                command = nextCommand
                numbers = []
            case .number(let number):
                numbers.append(number)
            }
        }
        if let command {
            apply(command, numbers, to: &path, state: &state)
        }
        
        return path
    }
    
    /// Runs the command once per complete set of arguments. Extra pairs after a move draw lines, per the spec.
    private static func apply(_ command: Character, _ numbers: [CGFloat], to path: inout Path, state: inout State) {
        guard let arity = arity(of: command) else { return }
        guard arity > 0 else {
            path.closeSubpath()
            state.current = state.subpathStart
            state.lastControl = nil
            state.lastCommand = command
            return
        }
        
        var command = command
        var remaining = numbers[...]
        while remaining.count >= arity {
            let arguments = Array(remaining.prefix(arity))
            remaining = remaining.dropFirst(arity)
            apply(command, arguments: arguments, to: &path, state: &state)
            if command == "M" {
                command = "L"
            } else if command == "m" {
                command = "l"
            }
        }
    }
    
    private static func apply(_ command: Character, arguments: [CGFloat], to path: inout Path, state: inout State) {
        let isRelative = command.isLowercase
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            isRelative ? CGPoint(x: state.current.x + x, y: state.current.y + y) : CGPoint(x: x, y: y)
        }
        func reflectedControl(after commands: String) -> CGPoint {
            guard let lastControl = state.lastControl, commands.contains(state.lastCommand) else { return state.current }
            return CGPoint(x: 2 * state.current.x - lastControl.x, y: 2 * state.current.y - lastControl.y)
        }
        
        var control: CGPoint?
        switch command.uppercased() {
        case "M":
            let destination = point(arguments[0], arguments[1])
            path.move(to: destination)
            state.current = destination
            state.subpathStart = destination
        case "L":
            let destination = point(arguments[0], arguments[1])
            path.addLine(to: destination)
            state.current = destination
        case "H":
            let destination = CGPoint(x: isRelative ? state.current.x + arguments[0] : arguments[0], y: state.current.y)
            path.addLine(to: destination)
            state.current = destination
        case "V":
            let destination = CGPoint(x: state.current.x, y: isRelative ? state.current.y + arguments[0] : arguments[0])
            path.addLine(to: destination)
            state.current = destination
        case "C":
            let control1 = point(arguments[0], arguments[1])
            let control2 = point(arguments[2], arguments[3])
            let destination = point(arguments[4], arguments[5])
            path.addCurve(to: destination, control1: control1, control2: control2)
            state.current = destination
            control = control2
        case "S":
            let control1 = reflectedControl(after: "CcSs")
            let control2 = point(arguments[0], arguments[1])
            let destination = point(arguments[2], arguments[3])
            path.addCurve(to: destination, control1: control1, control2: control2)
            state.current = destination
            control = control2
        case "Q":
            let quadControl = point(arguments[0], arguments[1])
            let destination = point(arguments[2], arguments[3])
            path.addQuadCurve(to: destination, control: quadControl)
            state.current = destination
            control = quadControl
        case "T":
            let quadControl = reflectedControl(after: "QqTt")
            let destination = point(arguments[0], arguments[1])
            path.addQuadCurve(to: destination, control: quadControl)
            state.current = destination
            control = quadControl
        case "A":
            let destination = point(arguments[5], arguments[6])
            path.addLine(to: destination)
            state.current = destination
        default:
            break
        }
        
        state.lastControl = control
        state.lastCommand = command
    }
    
    private static func arity(of command: Character) -> Int? {
        switch command.uppercased() {
        case "M", "L", "T": 2
        case "H", "V": 1
        case "C": 6
        case "S", "Q": 4
        case "A": 7
        case "Z": 0
        default: nil
        }
    }
    
    /// Splits the data into commands and numbers. Numbers may run together (`1.5.5`, `-1-2`) and use exponents.
    private static func tokenize(_ data: String) -> [Token] {
        var tokens = [Token]()
        var number = ""
        var hasDecimalPoint = false
        var hasExponent = false
        
        func endNumber() {
            if let value = Double(number) {
                tokens.append(.number(CGFloat(value)))
            }
            number = ""
            hasDecimalPoint = false
            hasExponent = false
        }
        
        for character in data {
            switch character {
            case "e", "E":
                if number.isEmpty || hasExponent {
                    endNumber()
                } else {
                    number.append(character)
                    hasExponent = true
                }
            case _ where character.isLetter:
                endNumber()
                tokens.append(.command(character))
            case _ where character.isNumber:
                number.append(character)
            case ".":
                if hasDecimalPoint || hasExponent {
                    endNumber()
                }
                number.append(character)
                hasDecimalPoint = true
            case "-", "+":
                if number.last == "e" || number.last == "E" {
                    number.append(character)
                } else {
                    endNumber()
                    number.append(character)
                }
            default:
                endNumber()
            }
        }
        endNumber()
        
        return tokens
    }
}
