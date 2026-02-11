#!/usr/bin/env bash
#
# rebrand.sh — Automated rebranding script for Element X iOS fork
#
# Replaces identity, URLs, and hardcoded strings across the project.
# Does NOT touch: .xcodeproj, localization .strings files, visual assets.
#
# Usage:
#   ./scripts/rebrand.sh                     # Interactive mode (prompts for values)
#   ./scripts/rebrand.sh --dry-run           # Show what would change without modifying files
#   APP_NAME="My App" BUNDLE_ID="com.example.app" ... ./scripts/rebrand.sh  # Environment variables
#
# After running this script, you must:
#   1. Run `xcodegen generate` to regenerate the .xcodeproj
#   2. Update localization .strings files (separate task)
#   3. Replace visual assets (app icon, logo, launch images) manually
#
# Requires: macOS with BSD sed, git
#
set -euo pipefail

# --------------------------------------------------------------------------
# Color output helpers
# --------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { printf "${CYAN}[INFO]${NC}  %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
error()   { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }
header()  { printf "\n${BOLD}=== %s ===${NC}\n\n" "$1"; }

# --------------------------------------------------------------------------
# Determine project root (script lives in scripts/)
# --------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --------------------------------------------------------------------------
# Parse flags
# --------------------------------------------------------------------------
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            printf "Usage: %s [--dry-run] [--help]\n" "$(basename "$0")"
            printf "\nSet parameters via environment variables or respond to interactive prompts.\n"
            printf "\nRequired variables:\n"
            printf "  APP_NAME            New app display name (e.g. \"My Messenger\")\n"
            printf "  PRODUCTION_NAME     Production app name for server identification (e.g. \"MyMessenger\")\n"
            printf "  BUNDLE_ID           New base bundle identifier (e.g. \"com.customer.messenger\")\n"
            printf "  APP_GROUP           New app group identifier (e.g. \"group.com.customer\")\n"
            printf "  TEAM_ID             Apple Developer Team ID (e.g. \"ABC123XYZ\")\n"
            printf "  WEBSITE_URL         Customer website URL (e.g. \"https://example.com\")\n"
            printf "  OIDC_REDIRECT_URL   OIDC redirect URL (e.g. \"https://example.com/oidc/login\")\n"
            printf "  PRIVACY_URL         Privacy policy URL\n"
            printf "  TERMS_URL           Terms of use / acceptable use URL\n"
            printf "  COPYRIGHT_URL       Copyright notice URL\n"
            printf "\nOptional variables:\n"
            printf "  PUSH_GATEWAY_URL    Push gateway endpoint (default: https://matrix.org)\n"
            exit 0
            ;;
        *)
            error "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

if $DRY_RUN; then
    warn "DRY-RUN MODE: No files will be modified."
fi

# --------------------------------------------------------------------------
# Prompt for a parameter if not set in environment
# --------------------------------------------------------------------------
prompt_param() {
    local var_name="$1"
    local description="$2"
    local default_value="${3:-}"
    local current_value="${!var_name:-}"

    if [[ -n "$current_value" ]]; then
        return
    fi

    if [[ -n "$default_value" ]]; then
        printf "${BOLD}%s${NC} [%s]: " "$description" "$default_value"
        read -r input
        if [[ -z "$input" ]]; then
            eval "$var_name='$default_value'"
        else
            eval "$var_name='$input'"
        fi
    else
        printf "${BOLD}%s${NC}: " "$description"
        read -r input
        if [[ -z "$input" ]]; then
            error "$var_name is required."
            exit 1
        fi
        eval "$var_name='$input'"
    fi
}

# --------------------------------------------------------------------------
# Collect parameters (from env or interactive prompts)
# --------------------------------------------------------------------------
header "Rebranding Configuration"

prompt_param APP_NAME          "App display name (e.g. My Messenger)"
prompt_param PRODUCTION_NAME   "Production app name for server ID (e.g. MyMessenger)"
prompt_param BUNDLE_ID         "Base bundle identifier (e.g. com.customer.messenger)"
prompt_param APP_GROUP         "App group identifier (e.g. group.com.customer)"
prompt_param TEAM_ID           "Apple Developer Team ID (e.g. ABC123XYZ)"
prompt_param WEBSITE_URL       "Customer website URL (e.g. https://example.com)"
prompt_param OIDC_REDIRECT_URL "OIDC redirect URL (e.g. https://example.com/oidc/login)"
prompt_param PRIVACY_URL       "Privacy policy URL"
prompt_param TERMS_URL         "Terms of use / acceptable use URL"
prompt_param COPYRIGHT_URL     "Copyright notice URL"
prompt_param PUSH_GATEWAY_URL  "Push gateway URL" "https://matrix.org"

# --------------------------------------------------------------------------
# Derived values
# --------------------------------------------------------------------------
# URL scheme for call integration: derive from bundle ID (e.g. com.customer.messenger -> com.customer.call)
# Extract the domain prefix from the bundle ID (everything except the last component)
BUNDLE_PREFIX="$(echo "$BUNDLE_ID" | sed 's/\.[^.]*$//')"
CALL_URL_SCHEME="${BUNDLE_PREFIX}.call"

# Extract the website host (e.g. "https://example.com" -> "example.com")
WEBSITE_HOST="$(echo "$WEBSITE_URL" | sed -E 's|https?://||; s|/.*||')"

# Help/encryption URLs derived from website
ENCRYPTION_URL="${WEBSITE_URL}/help#encryption"
DEVICE_VERIFICATION_URL="${WEBSITE_URL}/help#encryption-device-verification"
CHAT_BACKUP_URL="${WEBSITE_URL}/help#encryption5"
IDENTITY_PINNING_URL="${WEBSITE_URL}/help#encryption18"
HISTORY_SHARING_URL="${WEBSITE_URL}/en/help#e2ee-history-sharing"
LOGO_URL="${WEBSITE_URL}/mobile-icon.png"
ANALYTICS_TERMS_URL="${WEBSITE_URL}/cookie-policy"

# --------------------------------------------------------------------------
# Validate required parameters
# --------------------------------------------------------------------------
header "Validating Parameters"

VALIDATION_FAILED=false

validate_nonempty() {
    local var_name="$1"
    local value="${!var_name:-}"
    if [[ -z "$value" ]]; then
        error "$var_name is required but not set."
        VALIDATION_FAILED=true
    fi
}

validate_url() {
    local var_name="$1"
    local value="${!var_name:-}"
    if [[ -n "$value" ]] && ! echo "$value" | grep -qE '^https?://'; then
        error "$var_name must start with http:// or https:// (got: $value)"
        VALIDATION_FAILED=true
    fi
}

validate_bundle_id() {
    local value="$1"
    if ! echo "$value" | grep -qE '^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)+$'; then
        error "BUNDLE_ID must be a valid reverse-domain identifier (got: $value)"
        VALIDATION_FAILED=true
    fi
}

validate_nonempty APP_NAME
validate_nonempty PRODUCTION_NAME
validate_nonempty BUNDLE_ID
validate_nonempty APP_GROUP
validate_nonempty TEAM_ID
validate_nonempty WEBSITE_URL
validate_nonempty OIDC_REDIRECT_URL
validate_nonempty PRIVACY_URL
validate_nonempty TERMS_URL
validate_nonempty COPYRIGHT_URL

validate_url WEBSITE_URL
validate_url OIDC_REDIRECT_URL
validate_url PRIVACY_URL
validate_url TERMS_URL
validate_url COPYRIGHT_URL
validate_url PUSH_GATEWAY_URL

validate_bundle_id "$BUNDLE_ID"

if $VALIDATION_FAILED; then
    error "Validation failed. Fix the errors above and try again."
    exit 1
fi

success "All parameters validated."

# --------------------------------------------------------------------------
# Display summary
# --------------------------------------------------------------------------
header "Rebranding Summary"

printf "  %-30s %s\n" "App Name:" "$APP_NAME"
printf "  %-30s %s\n" "Production Name:" "$PRODUCTION_NAME"
printf "  %-30s %s\n" "Bundle ID:" "$BUNDLE_ID"
printf "  %-30s %s\n" "App Group:" "$APP_GROUP"
printf "  %-30s %s\n" "Team ID:" "$TEAM_ID"
printf "  %-30s %s\n" "Website URL:" "$WEBSITE_URL"
printf "  %-30s %s\n" "OIDC Redirect URL:" "$OIDC_REDIRECT_URL"
printf "  %-30s %s\n" "Privacy URL:" "$PRIVACY_URL"
printf "  %-30s %s\n" "Terms URL:" "$TERMS_URL"
printf "  %-30s %s\n" "Copyright URL:" "$COPYRIGHT_URL"
printf "  %-30s %s\n" "Push Gateway URL:" "$PUSH_GATEWAY_URL"
printf "  %-30s %s\n" "Call URL Scheme (derived):" "$CALL_URL_SCHEME"
printf "  %-30s %s\n" "Website Host (derived):" "$WEBSITE_HOST"

if ! $DRY_RUN; then
    printf "\n"
    printf "${YELLOW}This will modify files in: %s${NC}\n" "$PROJECT_ROOT"
    printf "Press Enter to continue or Ctrl+C to abort... "
    read -r
fi

# --------------------------------------------------------------------------
# Backup branch (skip in dry-run)
# --------------------------------------------------------------------------
if ! $DRY_RUN; then
    header "Creating Backup"

    BACKUP_BRANCH="backup/pre-rebrand-$(date +%Y%m%d-%H%M%S)"
    cd "$PROJECT_ROOT"

    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "You have uncommitted changes. Committing them to a backup branch."
        git stash push -m "rebrand-script-stash" 2>/dev/null || true
        git branch "$BACKUP_BRANCH" 2>/dev/null || true
        git stash pop 2>/dev/null || true
    else
        git branch "$BACKUP_BRANCH" 2>/dev/null || true
    fi

    success "Backup branch created: $BACKUP_BRANCH"
fi

# --------------------------------------------------------------------------
# Helper: sed in-place (macOS compatible)
# In dry-run mode, show the diff instead of modifying.
# --------------------------------------------------------------------------
CHANGE_COUNT=0

# Perform a sed substitution on a file.
# Usage: do_sed <file> <sed_expression> <description>
do_sed() {
    local file="$1"
    local expression="$2"
    local description="$3"
    local full_path="${PROJECT_ROOT}/${file}"

    if [[ ! -f "$full_path" ]]; then
        warn "File not found, skipping: $file"
        return
    fi

    if $DRY_RUN; then
        # Show what would change
        local before after
        before="$(cat "$full_path")"
        after="$(sed "$expression" "$full_path")"
        if [[ "$before" != "$after" ]]; then
            info "[DRY-RUN] $description"
            info "  File: $file"
            # Show a compact diff (first 5 changes)
            diff <(echo "$before") <(echo "$after") | head -20 || true
            printf "\n"
            CHANGE_COUNT=$((CHANGE_COUNT + 1))
        fi
    else
        # Check if the substitution would change anything
        local before after
        before="$(cat "$full_path")"
        sed -i '' "$expression" "$full_path"
        after="$(cat "$full_path")"
        if [[ "$before" != "$after" ]]; then
            success "$description"
            CHANGE_COUNT=$((CHANGE_COUNT + 1))
        fi
    fi
}

# Perform a literal string replacement in a file.
# Uses '|' as the sed delimiter, so old/new strings must not contain '|'.
# Usage: do_replace <file> <old_string> <new_string> <description>
do_replace() {
    local file="$1"
    local old_string="$2"
    local new_string="$3"
    local description="$4"

    do_sed "$file" "s|${old_string}|${new_string}|g" "$description"
}

# --------------------------------------------------------------------------
# SECTION 1: app.yml — Build variables (identity)
# --------------------------------------------------------------------------
header "Section 1: app.yml — Build Variables"

APP_YML="app.yml"

do_sed "$APP_YML" \
    "s|APP_DISPLAY_NAME:.*|APP_DISPLAY_NAME: ${APP_NAME}|" \
    "app.yml: Set APP_DISPLAY_NAME to '${APP_NAME}'"

do_sed "$APP_YML" \
    "s|PRODUCTION_APP_NAME:.*|PRODUCTION_APP_NAME: ${PRODUCTION_NAME}|" \
    "app.yml: Set PRODUCTION_APP_NAME to '${PRODUCTION_NAME}'"

do_sed "$APP_YML" \
    "s|APP_GROUP_IDENTIFIER:.*|APP_GROUP_IDENTIFIER: ${APP_GROUP}|" \
    "app.yml: Set APP_GROUP_IDENTIFIER to '${APP_GROUP}'"

do_sed "$APP_YML" \
    "s|BASE_BUNDLE_IDENTIFIER:.*|BASE_BUNDLE_IDENTIFIER: ${BUNDLE_ID}|" \
    "app.yml: Set BASE_BUNDLE_IDENTIFIER to '${BUNDLE_ID}'"

do_sed "$APP_YML" \
    "s|DEVELOPMENT_TEAM:.*|DEVELOPMENT_TEAM: ${TEAM_ID}|" \
    "app.yml: Set DEVELOPMENT_TEAM to '${TEAM_ID}'"

# --------------------------------------------------------------------------
# SECTION 2: project.yml — Organization name
# --------------------------------------------------------------------------
header "Section 2: project.yml — Organization Name"

do_sed "project.yml" \
    "s|ORGANIZATIONNAME:.*|ORGANIZATIONNAME: ${PRODUCTION_NAME}|" \
    "project.yml: Set ORGANIZATIONNAME to '${PRODUCTION_NAME}'"

# --------------------------------------------------------------------------
# SECTION 3: AppSettings.swift — URLs and configuration
# --------------------------------------------------------------------------
header "Section 3: AppSettings.swift — URLs and Configuration"

APPSETTINGS="ElementX/Sources/Application/Settings/AppSettings.swift"

# --- Brand URLs ---

do_replace "$APPSETTINGS" \
    'var websiteURL: URL = "https://element.io"' \
    "var websiteURL: URL = \"${WEBSITE_URL}\"" \
    "AppSettings: websiteURL"

do_replace "$APPSETTINGS" \
    'var logoURL: URL = "https://element.io/mobile-icon.png"' \
    "var logoURL: URL = \"${LOGO_URL}\"" \
    "AppSettings: logoURL"

do_replace "$APPSETTINGS" \
    'var copyrightURL: URL = "https://element.io/copyright"' \
    "var copyrightURL: URL = \"${COPYRIGHT_URL}\"" \
    "AppSettings: copyrightURL"

do_replace "$APPSETTINGS" \
    'var acceptableUseURL: URL = "https://element.io/acceptable-use-policy-terms"' \
    "var acceptableUseURL: URL = \"${TERMS_URL}\"" \
    "AppSettings: acceptableUseURL"

do_replace "$APPSETTINGS" \
    'var privacyURL: URL = "https://element.io/privacy"' \
    "var privacyURL: URL = \"${PRIVACY_URL}\"" \
    "AppSettings: privacyURL"

do_replace "$APPSETTINGS" \
    'var encryptionURL: URL = "https://element.io/help#encryption"' \
    "var encryptionURL: URL = \"${ENCRYPTION_URL}\"" \
    "AppSettings: encryptionURL"

do_replace "$APPSETTINGS" \
    'var deviceVerificationURL: URL = "https://element.io/help#encryption-device-verification"' \
    "var deviceVerificationURL: URL = \"${DEVICE_VERIFICATION_URL}\"" \
    "AppSettings: deviceVerificationURL"

do_replace "$APPSETTINGS" \
    'var chatBackupDetailsURL: URL = "https://element.io/help#encryption5"' \
    "var chatBackupDetailsURL: URL = \"${CHAT_BACKUP_URL}\"" \
    "AppSettings: chatBackupDetailsURL"

do_replace "$APPSETTINGS" \
    'var identityPinningViolationDetailsURL: URL = "https://element.io/help#encryption18"' \
    "var identityPinningViolationDetailsURL: URL = \"${IDENTITY_PINNING_URL}\"" \
    "AppSettings: identityPinningViolationDetailsURL"

do_replace "$APPSETTINGS" \
    'var historySharingDetailsURL: URL = "https://element.io/en/help#e2ee-history-sharing"' \
    "var historySharingDetailsURL: URL = \"${HISTORY_SHARING_URL}\"" \
    "AppSettings: historySharingDetailsURL"

# --- OIDC ---

do_replace "$APPSETTINGS" \
    'var oidcRedirectURL: URL = "https://element.io/oidc/login"' \
    "var oidcRedirectURL: URL = \"${OIDC_REDIRECT_URL}\"" \
    "AppSettings: oidcRedirectURL"

# --- Analytics terms ---

do_replace "$APPSETTINGS" \
    'var analyticsTermsURL: URL? = "https://element.io/cookie-policy"' \
    "var analyticsTermsURL: URL? = \"${ANALYTICS_TERMS_URL}\"" \
    "AppSettings: analyticsTermsURL"

# --- Web hosts and account provisioning ---

do_replace "$APPSETTINGS" \
    'var elementWebHosts = ["app.element.io", "staging.element.io", "develop.element.io"]' \
    "var elementWebHosts = [\"${WEBSITE_HOST}\"]" \
    "AppSettings: elementWebHosts"

do_replace "$APPSETTINGS" \
    'var accountProvisioningHost = "mobile.element.io"' \
    "var accountProvisioningHost = \"${WEBSITE_HOST}\"" \
    "AppSettings: accountProvisioningHost"

# --- Push gateway ---

do_replace "$APPSETTINGS" \
    'var pushGatewayBaseURL: URL = "https://matrix.org"' \
    "var pushGatewayBaseURL: URL = \"${PUSH_GATEWAY_URL}\"" \
    "AppSettings: pushGatewayBaseURL"

# --- Background task identifier (uses bundle ID prefix) ---

do_replace "$APPSETTINGS" \
    '"io.element.elementx.background.refresh"' \
    "\"${BUNDLE_ID}.background.refresh\"" \
    "AppSettings: backgroundAppRefreshTaskIdentifier"

# --- Nightly build detection (uses bundle ID prefix) ---

do_replace "$APPSETTINGS" \
    '"io.element.elementx.nightly"' \
    "\"${BUNDLE_ID}.nightly\"" \
    "AppSettings: nightly bundle ID check"

# --- Element Call PostHog (disable for customer brand) ---

do_replace "$APPSETTINGS" \
    'let elementCallPosthogAPIHost = "https://posthog-element-call.element.io"' \
    "let elementCallPosthogAPIHost = \"\"" \
    "AppSettings: Disable Element Call PostHog host"

do_replace "$APPSETTINGS" \
    'let elementCallPosthogAPIKey = "phc_rXGHx9vDmyEvyRxPziYtdVIv0ahEv8A9uLWFcCi1WcU"' \
    "let elementCallPosthogAPIKey = \"\"" \
    "AppSettings: Disable Element Call PostHog API key"

do_replace "$APPSETTINGS" \
    'let elementCallPosthogSentryDSN = "https://3bd2f95ba5554d4497da7153b552ffb5@sentry.tools.element.io/41"' \
    "let elementCallPosthogSentryDSN = \"\"" \
    "AppSettings: Disable Element Call Sentry DSN"

# --- Bug report application ID ---

do_replace "$APPSETTINGS" \
    'var bugReportApplicationID = "element-x-ios"' \
    "var bugReportApplicationID = \"${BUNDLE_ID}\"" \
    "AppSettings: bugReportApplicationID"

# --------------------------------------------------------------------------
# SECTION 4: target.yml (main app) — URL schemes, background tasks, domains
# --------------------------------------------------------------------------
header "Section 4: target.yml — URL Schemes, Domains, Background Tasks"

TARGET_YML="ElementX/SupportingFiles/target.yml"

# URL scheme for Element Call
do_replace "$TARGET_YML" \
    'CFBundleURLName: "Element Call"' \
    "CFBundleURLName: \"${APP_NAME} Call\"" \
    "target.yml: Call URL scheme name"

do_replace "$TARGET_YML" \
    'io.element.call' \
    "${CALL_URL_SCHEME}" \
    "target.yml: Call URL scheme value"

# Background task identifier
do_replace "$TARGET_YML" \
    'io.element.elementx.background.refresh' \
    "${BUNDLE_ID}.background.refresh" \
    "target.yml: Background task identifier"

# Associated domains — replace element.io domains with customer domain
# We replace the entire associated-domains block line by line
do_sed "$TARGET_YML" \
    "s|applinks:element\.io|applinks:${WEBSITE_HOST}|g" \
    "target.yml: Associated domain — element.io"

do_sed "$TARGET_YML" \
    "s|applinks:app\.element\.io|applinks:${WEBSITE_HOST}|g" \
    "target.yml: Associated domain — app.element.io"

# Remove staging and develop domains (not applicable for customer)
do_sed "$TARGET_YML" \
    "/applinks:staging\.element\.io/d" \
    "target.yml: Remove staging.element.io domain"

do_sed "$TARGET_YML" \
    "/applinks:develop\.element\.io/d" \
    "target.yml: Remove develop.element.io domain"

do_sed "$TARGET_YML" \
    "s|applinks:mobile\.element\.io|applinks:${WEBSITE_HOST}|g" \
    "target.yml: Associated domain — mobile.element.io"

do_sed "$TARGET_YML" \
    "s|applinks:call\.element\.io|applinks:call.${WEBSITE_HOST}|g" \
    "target.yml: Associated domain — call.element.io"

# Remove call.element.dev (Element development domain, not needed)
do_sed "$TARGET_YML" \
    "/applinks:call\.element\.dev/d" \
    "target.yml: Remove call.element.dev domain"

# Webcredentials — replace element.io wildcard with customer domain
do_sed "$TARGET_YML" \
    "s|webcredentials:\*\.element\.io|webcredentials:*.${WEBSITE_HOST}|g" \
    "target.yml: Webcredentials domain"

# --------------------------------------------------------------------------
# SECTION 5: NSE — Hardcoded notification identifier
# --------------------------------------------------------------------------
header "Section 5: NSE — Hardcoded Notification ID"

NSE_FILE="NSE/Sources/NotificationServiceExtension.swift"

do_replace "$NSE_FILE" \
    '"io.element.elementx.receivedWhileOfflineNotification"' \
    "\"${BUNDLE_ID}.receivedWhileOfflineNotification\"" \
    "NSE: receivedWhileOfflineNotificationID"

# --------------------------------------------------------------------------
# SECTION 6: Other hardcoded io.element.elementx strings in Swift source
# --------------------------------------------------------------------------
header "Section 6: Hardcoded Bundle ID References in Swift Source"

# BugReportService.swift — nightly detection
do_replace "ElementX/Sources/Services/BugReport/BugReportService.swift" \
    '"io.element.elementx.nightly"' \
    "\"${BUNDLE_ID}.nightly\"" \
    "BugReportService: nightly bundle ID check"

# UserSessionFlowCoordinator.swift — reachability notification
do_replace "ElementX/Sources/FlowCoordinators/UserSessionFlowCoordinator.swift" \
    '"io.element.elementx.reachability.notification"' \
    "\"${BUNDLE_ID}.reachability.notification\"" \
    "UserSessionFlowCoordinator: reachability notification ID"

# NetworkMonitor.swift — dispatch queue label
do_replace "ElementX/Sources/Other/NetworkMonitor/NetworkMonitor.swift" \
    '"io.element.elementx.network_monitor"' \
    "\"${BUNDLE_ID}.network_monitor\"" \
    "NetworkMonitor: dispatch queue label"

# RoomSummaryProvider.swift — dispatch queue label
do_replace "ElementX/Sources/Services/Room/RoomSummary/RoomSummaryProvider.swift" \
    '"io.element.elementx.room_summary_provider"' \
    "\"${BUNDLE_ID}.room_summary_provider\"" \
    "RoomSummaryProvider: dispatch queue label"

# RoomDirectorySearchProxy.swift — dispatch queue label
do_replace "ElementX/Sources/Services/RoomDirectorySearch/RoomDirectorySearchProxy.swift" \
    '"io.element.elementx.room_directory_search_proxy"' \
    "\"${BUNDLE_ID}.room_directory_search_proxy\"" \
    "RoomDirectorySearchProxy: dispatch queue label"

# TimelineItemProvider.swift — dispatch queue label
do_replace "ElementX/Sources/Services/Timeline/TimelineItemProvider.swift" \
    '"io.element.elementx.timeline_item_provider"' \
    "\"${BUNDLE_ID}.timeline_item_provider\"" \
    "TimelineItemProvider: dispatch queue label"

# EmojiProviderProtocol.swift — category identifier
do_replace "ElementX/Sources/Services/Emojis/EmojiProviderProtocol.swift" \
    '"io.element.elementx.frequently_used"' \
    "\"${BUNDLE_ID}.frequently_used\"" \
    "EmojiProviderProtocol: frequently used category ID"

# Bundle.swift — dispatch queue label
do_replace "ElementX/Sources/Other/Extensions/Bundle.swift" \
    '"io.element.elementx.localization_bundle_cache"' \
    "\"${BUNDLE_ID}.localization_bundle_cache\"" \
    "Bundle: localization cache dispatch queue label"

# AudioRecorder.swift — dispatch queue label
do_replace "ElementX/Sources/Services/Audio/Recorder/AudioRecorder.swift" \
    '"io.element.elementx.audio_recorder"' \
    "\"${BUNDLE_ID}.audio_recorder\"" \
    "AudioRecorder: dispatch queue label"

# AttributedStringBuilder.swift — dispatch queue label
do_replace "ElementX/Sources/Other/HTMLParsing/AttributedStringBuilder.swift" \
    '"io.element.elementx.attributed_string_builder_v2_cache"' \
    "\"${BUNDLE_ID}.attributed_string_builder_v2_cache\"" \
    "AttributedStringBuilder: cache dispatch queue label"

# CallScreen.swift — Element Call client ID
do_replace "ElementX/Sources/Screens/CallScreen/View/CallScreen.swift" \
    'clientID: "io.element.elementx"' \
    "clientID: \"${BUNDLE_ID}\"" \
    "CallScreen: Element Call client ID"

# --------------------------------------------------------------------------
# SECTION 7: Hardcoded element.io in Swift source (non-AppSettings)
# --------------------------------------------------------------------------
header "Section 7: Hardcoded element.io References in Swift Source"

# AppRoutes.swift — known call hosts
do_replace "ElementX/Sources/Application/Navigation/AppRoutes.swift" \
    'knownHosts = ["call.element.io"]' \
    "knownHosts = [\"call.${WEBSITE_HOST}\"]" \
    "AppRoutes: Element Call known hosts"

# ServerConfirmationScreenModels.swift — element.io special case
do_replace "ElementX/Sources/Screens/Authentication/ServerConfirmationScreen/ServerConfirmationScreenModels.swift" \
    'homeserverAddress == "element.io"' \
    "homeserverAddress == \"${WEBSITE_HOST}\"" \
    "ServerConfirmationScreenModels: homeserver special case"

# RoomScreenFooterView.swift — learnMoreURL references (3 occurrences)
do_sed "ElementX/Sources/Screens/RoomScreen/View/RoomScreenFooterView.swift" \
    "s|\"https://element.io/\"|\"${WEBSITE_URL}/\"|g" \
    "RoomScreenFooterView: learnMoreURL references"

# --------------------------------------------------------------------------
# SECTION 8: Test file bundle ID references (lower priority, for consistency)
# --------------------------------------------------------------------------
header "Section 8: Test Files — Bundle ID References"

# UITestsAppCoordinator.swift
do_replace "ElementX/Sources/UITests/UITestsAppCoordinator.swift" \
    '"io.element.elementx.uitests"' \
    "\"${BUNDLE_ID}.uitests\"" \
    "UITestsAppCoordinator: suite name"

# UnitTestsAppCoordinator.swift
do_replace "ElementX/Sources/UnitTests/UnitTestsAppCoordinator.swift" \
    '"io.element.elementx.unittests"' \
    "\"${BUNDLE_ID}.unittests\"" \
    "UnitTestsAppCoordinator: suite name"

# AccessibilityTestsAppCoordinator.swift
do_replace "ElementX/Sources/AccessibilityTests/AccessibilityTestsAppCoordinator.swift" \
    '"io.element.elementx.accessibilitytests"' \
    "\"${BUNDLE_ID}.accessibilitytests\"" \
    "AccessibilityTestsAppCoordinator: suite name"

# --------------------------------------------------------------------------
# SECTION 9: Info.plist background task identifier
# --------------------------------------------------------------------------
header "Section 9: Info.plist — Background Task Identifier"

INFOPLIST="ElementX/SupportingFiles/Info.plist"

if [[ -f "${PROJECT_ROOT}/${INFOPLIST}" ]]; then
    do_replace "$INFOPLIST" \
        'io.element.elementx.background.refresh' \
        "${BUNDLE_ID}.background.refresh" \
        "Info.plist: Background task identifier"
else
    warn "Info.plist not found (may be auto-generated by XcodeGen)"
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
header "Rebranding Complete"

if $DRY_RUN; then
    info "DRY-RUN: ${CHANGE_COUNT} changes would be made."
    info "Run without --dry-run to apply changes."
else
    success "${CHANGE_COUNT} changes applied successfully."
    printf "\n"
    info "Backup branch: ${BACKUP_BRANCH}"
    printf "\n"
    warn "Next steps:"
    printf "  1. Run ${BOLD}xcodegen generate${NC} to regenerate the .xcodeproj\n"
    printf "  2. Update localization .strings files (InfoPlist.strings + Localizable.strings)\n"
    printf "  3. Replace visual assets: app icon, logo, launch screen images\n"
    printf "  4. Update Secrets/Secrets.swift with customer analytics keys (or clear them)\n"
    printf "  5. Update GoogleService-Info.plist with customer Firebase config\n"
    printf "  6. Build and verify: ${BOLD}xcodebuild build -scheme ElementX -destination 'platform=iOS Simulator,name=iPhone 17 Pro'${NC}\n"
    printf "  7. Run verification:\n"
    printf "     ${CYAN}grep -ri 'element.io' ElementX/Sources/ --include='*.swift' | grep -v Copyright | grep -v '//'${NC}\n"
    printf "     ${CYAN}grep -r 'io.element.elementx' app.yml project.yml ElementX/SupportingFiles/${NC}\n"
fi

printf "\n"
