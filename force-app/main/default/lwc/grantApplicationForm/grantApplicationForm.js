import { LightningElement, wire } from 'lwc';
import getSupportOptions from '@salesforce/apex/GrantApplicationController.getSupportOptions';
import submitApplication from '@salesforce/apex/GrantApplicationController.submitApplication';

export default class GrantApplicationForm extends LightningElement {
    firstName = '';
    lastName = '';
    phone = '';
    postalCode = '';
    monthlyIncome;
    supportOption = '';

    supportOptions = [];
    isLoading = false;
    successMessage = '';
    errorMessage = '';

    @wire(getSupportOptions)
    wiredSupportOptions({ data, error }) {
        if (data) {
            this.supportOptions = data;
        } else if (error) {
            this.errorMessage = this.extractErrorMessage(error);
        }
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value;

        this.successMessage = '';
        this.errorMessage = '';
    }

    handleSupportOptionChange(event) {
        this.supportOption = event.detail.value;

        this.successMessage = '';
        this.errorMessage = '';
    }

    async handleSubmit() {
        this.successMessage = '';
        this.errorMessage = '';

        if (!this.validateForm()) {
            return;
        }

        this.isLoading = true;

        try {
            const result = await submitApplication({
                firstName: this.firstName,
                lastName: this.lastName,
                phone: this.phone,
                postalCode: this.postalCode,
                monthlyIncome: Number(this.monthlyIncome),
                supportOption: this.supportOption
            });

            this.successMessage = result.message;
            this.resetForm();
        } catch (error) {
            this.errorMessage = this.extractErrorMessage(error);
        } finally {
            this.isLoading = false;
        }
    }

    validateForm() {
        const inputs = [...this.template.querySelectorAll('lightning-input')];
        const combobox = this.template.querySelector('lightning-combobox');

        let isValid = true;

        inputs.forEach((input) => {
            input.reportValidity();

            if (!input.checkValidity()) {
                isValid = false;
            }
        });

        if (combobox) {
            combobox.reportValidity();

            if (!combobox.checkValidity()) {
                isValid = false;
            }
        }

        return isValid;
    }

    resetForm() {
        this.firstName = '';
        this.lastName = '';
        this.phone = '';
        this.postalCode = '';
        this.monthlyIncome = null;
        this.supportOption = '';
    }

    extractErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }

        if (error?.message) {
            return error.message;
        }

        return 'The application could not be submitted. Please try again.';
    }

    get supportOptionChoices() {
        return this.supportOptions.map((option) => ({
            label: `${option.label} — SGD ${option.monthlyAmount} for ${option.durationMonths} months`,
            value: option.value
        }));
    }
    get selectedOptionSummary() {
        if (!this.supportOption) {
            return '';
        }
    
        const selectedOption = this.supportOptions.find(
            (option) => option.value === this.supportOption
        );
    
        if (!selectedOption) {
            return '';
        }
    
        const totalAmount =
            selectedOption.monthlyAmount * selectedOption.durationMonths;
    
        return (
            `${selectedOption.label}: SGD ${selectedOption.monthlyAmount} per month ` +
            `for ${selectedOption.durationMonths} months. ` +
            `Total support amount: SGD ${totalAmount}.`
        );
    }
}