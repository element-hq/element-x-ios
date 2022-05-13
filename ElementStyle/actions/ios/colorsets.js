const fs = require('fs-extra');
const { contents, idiom, darkAppearance } = require('./consts');

/**
 * This action will iterate over all the colors in the Style Dictionary
 * and for each one write a colorset.
 */
module.exports = {
  do: (dictionary, platform) => {
    const assetPath = `${platform.buildPath}/StyleDictionary.xcassets`;
    fs.ensureDirSync(assetPath)
    fs.writeFileSync(`${assetPath}/Contents.json`, JSON.stringify(contents, null, 2));
    
    dictionary.allProperties
      .filter(token => token.attributes.category === `color` &&
        (!dictionary.usesReference(token.original.value) || token.darkValue))
        // we only need colorsets for tokens that have a dark value or
        // are not a reference
      .forEach(token => {
        const colorsetPath = `${assetPath}/${token.name}.colorset`;
        fs.ensureDirSync(colorsetPath);
        
        const colorset = {
          colors: [{
            idiom,
            color: {
              'color-space': `srgb`,
              components: token.value
            }
          }],
          ...contents
        }
        
        if (token.darkValue) {
          colorset.colors.push({
            idiom,
            color: {
              'color-space': `srgb`,
              components: token.darkValue
            },
            appearances: [darkAppearance]
          });
        }
        
        fs.writeFileSync(`${colorsetPath}/Contents.json`, JSON.stringify(colorset, null, 2));
      });
  },
  undo: function(dictionary, platform) {
    // no undo
  }
}