const AxeBuilder = require("@axe-core/playwright").default;

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
 * Automated accessibility (WCAG 2.1 A/AA) audit of the public grant
 * application form. A government service must be usable by everyone, so we
 * gate the pipeline on critical/serious violations and attach the full axe
 * report to Allure for triage of the remaining (lower-impact) findings.
 */
test.describe("Accessibility", () => {
  test.beforeEach(async () => {
    await epic("Agency X Grant Portal");
    await feature("Accessibility");
    await owner("QA Automation");
  });

  test("grant application form meets WCAG 2.1 A/AA (no critical/serious issues)", async ({
    grantApplicationPage,
    page
  }, testInfo) => {
    await story("Automated WCAG scan of the public application form");
    await severity(Severity.CRITICAL);
    await tags("a11y", "wcag");

    await expect(grantApplicationPage.heading).toBeVisible();

    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
      .analyze();

    await testInfo.attach("axe-results.json", {
      body: JSON.stringify(results.violations, null, 2),
      contentType: "application/json"
    });

    const blocking = results.violations.filter((violation) =>
      ["critical", "serious"].includes(violation.impact)
    );

    const summary = blocking
      .map((violation) => `${violation.id} (${violation.impact})`)
      .join(", ");

    expect(
      blocking,
      `Blocking accessibility violations found: ${summary}`
    ).toEqual([]);
  });
});
