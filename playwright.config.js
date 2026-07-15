require("dotenv").config();

const path = require("node:path");
const { defineConfig, devices } = require("@playwright/test");

module.exports = defineConfig({
  testDir: "./tests/e2e",
  globalSetup: require.resolve("./tests/global-setup"),
  timeout: 60_000,
  expect: {
    timeout: 10_000
  },
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ["list"],
    ["html", { outputFolder: "playwright-report", open: "never" }],
    [
      "allure-playwright",
      {
        resultsDir: "allure-results",
        detail: true,
        environmentInfo: {
          project: "Agency X Grant Portal",
          framework: "Playwright",
          node_version: process.version
        }
      }
    ]
  ],
  use: {
    baseURL: process.env.PORTAL_URL,
    storageState: path.join(__dirname, "tests", ".auth", "state.json"),
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure"
  },
  projects: [
    // Functional + accessibility suites run across all three engines.
    {
      name: "chromium",
      testDir: "./tests/e2e",
      use: { ...devices["Desktop Chrome"] }
    },
    {
      name: "firefox",
      testDir: "./tests/e2e",
      use: { ...devices["Desktop Firefox"] }
    },
    {
      name: "webkit",
      testDir: "./tests/e2e",
      use: { ...devices["Desktop Safari"] }
    },
    // Visual regression is pinned to a single engine so baselines stay stable.
    {
      name: "visual",
      testDir: "./tests/visual",
      use: { ...devices["Desktop Chrome"] }
    }
  ]
});
