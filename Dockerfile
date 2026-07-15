# syntax=docker/dockerfile:1

# Reproducible Playwright E2E runner for the Agency X Grant Portal.
#
# Built on the official Playwright image, so all browsers (Chromium, Firefox,
# WebKit) and their OS dependencies are preinstalled and pinned to the same
# version as the project — no "works on my machine" drift.
FROM mcr.microsoft.com/playwright:v1.61.1-jammy

WORKDIR /app

# Salesforce CLI is required by tests/global-setup.js to open an authenticated
# Experience Cloud session that is shared across browsers via storageState.
RUN npm install --global @salesforce/cli

# Install dependencies first so this layer is cached until the manifests change.
COPY package.json package-lock.json ./
RUN npm install --no-audit --no-fund

# Copy the rest of the framework (Playwright config, tests, page objects, ...).
COPY . .

RUN chmod +x ./docker-entrypoint.sh

# The entrypoint authenticates to Salesforce (if SFDX_AUTH_URL is provided),
# then runs the given command.
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["npm", "run", "test:e2e"]
