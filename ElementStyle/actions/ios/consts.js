/**
 * These are parts of Contents.json files used in iOS assets. They are shared
 * by both colorsets and imagesets so we are defining them here to be shared
 * across both actions that make images and colors.
 * 
 */
const darkAppearance = {
  appearance: "luminosity",
  value: "dark"
};

const idiom = `universal`;

const contents = {
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

module.exports = {
  darkAppearance,
  idiom,
  contents
}