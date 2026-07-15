require('dotenv').config();

const { chromium } = require('@playwright/test');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const STORAGE_STATE = path.join(__dirname, '.auth', 'state.json');

module.exports = async () => {
    const communityPath =
        `/servlet/networks/session/create?url=` +
        `%2F${process.env.SF_COMMUNITY_PATH}%2F` +
        `&site=${process.env.SF_SITE_ID}`;

    const output = execFileSync(
        'sf',
        [
            'org',
            'open',
            '--target-org',
            process.env.SF_TARGET_ORG,
            '--path',
            communityPath,
            '--url-only',
            '--json'
        ],
        { encoding: 'utf8' }
    );

    // The CLI can print warnings before the JSON payload, so start at the first brace.
    const orgResult = JSON.parse(output.slice(output.indexOf('{')));

    const browser = await chromium.launch();
    const page = await browser.newPage();

    await page.goto(orgResult.result.url);
    await page
        .getByRole('heading', { name: 'Financial Support Application' })
        .waitFor();

    fs.mkdirSync(path.dirname(STORAGE_STATE), { recursive: true });
    await page.context().storageState({ path: STORAGE_STATE });

    await browser.close();
};

module.exports.STORAGE_STATE = STORAGE_STATE;
