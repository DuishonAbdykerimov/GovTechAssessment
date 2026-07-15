const {
  epic,
  feature,
  story,
  severity,
  owner,
  tags,
  Severity
} = require("allure-js-commons");

const { test, expect } = require("../fixtures/portal.fixtures");

/**
 * Visual regression for the public grant application form.
 *
 * Pinned to a single engine (the `visual` project) so baselines stay stable.
 * We snapshot the form container rather than the full page to avoid noise from
 * the surrounding Experience Cloud chrome, disable animations, and allow a tiny
 * pixel tolerance to absorb sub-pixel font rendering differences.
 */
test.describe("Visual regression", () => {
  test.beforeEach(async () => {
    await epic("Agency X Grant Portal");
    await feature("Visual Regression");
    await owner("QA Automation");
  });

  test("grant application form matches the visual baseline", async ({
    grantApplicationPage
  }) => {
    await story("Pristine application form matches its approved baseline");
    await severity(Severity.NORMAL);
    await tags("visual", "ui");

    await expect(grantApplicationPage.formContainer).toBeVisible();

    await expect(grantApplicationPage.formContainer).toHaveScreenshot(
      "grant-application-form.png",
      {
        animations: "disabled",
        maxDiffPixelRatio: 0.02
      }
    );
  });
});
