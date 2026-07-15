/**
 * Test data builders for grant applicants.
 *
 * Phone numbers are randomised so repeated runs never collide on the
 * unique phone key used by the org, keeping the suite idempotent.
 */

function randomSingaporePhone() {
    const group = () => String(Math.floor(1000 + Math.random() * 9000));

    return `65 ${group()} ${group()}`;
}

const SUPPORT_OPTIONS = {
    optionOne: 'Option One',
    optionTwo: 'Option Two',
    optionThree: 'Option Three'
};

/**
 * Base applicant that always satisfies every field-level validation rule.
 * Individual tests override only the fields they care about.
 */
function buildApplicant(overrides = {}) {
    return {
        firstName: 'Portal',
        lastName: 'Applicant',
        phone: randomSingaporePhone(),
        postalCode: '123456',
        monthlyIncome: '1500',
        supportOption: SUPPORT_OPTIONS.optionOne,
        ...overrides
    };
}

/** Monthly income below the eligibility threshold (< 2000). */
function eligibleApplicant(overrides = {}) {
    return buildApplicant({ monthlyIncome: '1500', ...overrides });
}

/** Monthly income at or above the eligibility threshold (>= 2000). */
function notEligibleApplicant(overrides = {}) {
    return buildApplicant({ monthlyIncome: '2500', ...overrides });
}

module.exports = {
    SUPPORT_OPTIONS,
    randomSingaporePhone,
    buildApplicant,
    eligibleApplicant,
    notEligibleApplicant
};
