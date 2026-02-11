#!/bin/bash
#
# rebrand_strings.sh — Localization string replacement for Element X iOS branded fork
#
# Replaces brand name references in InfoPlist.strings (automatic) and generates
# a review report for Localizable.strings (manual review required).
#
# Usage:
#   ./scripts/rebrand_strings.sh --app-name "MyApp" [--old-app-name "Element X"] [--dry-run]
#
# Environment variables (alternative to arguments):
#   APP_NAME       — New app display name (required)
#   OLD_APP_NAME   — Current app name (default: "Element X")
#
# Examples:
#   ./scripts/rebrand_strings.sh --app-name "Acme Chat"
#   ./scripts/rebrand_strings.sh --app-name "Acme Chat" --dry-run
#   APP_NAME="Acme Chat" ./scripts/rebrand_strings.sh
#
# Features:
#   - Replaces "Element X" in InfoPlist.strings across all locales (automatic)
#   - Reports brand references in Localizable.strings (manual review — no auto-modify)
#   - Handles locales with translated brand names (Welsh "Elfen X", Urdu transliteration)
#   - Dry-run mode shows what would change without modifying files
#   - UTF-8 safe, macOS compatible
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCALIZATIONS_DIR="$PROJECT_ROOT/ElementX/Resources/Localizations"
REPORT_DIR="$PROJECT_ROOT/reports"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$REPORT_DIR/rebrand_report_${TIMESTAMP}.txt"

# Default values
DRY_RUN=false
OLD_APP_NAME="${OLD_APP_NAME:-Element X}"

# ============================================================================
# Argument parsing
# ============================================================================

print_usage() {
    cat <<'USAGE'
Usage: rebrand_strings.sh --app-name "NewName" [options]

Required:
  --app-name NAME       New app display name (replaces "Element X")

Options:
  --old-app-name NAME   Current app name to replace (default: "Element X")
  --dry-run             Show what would change without modifying any files
  --help                Show this help message

Environment variables:
  APP_NAME              Alternative to --app-name
  OLD_APP_NAME          Alternative to --old-app-name (default: "Element X")

Examples:
  ./scripts/rebrand_strings.sh --app-name "Acme Chat"
  ./scripts/rebrand_strings.sh --app-name "Acme Chat" --old-app-name "Element X" --dry-run
  APP_NAME="Acme Chat" ./scripts/rebrand_strings.sh
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app-name)
            APP_NAME="$2"
            shift 2
            ;;
        --old-app-name)
            OLD_APP_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "${APP_NAME:-}" ]]; then
    echo "ERROR: APP_NAME is required. Use --app-name or set APP_NAME environment variable."
    echo ""
    print_usage
    exit 1
fi

if [[ "$APP_NAME" == "$OLD_APP_NAME" ]]; then
    echo "ERROR: APP_NAME ('$APP_NAME') is the same as OLD_APP_NAME ('$OLD_APP_NAME'). Nothing to do."
    exit 1
fi

# Validate localizations directory exists
if [[ ! -d "$LOCALIZATIONS_DIR" ]]; then
    echo "ERROR: Localizations directory not found: $LOCALIZATIONS_DIR"
    echo "Are you running this from the project root?"
    exit 1
fi

# ============================================================================
# Known locale-specific brand name translations
# ============================================================================
#
# Some locales translate the brand name into their own script/language.
# These need separate handling because a plain "Element X" search will miss them.
#
# Locale | Translation      | Notes
# -------|-------------------|------
# cy     | Elfen X           | Welsh translation of "Element"
# ur     | ایلیمنٹ ش (X)     | Urdu transliteration
#
# When OLD_APP_NAME is "Element X", we also replace these locale-specific variants.
# For custom OLD_APP_NAME values, only the exact string is replaced.

declare -A LOCALE_BRAND_VARIANTS
if [[ "$OLD_APP_NAME" == "Element X" ]]; then
    LOCALE_BRAND_VARIANTS=(
        ["cy"]="Elfen X"
        ["ur"]="ایلیمنٹ ش (X)"
    )
fi

# ============================================================================
# Counters and tracking
# ============================================================================

INFOPLIST_MODIFIED=0
INFOPLIST_SKIPPED=0
INFOPLIST_NOFILE=0
LOCALIZABLE_REFS_TOTAL=0
LOCALIZABLE_FILES_WITH_REFS=0
LOCALES_PROCESSED=0
LOCALES_WITH_NO_CHANGES=()

# ============================================================================
# Helper functions
# ============================================================================

log_info() {
    echo "[INFO]  $*"
}

log_warn() {
    echo "[WARN]  $*"
}

log_change() {
    echo "[CHANGE] $*"
}

log_dry() {
    echo "[DRY-RUN] $*"
}

log_report() {
    echo "$*" >> "$REPORT_FILE"
}

# Perform string replacement in a .strings file
# Uses perl with \Q..\E for literal (non-regex) matching and -CSD for UTF-8.
# Arguments: $1=file_path, $2=old_string, $3=new_string, $4=locale_name
# Returns: 0 if replacements were made, 1 if no matches found
replace_in_strings_file() {
    local file="$1"
    local old_str="$2"
    local new_str="$3"
    local locale="$4"

    # Check if the file contains the old string (fixed-string grep for safety)
    if ! grep -q -F -- "$old_str" "$file" 2>/dev/null; then
        return 1
    fi

    local match_count
    match_count=$(grep -c -F -- "$old_str" "$file" 2>/dev/null || true)

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would replace '$old_str' -> '$new_str' in $locale/$(basename "$file") ($match_count occurrence(s))"
        # Show before/after for each matching line
        while IFS= read -r line; do
            local new_line="${line//"$old_str"/"$new_str"}"
            echo "         BEFORE: $line"
            echo "         AFTER:  $new_line"
        done < <(grep -F -- "$old_str" "$file" 2>/dev/null)
    else
        # Use perl for the replacement:
        #   -CSD    = handle stdin/stdout/default as UTF-8
        #   -i      = in-place edit (no backup suffix needed on macOS perl)
        #   \Q..\E  = treat old_str as literal (no regex metacharacters)
        # Pass old/new strings via environment variables to avoid shell interpolation issues
        OLD_STR="$old_str" NEW_STR="$new_str" \
            perl -CSD -i -pe 's/\Q$ENV{OLD_STR}\E/$ENV{NEW_STR}/g' "$file"
        log_change "Replaced '$old_str' -> '$new_str' in $locale/$(basename "$file") ($match_count occurrence(s))"
    fi

    return 0
}

# ============================================================================
# Main processing
# ============================================================================

echo "============================================================================"
echo "  Element X iOS — Localization Rebrand Script"
echo "============================================================================"
echo ""
echo "  Old app name:  $OLD_APP_NAME"
echo "  New app name:  $APP_NAME"
echo "  Dry run:       $DRY_RUN"
echo "  Localizations: $LOCALIZATIONS_DIR"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo "  *** DRY RUN MODE — No files will be modified ***"
    echo ""
fi

# Create report directory
mkdir -p "$REPORT_DIR"

# Initialize report
cat > "$REPORT_FILE" <<HEADER
================================================================================
  Rebrand Localization Report
  Generated: $(date)
================================================================================

  Old app name:  $OLD_APP_NAME
  New app name:  $APP_NAME
  Dry run:       $DRY_RUN

================================================================================

HEADER

# ============================================================================
# Phase 1: InfoPlist.strings — Automatic replacement
# ============================================================================

echo "--------------------------------------------------------------------"
echo "  Phase 1: InfoPlist.strings — Automatic Replacement"
echo "--------------------------------------------------------------------"
echo ""

log_report "==== PHASE 1: InfoPlist.strings — Automatic Replacement ===="
log_report ""

# Iterate over all locale directories
for locale_dir in "$LOCALIZATIONS_DIR"/*.lproj; do
    if [[ ! -d "$locale_dir" ]]; then
        continue
    fi

    locale_name=$(basename "$locale_dir" .lproj)
    LOCALES_PROCESSED=$((LOCALES_PROCESSED + 1))
    infoplist_file="$locale_dir/InfoPlist.strings"

    if [[ ! -f "$infoplist_file" ]]; then
        log_info "No InfoPlist.strings in $locale_name — skipping"
        log_report "  [$locale_name] No InfoPlist.strings file"
        INFOPLIST_NOFILE=$((INFOPLIST_NOFILE + 1))
        continue
    fi

    locale_had_changes=false

    # Try standard OLD_APP_NAME replacement
    if replace_in_strings_file "$infoplist_file" "$OLD_APP_NAME" "$APP_NAME" "$locale_name"; then
        locale_had_changes=true
        log_report "  [$locale_name] Replaced '$OLD_APP_NAME' -> '$APP_NAME'"
    fi

    # Try locale-specific brand variant if defined (e.g., Welsh "Elfen X", Urdu transliteration)
    if [[ -n "${LOCALE_BRAND_VARIANTS[$locale_name]+x}" ]]; then
        local_variant="${LOCALE_BRAND_VARIANTS[$locale_name]}"
        if replace_in_strings_file "$infoplist_file" "$local_variant" "$APP_NAME" "$locale_name"; then
            locale_had_changes=true
            log_report "  [$locale_name] Replaced locale variant '$local_variant' -> '$APP_NAME'"
        fi
    fi

    if [[ "$locale_had_changes" == true ]]; then
        INFOPLIST_MODIFIED=$((INFOPLIST_MODIFIED + 1))
    else
        INFOPLIST_SKIPPED=$((INFOPLIST_SKIPPED + 1))
        log_info "No '$OLD_APP_NAME' found in $locale_name/InfoPlist.strings — no changes needed"
        log_report "  [$locale_name] No matches found"
        LOCALES_WITH_NO_CHANGES+=("$locale_name (InfoPlist)")
    fi
done

echo ""

# ============================================================================
# Phase 2: Localizable.strings — Report only (no auto-modification)
# ============================================================================

echo "--------------------------------------------------------------------"
echo "  Phase 2: Localizable.strings — Brand Reference Report"
echo "--------------------------------------------------------------------"
echo ""
echo "  NOTE: Localizable.strings files are NOT modified automatically."
echo "  This phase generates a report for manual review."
echo ""

log_report ""
log_report "==== PHASE 2: Localizable.strings — Brand Reference Report ===="
log_report ""
log_report "  These references require manual review before modification."
log_report "  Some may be internal identifiers, product names (Element Call,"
log_report "  Element Pro), or server-specific strings that should not be"
log_report "  blindly replaced."
log_report ""

# Define search patterns — order matters (most specific first)
SEARCH_TERMS=(
    "Element X"
    "Element Pro"
    "Element Call"
    "element.io"
    "Element"
)

for locale_dir in "$LOCALIZATIONS_DIR"/*.lproj; do
    if [[ ! -d "$locale_dir" ]]; then
        continue
    fi

    locale_name=$(basename "$locale_dir" .lproj)
    localizable_file="$locale_dir/Localizable.strings"

    if [[ ! -f "$localizable_file" ]]; then
        continue
    fi

    locale_refs=0
    locale_output=""

    for term in "${SEARCH_TERMS[@]}"; do
        # Search for the term in string values (right side of = in .strings files)
        matches=$(grep -n -F -- "$term" "$localizable_file" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            match_count=$(echo "$matches" | wc -l | tr -d ' ')
            locale_refs=$((locale_refs + match_count))
            locale_output+="    Pattern: \"$term\" ($match_count match(es))"
            locale_output+=$'\n'
            while IFS= read -r match_line; do
                locale_output+="      $match_line"
                locale_output+=$'\n'
            done <<< "$matches"
            locale_output+=$'\n'
        fi
    done

    if [[ $locale_refs -gt 0 ]]; then
        LOCALIZABLE_FILES_WITH_REFS=$((LOCALIZABLE_FILES_WITH_REFS + 1))
        # Avoid double-counting: unique lines only
        unique_refs=$(grep -c -F -e "Element X" -e "Element Pro" -e "Element Call" -e "element.io" -e "Element" "$localizable_file" 2>/dev/null || echo "0")
        LOCALIZABLE_REFS_TOTAL=$((LOCALIZABLE_REFS_TOTAL + unique_refs))

        log_report "  [$locale_name] Localizable.strings — $unique_refs unique line(s) with brand references:"
        log_report "$locale_output"
    fi
done

# ============================================================================
# Phase 3: Localizable.strings key-level analysis (English only, for guidance)
# ============================================================================

log_report ""
log_report "==== PHASE 3: English Localizable.strings — Detailed Analysis ===="
log_report ""
log_report "  The following string keys contain brand references in their values."
log_report "  Review each and decide whether to replace:"
log_report ""
log_report "  CATEGORY A — User-facing strings with 'Element X' (likely replace):"
log_report "  -------------------------------------------------------------------"

en_localizable="$LOCALIZATIONS_DIR/en.lproj/Localizable.strings"
if [[ -f "$en_localizable" ]]; then
    # Element X references
    elementx_matches=$(grep -n -F "Element X" "$en_localizable" 2>/dev/null || true)
    if [[ -n "$elementx_matches" ]]; then
        while IFS= read -r line; do
            log_report "    $line"
        done <<< "$elementx_matches"
    else
        log_report "    (none found)"
    fi

    log_report ""
    log_report "  CATEGORY B — 'Element Pro' references (product name — review carefully):"
    log_report "  -----------------------------------------------------------------------"
    elementpro_matches=$(grep -n -F "Element Pro" "$en_localizable" 2>/dev/null || true)
    if [[ -n "$elementpro_matches" ]]; then
        while IFS= read -r line; do
            log_report "    $line"
        done <<< "$elementpro_matches"
    else
        log_report "    (none found)"
    fi

    log_report ""
    log_report "  CATEGORY C — 'Element Call' references (feature name — review carefully):"
    log_report "  ------------------------------------------------------------------------"
    elementcall_matches=$(grep -n -F "Element Call" "$en_localizable" 2>/dev/null || true)
    if [[ -n "$elementcall_matches" ]]; then
        while IFS= read -r line; do
            log_report "    $line"
        done <<< "$elementcall_matches"
    else
        log_report "    (none found)"
    fi

    log_report ""
    log_report "  CATEGORY D — 'element.io' references (URL/server — review carefully):"
    log_report "  ---------------------------------------------------------------------"
    elementio_matches=$(grep -n -F "element.io" "$en_localizable" 2>/dev/null || true)
    if [[ -n "$elementio_matches" ]]; then
        while IFS= read -r line; do
            log_report "    $line"
        done <<< "$elementio_matches"
    else
        log_report "    (none found)"
    fi

    log_report ""
    log_report "  CATEGORY E — Standalone 'Element' (may be partial match — review carefully):"
    log_report "  --------------------------------------------------------------------------"
    # Find "Element" that is NOT part of "Element X", "Element Pro", "Element Call", or "element.io"
    element_standalone=$(grep -n "Element" "$en_localizable" 2>/dev/null | grep -v -F "Element X" | grep -v -F "Element Pro" | grep -v -F "Element Call" | grep -v -F "element.io" || true)
    if [[ -n "$element_standalone" ]]; then
        while IFS= read -r line; do
            log_report "    $line"
        done <<< "$element_standalone"
    else
        log_report "    (none found)"
    fi
fi

# ============================================================================
# Phase 4: Check for locale-specific translated brand names in Localizable.strings
# ============================================================================

log_report ""
log_report "==== PHASE 4: Locale-specific Brand Name Translations ===="
log_report ""
log_report "  Some locales translate 'Element X' into their own script."
log_report "  These require locale-specific handling:"
log_report ""

for locale in "${!LOCALE_BRAND_VARIANTS[@]}"; do
    variant="${LOCALE_BRAND_VARIANTS[$locale]}"
    variant_localizable="$LOCALIZATIONS_DIR/${locale}.lproj/Localizable.strings"
    if [[ -f "$variant_localizable" ]]; then
        variant_matches=$(grep -c -F -- "$variant" "$variant_localizable" 2>/dev/null || echo "0")
        log_report "  [$locale] '$variant' — $variant_matches occurrence(s) in Localizable.strings"
    fi

    variant_infoplist="$LOCALIZATIONS_DIR/${locale}.lproj/InfoPlist.strings"
    if [[ -f "$variant_infoplist" ]]; then
        variant_info_matches=$(grep -c -F -- "$variant" "$variant_infoplist" 2>/dev/null || echo "0")
        log_report "  [$locale] '$variant' — $variant_info_matches occurrence(s) in InfoPlist.strings"
    fi
done

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "============================================================================"
echo "  Summary"
echo "============================================================================"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo "  *** DRY RUN — No files were modified ***"
    echo ""
fi

echo "  InfoPlist.strings:"
echo "    Modified:              $INFOPLIST_MODIFIED locale(s)"
echo "    No matches found:      $INFOPLIST_SKIPPED locale(s)"
echo "    No InfoPlist.strings:  $INFOPLIST_NOFILE locale(s)"
echo ""
echo "  Localizable.strings (report only — NOT modified):"
echo "    Files with brand refs: $LOCALIZABLE_FILES_WITH_REFS"
echo "    Total reference lines: $LOCALIZABLE_REFS_TOTAL"
echo ""
echo "  Total locales processed: $LOCALES_PROCESSED"

if [[ ${#LOCALES_WITH_NO_CHANGES[@]} -gt 0 ]]; then
    echo ""
    echo "  Locales with no InfoPlist.strings changes (review manually):"
    for lnc in "${LOCALES_WITH_NO_CHANGES[@]}"; do
        echo "    - $lnc"
    done
fi

echo ""
echo "  Full report: $REPORT_FILE"
echo ""

# Write summary to report
log_report ""
log_report "==== SUMMARY ===="
log_report ""
if [[ "$DRY_RUN" == true ]]; then
    log_report "  *** DRY RUN — No files were modified ***"
    log_report ""
fi
log_report "  Old app name: $OLD_APP_NAME"
log_report "  New app name: $APP_NAME"
log_report ""
log_report "  InfoPlist.strings:"
log_report "    Modified:              $INFOPLIST_MODIFIED locale(s)"
log_report "    No matches found:      $INFOPLIST_SKIPPED locale(s)"
log_report "    No InfoPlist.strings:  $INFOPLIST_NOFILE locale(s)"
log_report ""
log_report "  Localizable.strings (report only — NOT modified):"
log_report "    Files with brand refs: $LOCALIZABLE_FILES_WITH_REFS"
log_report "    Total reference lines: $LOCALIZABLE_REFS_TOTAL"
log_report ""
log_report "  Total locales processed: $LOCALES_PROCESSED"
if [[ ${#LOCALES_WITH_NO_CHANGES[@]} -gt 0 ]]; then
    log_report ""
    log_report "  Locales with no InfoPlist.strings changes:"
    for lnc in "${LOCALES_WITH_NO_CHANGES[@]}"; do
        log_report "    - $lnc"
    done
fi
log_report ""
log_report "================================================================================  "
log_report "  End of report"
log_report "================================================================================"

echo "Done."
