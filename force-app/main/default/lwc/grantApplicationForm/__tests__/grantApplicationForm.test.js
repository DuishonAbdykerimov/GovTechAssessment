import { createElement } from 'lwc';

import GrantApplicationForm from 'c/grantApplicationForm';
import getSupportOptions from '@salesforce/apex/GrantApplicationController.getSupportOptions';
import submitApplication from '@salesforce/apex/GrantApplicationController.submitApplication';

jest.mock(
    '@salesforce/apex/GrantApplicationController.getSupportOptions',
    () => {
        const {
            createApexTestWireAdapter
        } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/GrantApplicationController.submitApplication',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

const SUPPORT_OPTIONS = [
    {
        label: 'Option One',
        value: 'Option One',
        monthlyAmount: 500,
        durationMonths: 3
    },
    {
        label: 'Option Two',
        value: 'Option Two',
        monthlyAmount: 300,
        durationMonths: 6
    },
    {
        label: 'Option Three',
        value: 'Option Three',
        monthlyAmount: 200,
        durationMonths: 12
    }
];

function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
}

function createComponent() {
    const element = createElement('c-grant-application-form', {
        is: GrantApplicationForm
    });

    document.body.appendChild(element);

    return element;
}

function markFieldsValid(element) {
    element.shadowRoot
        .querySelectorAll('lightning-input, lightning-combobox')
        .forEach((field) => {
            field.checkValidity = jest.fn(() => true);
            field.reportValidity = jest.fn();
        });
}

function populateForm(element) {
    const inputs = element.shadowRoot.querySelectorAll('lightning-input');

    const inputValues = {
        firstName: 'Portal',
        lastName: 'Applicant',
        phone: '65 6812 3800',
        postalCode: '323800',
        monthlyIncome: '1500'
    };

    inputs.forEach((input) => {
        input.value = inputValues[input.name];

        input.dispatchEvent(new CustomEvent('change'));
    });

    const supportOption =
        element.shadowRoot.querySelector('lightning-combobox');

    supportOption.dispatchEvent(
        new CustomEvent('change', {
            detail: {
                value: 'Option One'
            }
        })
    );

    markFieldsValid(element);
}

describe('c-grant-application-form', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }

        jest.clearAllMocks();
    });

    it('loads active support options from Apex', async () => {
        const element = createComponent();

        getSupportOptions.emit(SUPPORT_OPTIONS);

        await flushPromises();

        const combobox =
            element.shadowRoot.querySelector('lightning-combobox');

        expect(combobox.options).toHaveLength(3);

        expect(combobox.options[0]).toEqual({
            label: 'Option One — SGD 500 for 3 months',
            value: 'Option One'
        });

        expect(combobox.options[1]).toEqual({
            label: 'Option Two — SGD 300 for 6 months',
            value: 'Option Two'
        });

        expect(combobox.options[2]).toEqual({
            label: 'Option Three — SGD 200 for 12 months',
            value: 'Option Three'
        });
    });

    it('submits a valid grant application', async () => {
        submitApplication.mockResolvedValue({
            success: true,
            contactId: '003000000000001AAA',
            eligibilityStatus: 'Eligible',
            message:
                'Your application has been submitted successfully. ' +
                'You are eligible for financial support.'
        });

        const element = createComponent();

        getSupportOptions.emit(SUPPORT_OPTIONS);

        await flushPromises();

        populateForm(element);

        const button =
            element.shadowRoot.querySelector('lightning-button');

        button.click();

        await flushPromises();

        expect(submitApplication).toHaveBeenCalledTimes(1);

        expect(submitApplication).toHaveBeenCalledWith({
            firstName: 'Portal',
            lastName: 'Applicant',
            phone: '65 6812 3800',
            postalCode: '323800',
            monthlyIncome: 1500,
            supportOption: 'Option One'
        });

        expect(element.shadowRoot.textContent).toContain(
            'Your application has been submitted successfully.'
        );

        expect(element.shadowRoot.textContent).toContain(
            'You are eligible for financial support.'
        );
    });

    it('shows a friendly Apex error message', async () => {
        submitApplication.mockRejectedValue({
            body: {
                message:
                    'Enter a valid Singapore phone number in the format 65 6812 3456.'
            }
        });

        const element = createComponent();

        getSupportOptions.emit(SUPPORT_OPTIONS);

        await flushPromises();

        populateForm(element);

        const button =
            element.shadowRoot.querySelector('lightning-button');

        button.click();

        await flushPromises();

        expect(element.shadowRoot.textContent).toContain(
            'Enter a valid Singapore phone number in the format 65 6812 3456.'
        );
    });

    it('shows an error when support options cannot be loaded', async () => {
        const element = createComponent();

        // Apex wire adapter.error(body, status, statusText)
        getSupportOptions.error({
            message: 'Unable to load support options.'
        });

        await flushPromises();

        expect(element.shadowRoot.textContent).toContain(
            'Unable to load support options.'
        );
    });
});
