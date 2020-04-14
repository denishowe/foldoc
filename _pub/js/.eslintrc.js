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
		"arrow-parens": ["error", "as-needed"],
		"indent": ["error", "tab"],
		"max-classes-per-file": "off",
		"no-console": "off",
	  "no-continue": "off",
		"no-extend-native": "off",
		"no-mixed-operators": "off",
		"no-multi-assign": "off",
    "no-nested-ternary": "off",
		"no-param-reassign": "off",
	  "no-plusplus": "off",
		"no-tabs": "off",
	  "no-return-assign": "off",
		"no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
		"no-use-before-define": "off",
    "object-curly-newline": "off",
		"one-var": "off",
		"one-var-declaration-per-line": "off",
		"semi": ["error", "always", { "omitLastInOneLineBlock": true}],
  }
};
