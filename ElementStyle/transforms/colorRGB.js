const Color = require('tinycolor2');

module.exports = {
  type: `value`,
  matcher: (token) => token.attributes.category === `color`,
  transformer: (token) => {
    const { r,g,b,a } = Color(token.value).toRgb();
    return {
      alpha: a.toFixed(4),
      blue: (b/255).toFixed(4),
      red: (r/255).toFixed(4),
      green: (g/255).toFixed(4)
    }
  }
}