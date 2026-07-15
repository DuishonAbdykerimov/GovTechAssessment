#!/usr/bin/env bash
# Authenticate to Salesforce from an SFDX auth URL (when provided), then run the
# requested command. Credentials are never baked into the image — pass
# SFDX_AUTH_URL at runtime (e.g. `docker run -e SFDX_AUTH_URL=... `).
set -euo pipefail

if [ -n "${SFDX_AUTH_URL:-}" ]; then
    echo "Authenticating to Salesforce with SFDX_AUTH_URL..."
    echo "$SFDX_AUTH_URL" >/tmp/sfdx-auth-url.txt
    sf org login sfdx-url \
        --sfdx-url-file /tmp/sfdx-auth-url.txt \
        --alias ci-org \
        --set-default
    rm -f /tmp/sfdx-auth-url.txt
    # global-setup reads SF_TARGET_ORG; point it at the org we just logged in to.
    export SF_TARGET_ORG="ci-org"
fi

exec "$@"
