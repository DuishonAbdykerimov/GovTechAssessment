require("dotenv").config();

const { chromium } = require("@playwright/test");
const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const STORAGE_STATE = path.join(__dirname, ".auth", "state.json");

// The Experience Cloud site can be slow to render the LWC form on a cold
// session, so give authentication a few resilient attempts before failing.
const MAX_ATTEMPTS = 3;
const HEADING_TIMEOUT = 60_000;

/**
 * Ask the Salesforce CLI for a one-time authenticated session URL that lands on
 * the community. The token is single-use, so a fresh URL is fetched per attempt.
 */
function getSessionUrl() {
  const communityPath =
    `/servlet/networks/session/create?url=` +
    `%2F${process.env.SF_COMMUNITY_PATH}%2F` +
    `&site=${process.env.SF_SITE_ID}`;

  const output = execFileSync(
    "sf",
    [
      "org",
      "open",
      "--target-org",
      process.env.SF_TARGET_ORG,
      "--path",
      communityPath,
      "--url-only",
      "--json"
    ],
    { encoding: "utf8" }
  );

  // The CLI can print warnings before the JSON payload, so start at the first brace.
  return JSON.parse(output.slice(output.indexOf("{"))).result.url;
}

module.exports = async () => {
  const browser = await chromium.launch();

  try {
    let lastError;

    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
      const page = await browser.newPage();

      try {
        await page.goto(getSessionUrl(), {
          waitUntil: "domcontentloaded"
        });
        await page
          .getByRole("heading", {
            name: "Financial Support Application"
          })
          .waitFor({ timeout: HEADING_TIMEOUT });

        fs.mkdirSync(path.dirname(STORAGE_STATE), { recursive: true });
        await page.context().storageState({ path: STORAGE_STATE });
        await page.close();
        return;
      } catch (error) {
        lastError = error;
        console.warn(
          `[global-setup] authentication attempt ${attempt}/${MAX_ATTEMPTS} failed: ${error.message}`
        );
        await page.close();
      }
    }

    throw lastError;
  } finally {
    await browser.close();
  }
};

module.exports.STORAGE_STATE = STORAGE_STATE;
