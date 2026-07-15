const base = require('@playwright/test');
const { GrantApplicationPage } = require('../pages/grant-application.page');

/**
 * Extends the base Playwright test with domain-specific fixtures so specs stay
 * declarative: they receive an already-opened `grantApplicationPage` instead of
 * repeating navigation and page-object wiring in every test.
 */
const test = base.test.extend({
    grantApplicationPage: async ({ page }, use) => {
        const grantApplicationPage = new GrantApplicationPage(page);
        await grantApplicationPage.open();
        await use(grantApplicationPage);
    }
});

const expect = base.expect;

module.exports = { test, expect };
