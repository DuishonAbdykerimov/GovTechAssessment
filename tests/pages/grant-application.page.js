const { expect } = require("@playwright/test");

/**
 * Page Object for the public Grant Application form (LWC `grantApplicationForm`)
 * rendered on the Agency X Experience Cloud site.
 *
 * All locators are role/label based so the tests stay resilient to markup
 * changes and mirror how a real applicant perceives the page.
 */
class GrantApplicationPage {
  constructor(page) {
    this.page = page;

    // The LWC host element wraps the whole form; used as the visual-regression target.
    this.formContainer = page.locator("c-grant-application-form");
    this.heading = page.getByRole("heading", {
      name: "Financial Support Application"
    });
    this.firstName = page.getByLabel("First Name");
    this.lastName = page.getByLabel("Last Name");
    this.phone = page.getByRole("textbox", { name: /Phone/, exact: true });
    this.postalCode = page.getByRole("textbox", {
      name: /Postal Code/,
      exact: true
    });
    this.monthlyIncome = page.getByRole("spinbutton", {
      name: "Monthly Income (SGD)"
    });
    this.supportOption = page.getByRole("combobox", {
      name: /Support (Programme|Option)/
    });
    this.submitButton = page.getByRole("button", {
      name: "Submit Application"
    });
    this.successMessage = page.getByText(/submitted successfully/i);
  }

  async open() {
    // Authentication is established once in global-setup and shared via storageState.
    await this.page.goto("/");
    await expect(this.heading).toBeVisible();
  }

  async fillForm(applicant) {
    await this.firstName.fill(applicant.firstName);
    await this.lastName.fill(applicant.lastName);
    await this.phone.fill(applicant.phone);
    await this.postalCode.fill(applicant.postalCode);
    await this.monthlyIncome.fill(applicant.monthlyIncome);
    await this.selectSupportOption(applicant.supportOption);
  }

  async selectSupportOption(optionName) {
    await this.supportOption.click();
    await this.page
      .getByRole("option", { name: new RegExp(optionName) })
      .click();
  }

  async submit() {
    await this.submitButton.click();
  }

  async submitApplication(applicant) {
    await this.fillForm(applicant);
    await this.submit();
  }

  /** Locator for an inline/toast message containing the given text. */
  message(text) {
    return this.page.getByText(text);
  }
}

module.exports = { GrantApplicationPage };
