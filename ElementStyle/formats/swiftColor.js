/**
 * This custom format creates an extension of the SwiftUI Color
 * class and adds all the color tokens as static variables so that
 * you can reference a color token like: `Color.backgroundPrimary`. 
 * It will handle dark mode by using the colorsets and references.
 * 
 * @example
 * ```swift
 * Text("Hello, World!")
 *   .backgroundColor(Color.backgroundPrimary)
 *   .foregroundColor(Color.fontPrimary)
 * ```
 */
module.exports = function({ dictionary, options }) {
  return `import SwiftUI

// MARK: SwiftUI

extension Color {
    public static let element = ElementColorsSwiftUI()
}

public struct ElementColorsSwiftUI {\n` +
  dictionary.allProperties.map(token => {
    if (token.attributes.category === `color`) {
      let value;
      // if the token does not have a reference or has a darkValue
      // use the colorset of the same name
      // else use the reference name
      if (options.outputReferences) {
        // if it has a dark value -> use the colorset (all colors with darkValue have a colorset)
        if (token.darkValue) {
          value = `Color("${token.name}", bundle: Bundle.module)`;
        // if it is a reference -> refer to the Color extension name
        } else if (dictionary.usesReference(token.original.value)) {
          const reference = dictionary.getReferences(token.original.value)[0];
          value = `${reference.name}`
        // default to using the colorset
        } else {
          value = `Color("${token.name}", bundle: Bundle.module)`
        }
      } else {
        value = `Color("${token.name}", bundle: Bundle.module)`;
      }
      return `    public var ${token.name}: Color { ${value} }`
    }
  }).join(`\n`) +
  `\n}

// MARK: UIKit

extension UIColor {
    public static let element = ElementColorsUIKit()
}

public struct ElementColorsUIKit {\n` +
dictionary.allProperties.map(token => {
  if (token.attributes.category === `color`) {
    let value;
    // if the token does not have a reference or has a darkValue
    // use the colorset of the same name
    // else use the reference name
    if (options.outputReferences) {
      // if it has a dark value -> use the colorset (all colors with darkValue have a colorset)
      if (token.darkValue) {
        value = `UIColor(named: "${token.name}", in: Bundle.module, compatibleWith: nil)!`;
      // if it is a reference -> refer to the Color extension name
      } else if (dictionary.usesReference(token.original.value)) {
        const reference = dictionary.getReferences(token.original.value)[0];
        value = `${reference.name}`
      // default to using the colorset
      } else {
        value = `UIColor(named: "${token.name}", in: Bundle.module, compatibleWith: nil)!`
      }
    } else {
      value = `UIColor(named: "${token.name}", in: Bundle.module, compatibleWith: nil)!`;
    }
    return `    public var ${token.name}: UIColor { ${value} }`
  }
}).join(`\n`) +
`\n}\n`
}