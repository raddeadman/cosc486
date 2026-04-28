module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files.
    "/generated/**/*", // Ignore generated files.
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  rules: {
    "quotes": 'off', // Disable quote style rules
    "import/no-unresolved": 0,
    "indent": ["error", 2],
    'linebreak-style': 'off', // Allow CRLF on Windows
    'valid-jsdoc': 'off', // Disable JSDoc requirements
    'arrow-parens': 'off', // Allow arrow functions without parens
    'max-len': ['error', { 'code': 1200 }], // Increase max line length
    'object-curly-spacing': 'off', // Disable spacing rules for object literals
    'indent': 'off', // Disable indentation rules
  },
};
