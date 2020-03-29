module.exports = {
	"plugins": ["html"],
  "env": {
    "es6": true,
    "node": true,
		"browser": true,
  },
  "extends": "airbnb-base",
  "globals": {
    "Atomics": "readonly",
    "SharedArrayBuffer": "readonly"
  },
  "parserOptions": {
    "ecmaVersion": 2018,
    "sourceType": "module"
  },
  "rules": {
		"indent": ["error", "tab"],
		"no-console": "off",
	  "no-continue": "off",
		"no-extend-native": "off",
		"no-multi-assign": "off",
    "no-nested-ternary": "off",
	  "no-plusplus": "off",
		"no-tabs": "off",
	  "no-return-assign": "off",
		"no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
		"no-use-before-define": "off",
    "object-curly-newline": "off",
		"semi": ["error", "always", { "omitLastInOneLineBlock": true}],
  }
};
