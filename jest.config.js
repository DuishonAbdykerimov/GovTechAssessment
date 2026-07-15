const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...jestConfig,
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver"],
  // Keep Jest focused on LWC unit tests; the Playwright E2E specs under
  // tests/ use *.spec.js which Jest's default testMatch would otherwise pick up.
  testPathIgnorePatterns: ["<rootDir>/node_modules/", "<rootDir>/tests/"]
};
