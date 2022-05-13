const StyleDictionary = require('style-dictionary');
const fs = require('fs-extra');

const iosPath = `../DesignKit/StyleDictionary/`;

// before this runs we should clean the directories we are generating files in
// to make sure they are ✨clean✨
console.log(`cleaning ${iosPath}...`);
fs.removeSync(iosPath);

/**
 * This function will wrap a built-in format and replace `.value` with `.darkValue`
 * if a token has a `.darkValue`.
 * @param {String} format - the name of the built-in format
 * @returns {Function}
 */
function darkFormatWrapper(format) {
  return function(args) {
    const dictionary = Object.assign({}, args.dictionary);
    // Override each token's `value` with `darkValue`
    dictionary.allProperties = dictionary.allProperties.map(token => {
      const {darkValue} = token;
      if (darkValue) {
        return Object.assign({}, token, {
          value: token.darkValue
        });
      } else {
        return token;
      }
    });
    
    // Use the built-in format but with our customized dictionary object
    // so it will output the darkValue instead of the value
    return StyleDictionary.format[format]({ ...args, dictionary })
  }
}

StyleDictionary.extend({
  // custom actions
  action: {
    generateColorsets: require('./actions/ios/colorsets')
  },
  // custom transforms
  transform: {
    'attribute/cti': require('./transforms/attributeCTI'),
    'colorRGB': require('./transforms/colorRGB'),
    'size/remToFloat': require('./transforms/remToFloat')
  },
  // custom formats
  format: {
    swiftColor: require('./formats/swiftColor')
  },
  
  source: [
    `tokens/**/*.json`
  ],
  
  platforms: {
    iosColors: {
      buildPath: iosPath,
      transforms: [`attribute/cti`,`colorRGB`,`name/ti/camel`],
      actions: [`generateColorsets`]
    },
    
    iOS: {
      buildPath: iosPath,
      transforms: [`attribute/cti`,`name/ti/camel`,`size/swift/remToCGFloat`],
      files: [{
        destination: `ElementColors.swift`,
        format: `swiftColor`,
        filter: (token) => token.attributes.category === `color`,
        options: {
          outputReferences: true
        }
      }]
    }
  }
}).buildAllPlatforms();