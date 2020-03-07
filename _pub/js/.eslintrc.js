module.exports = {
    "env": {
        "es6": true,
        "node": true
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
	  "no-continue": 0,
      "no-nested-ternary": 0,
	  "no-plusplus": 0,
	  "no-return-assign": 0,
      "object-curly-newline": 0,
    }
};
