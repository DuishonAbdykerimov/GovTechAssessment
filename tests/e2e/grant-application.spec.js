const {
    epic,
    feature,
    story,
    severity,
    owner,
    tags,
    Severity
} = require('allure-js-commons');

const { test, expect } = require('../fixtures/portal.fixtures');
const {
    eligibleApplicant,
    notEligibleApplicant,
    buildApplicant,
    SUPPORT_OPTIONS
} = require('../data/applicants');

async function attachScreenshot(page, testInfo, name) {
    await testInfo.attach(name, {
        body: await page.screenshot({ fullPage: true }),
        contentType: 'image/png'
    });
}

test.describe('Grant Application Portal', () => {
    test.beforeEach(async () => {
        await epic('Agency X Grant Portal');
        await feature('Grant Application Submission');
        await owner('QA Automation');
    });

    test('displays the application form with all required fields', async ({
        grantApplicationPage,
        page
    }, testInfo) => {
        await story('Applicant opens the public application form');
        await severity(Severity.CRITICAL);
        await tags('smoke', 'ui');

        await test.step('All key form controls are visible', async () => {
            await expect(grantApplicationPage.heading).toBeVisible();
            await expect(grantApplicationPage.firstName).toBeVisible();
            await expect(grantApplicationPage.lastName).toBeVisible();
            await expect(grantApplicationPage.phone).toBeVisible();
            await expect(grantApplicationPage.postalCode).toBeVisible();
            await expect(grantApplicationPage.monthlyIncome).toBeVisible();
            await expect(grantApplicationPage.supportOption).toBeVisible();
            await expect(grantApplicationPage.submitButton).toBeVisible();
        });

        await attachScreenshot(page, testInfo, 'Application form loaded');
    });

    test('submits an eligible application successfully', async ({
        grantApplicationPage,
        page
    }, testInfo) => {
        await story('Eligible applicant submits the form');
        await severity(Severity.BLOCKER);
        await tags('regression', 'happy-path');

        const applicant = eligibleApplicant({
            supportOption: SUPPORT_OPTIONS.optionOne
        });

        await test.step('Fill in the application form', async () => {
            await grantApplicationPage.fillForm(applicant);
        });

        await attachScreenshot(page, testInfo, 'Form filled');

        await test.step('Submit the application', async () => {
            await grantApplicationPage.submit();
        });

        await test.step('Success and eligibility messages are shown', async () => {
            await expect(
                grantApplicationPage.message(/submitted successfully/i)
            ).toBeVisible();
            await expect(
                grantApplicationPage.message(/eligible for financial support/i)
            ).toBeVisible();
        });

        await attachScreenshot(page, testInfo, 'Submission confirmation');
    });

    test('submits an application flagged as not eligible', async ({
        grantApplicationPage,
        page
    }, testInfo) => {
        await story('Applicant above the income threshold is not eligible');
        await severity(Severity.CRITICAL);
        await tags('regression', 'eligibility');

        const applicant = notEligibleApplicant();

        await test.step('Submit an application with income above the threshold', async () => {
            await grantApplicationPage.submitApplication(applicant);
        });

        await test.step('Success message reports the applicant is not eligible', async () => {
            await expect(
                grantApplicationPage.message(/submitted successfully/i)
            ).toBeVisible();
            await expect(
                grantApplicationPage.message(
                    /not eligible for financial support/i
                )
            ).toBeVisible();
        });

        await attachScreenshot(page, testInfo, 'Not eligible confirmation');
    });

    for (const supportOption of [
        SUPPORT_OPTIONS.optionTwo,
        SUPPORT_OPTIONS.optionThree
    ]) {
        test(`submits an eligible application with ${supportOption}`, async ({
            grantApplicationPage,
            page
        }, testInfo) => {
            await story('Eligible applicant chooses a different support option');
            await severity(Severity.NORMAL);
            await tags('regression', 'happy-path');

            const applicant = eligibleApplicant({ supportOption });

            await test.step(`Submit an eligible application with ${supportOption}`, async () => {
                await grantApplicationPage.submitApplication(applicant);
            });

            await test.step('Application is submitted successfully', async () => {
                await expect(
                    grantApplicationPage.message(/submitted successfully/i)
                ).toBeVisible();
            });

            await attachScreenshot(
                page,
                testInfo,
                `Submission confirmation - ${supportOption}`
            );
        });
    }

    test('rejects an invalid Singapore phone number', async ({
        grantApplicationPage,
        page
    }, testInfo) => {
        await story('Applicant enters an invalid phone number');
        await severity(Severity.NORMAL);
        await tags('regression', 'validation');

        const applicant = buildApplicant({ phone: '12345' });

        await test.step('Fill the form with an invalid phone number', async () => {
            await grantApplicationPage.fillForm(applicant);
        });

        await test.step('Submit the application', async () => {
            await grantApplicationPage.submit();
        });

        await test.step('A field-level validation error is displayed', async () => {
            await expect(
                grantApplicationPage.message(/valid Singapore phone number/i)
            ).toBeVisible();
        });

        await attachScreenshot(page, testInfo, 'Phone validation error');
    });

    test('rejects an invalid Singapore postal code', async ({
        grantApplicationPage,
        page
    }, testInfo) => {
        await story('Applicant enters an invalid postal code');
        await severity(Severity.NORMAL);
        await tags('regression', 'validation');

        const applicant = buildApplicant({ postalCode: '123' });

        await test.step('Fill the form with an invalid postal code', async () => {
            await grantApplicationPage.fillForm(applicant);
        });

        await test.step('Submit the application', async () => {
            await grantApplicationPage.submit();
        });

        await test.step('A field-level validation error is displayed', async () => {
            await expect(
                grantApplicationPage.message(/valid 6-digit Singapore postal code/i)
            ).toBeVisible();
        });

        await attachScreenshot(page, testInfo, 'Postal code validation error');
    });
});
