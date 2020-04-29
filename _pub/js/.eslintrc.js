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
		"no-multiple-empty-lines": ["error", { "max": 1, "maxEOF": 1 }],
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
		"prefer-const": ["error", { "destructuring": "all" }],
		"prefer-template": "off",
		"semi": ["error", "always", { "omitLastInOneLineBlock": true }],
		"space-unary-ops": ["error", { "overrides": { "!": true } }],
		"space-infix-ops": "off",
  }
};
