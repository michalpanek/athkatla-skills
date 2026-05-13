#!/usr/bin/env bash
# scan.sh — Detection-only npm supply-chain scanner.
# All scan inputs are USER-PROVIDED via flag (path, URL, or stdin "-").
# No bundled campaign lists.
#
# Usage:
#   scan.sh --packages <PATH|URL|-> [--iocs <PATH|URL|->]
#                                   [--workflows <PATH|URL|->]
#                                   [--lifecycle <PATH|URL|->]
#                                   [-h | --help]
#
# Inputs (one entry per line, "#" comments, blank lines ignored):
#   packages:    "package@version"  e.g. @scope/pkg@1.2.3
#   iocs:        filename basename  e.g. evil_runner.js
#   workflows:   path glob under .github/workflows/  e.g. .github/workflows/discussion.yaml
#   lifecycle:   keyword substring  e.g. evil_runner
#
# Source forms (for any flag):
#   /path/to/file        local file
#   http(s)://...        fetched via curl or wget
#   -                    read from stdin (only one flag may use stdin per run)
#
# Environment:
#   SUPPLY_SCAN_ROOTS   colon-separated extra roots to scan
#                       (default: $HOME + /usr/local/lib/node_modules + /opt/homebrew/lib/node_modules if present)
#   SUPPLY_SCAN_PRUNE   colon-separated dir basenames to prune
#                       (default: .Trash:Library:.cache:.npm:.pnpm-store:.bun:.yarn)
#
# Exit codes:
#   0  no matches in any provided category
#   1  one or more matches found
#   2  invalid args / missing or empty required input
#
# Compatibility: bash 3.2+ (no associative arrays).
set -euo pipefail

show_help() {
  sed -n '2,32p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

PACKAGES_SRC=""
IOCS_SRC=""
WORKFLOWS_SRC=""
LIFECYCLE_SRC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    --packages)
      [[ -z "${2:-}" ]] && { echo "ERROR: --packages requires a PATH, URL, or -" >&2; exit 2; }
      PACKAGES_SRC="$2"
      shift 2
      ;;
    --iocs)
      [[ -z "${2:-}" ]] && { echo "ERROR: --iocs requires a PATH, URL, or -" >&2; exit 2; }
      IOCS_SRC="$2"
      shift 2
      ;;
    --workflows)
      [[ -z "${2:-}" ]] && { echo "ERROR: --workflows requires a PATH, URL, or -" >&2; exit 2; }
      WORKFLOWS_SRC="$2"
      shift 2
      ;;
    --lifecycle)
      [[ -z "${2:-}" ]] && { echo "ERROR: --lifecycle requires a PATH, URL, or -" >&2; exit 2; }
      LIFECYCLE_SRC="$2"
      shift 2
      ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      show_help >&2
      exit 2
      ;;
  esac
done

if [[ -z "${PACKAGES_SRC}" ]]; then
  echo "ERROR: --packages is required" >&2
  show_help >&2
  exit 2
fi

# Track temp files for cleanup
TMP_FILES=()
cleanup() {
  local f
  for f in "${TMP_FILES[@]}"; do
    [[ -n "${f}" && -f "${f}" ]] && rm -f "${f}"
  done
}
trap cleanup EXIT

STDIN_USED=0

# Resolve a source spec (path / URL / -) to a local file path.
# Echoes the path on stdout. Errors to stderr.
resolve_source() {
  local label="$1"
  local src="$2"
  local out

  if [[ "${src}" == "-" ]]; then
    if [[ "${STDIN_USED}" -eq 1 ]]; then
      echo "ERROR: only one flag may read from stdin (- ); ${label} cannot also use stdin" >&2
      exit 2
    fi
    STDIN_USED=1
    out="$(mktemp)"; TMP_FILES+=("${out}")
    cat > "${out}"
    printf '%s' "${out}"
    return 0
  fi

  if [[ "${src}" =~ ^https?:// ]]; then
    out="$(mktemp)"; TMP_FILES+=("${out}")
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "${src}" -o "${out}"
    elif command -v wget >/dev/null 2>&1; then
      wget -qO "${out}" "${src}"
    else
      echo "ERROR: curl or wget required to fetch ${label} from URL" >&2
      exit 2
    fi
    printf '%s' "${out}"
    return 0
  fi

  if [[ ! -f "${src}" ]]; then
    echo "ERROR: ${label} file not found: ${src}" >&2
    exit 2
  fi
  printf '%s' "${src}"
}

PACKAGES_FILE="$(resolve_source "--packages" "${PACKAGES_SRC}")"
IOCS_FILE=""
WORKFLOWS_FILE=""
LIFECYCLE_FILE=""
[[ -n "${IOCS_SRC}" ]]      && IOCS_FILE="$(resolve_source "--iocs" "${IOCS_SRC}")"
[[ -n "${WORKFLOWS_SRC}" ]] && WORKFLOWS_FILE="$(resolve_source "--workflows" "${WORKFLOWS_SRC}")"
[[ -n "${LIFECYCLE_SRC}" ]] && LIFECYCLE_FILE="$(resolve_source "--lifecycle" "${LIFECYCLE_SRC}")"

cat <<'BANNER' >&2
=========================================================================
SAFETY: detection-only. Do NOT delete node_modules until you have backed
up untracked work and rotated all reachable credentials.
=========================================================================
BANNER

# Normalize packages list into NORM_LIST as "pkg|version" lines; build PKG_INDEX.
NORM_LIST="$(mktemp)"; TMP_FILES+=("${NORM_LIST}")
PKG_INDEX="$(mktemp)"; TMP_FILES+=("${PKG_INDEX}")
TOTAL_ENTRIES=0
while IFS= read -r line || [[ -n "${line}" ]]; do
  line="${line%%#*}"
  line="${line//$'\r'/}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "${line}" ]] && continue
  [[ "${line}" != *"@"* ]] && continue

  pkg="${line%@*}"
  ver="${line##*@}"
  [[ -z "${pkg}" || -z "${ver}" ]] && continue
  [[ "${ver}" =~ ^[0-9] ]] || continue

  printf '%s|%s\n' "${pkg}" "${ver}" >> "${NORM_LIST}"
  printf '%s\n' "${pkg}" >> "${PKG_INDEX}"
  TOTAL_ENTRIES=$((TOTAL_ENTRIES + 1))
done < "${PACKAGES_FILE}"

sort -u "${NORM_LIST}"  -o "${NORM_LIST}"
sort -u "${PKG_INDEX}" -o "${PKG_INDEX}"

UNIQUE_PKGS="$(wc -l < "${PKG_INDEX}" | tr -d ' ')"
if [[ "${TOTAL_ENTRIES}" -eq 0 ]]; then
  echo "ERROR: --packages list is empty or unparseable: ${PACKAGES_SRC}" >&2
  exit 2
fi
echo "Loaded ${TOTAL_ENTRIES} affected entries across ${UNIQUE_PKGS} packages from: ${PACKAGES_SRC}"

# Parse optional IOC filenames into an array
IOC_NAMES=()
if [[ -n "${IOCS_FILE}" ]]; then
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%%#*}"
    line="${line//$'\r'/}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "${line}" ]] && continue
    IOC_NAMES+=("${line}")
  done < "${IOCS_FILE}"
  echo "Loaded ${#IOC_NAMES[@]} IOC filenames from: ${IOCS_SRC}"
fi

# Parse optional workflow path patterns into an array
WORKFLOW_PATTERNS=()
if [[ -n "${WORKFLOWS_FILE}" ]]; then
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%%#*}"
    line="${line//$'\r'/}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "${line}" ]] && continue
    WORKFLOW_PATTERNS+=("${line}")
  done < "${WORKFLOWS_FILE}"
  echo "Loaded ${#WORKFLOW_PATTERNS[@]} workflow path patterns from: ${WORKFLOWS_SRC}"
fi

# Parse optional lifecycle keywords into an array
LIFECYCLE_KEYWORDS=()
if [[ -n "${LIFECYCLE_FILE}" ]]; then
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%%#*}"
    line="${line//$'\r'/}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "${line}" ]] && continue
    LIFECYCLE_KEYWORDS+=("${line}")
  done < "${LIFECYCLE_FILE}"
  echo "Loaded ${#LIFECYCLE_KEYWORDS[@]} lifecycle keywords from: ${LIFECYCLE_SRC}"
fi

# Build root list (de-dup)
RAW_ROOTS=("${HOME}")
[[ -d /usr/local/lib/node_modules ]]    && RAW_ROOTS+=("/usr/local/lib/node_modules")
[[ -d /opt/homebrew/lib/node_modules ]] && RAW_ROOTS+=("/opt/homebrew/lib/node_modules")
if [[ -n "${SUPPLY_SCAN_ROOTS:-}" ]]; then
  IFS=':' read -ra EXTRA <<< "${SUPPLY_SCAN_ROOTS}"
  RAW_ROOTS+=("${EXTRA[@]}")
fi
ROOTS=()
SEEN=""
for r in "${RAW_ROOTS[@]}"; do
  [[ -z "${r}" || ! -d "${r}" ]] && continue
  case ":${SEEN}:" in
    *":${r}:"*) continue ;;
  esac
  SEEN="${SEEN}:${r}"
  ROOTS+=("${r}")
done
[[ ${#ROOTS[@]} -eq 0 ]] && { echo "ERROR: no valid scan roots" >&2; exit 2; }

PRUNE_NAMES="${SUPPLY_SCAN_PRUNE:-.Trash:Library:.cache:.npm:.pnpm-store:.bun:.yarn}"
IFS=':' read -ra PRUNE_ARR <<< "${PRUNE_NAMES}"

PRUNE_EXPR=()
first=1
for name in "${PRUNE_ARR[@]}"; do
  [[ -z "${name}" ]] && continue
  if [[ ${first} -eq 1 ]]; then
    PRUNE_EXPR+=(\( -name "${name}")
    first=0
  else
    PRUNE_EXPR+=(-o -name "${name}")
  fi
done
[[ ${#PRUNE_EXPR[@]} -gt 0 ]] && PRUNE_EXPR+=(\) -prune -o)

echo "Scanning roots: ${ROOTS[*]}"
echo "Pruning: ${PRUNE_NAMES}"
echo

INSTALLED_FILE="$(mktemp)"; TMP_FILES+=("${INSTALLED_FILE}")
LOCK_FILE="$(mktemp)";      TMP_FILES+=("${LOCK_FILE}")
IOC_FILE="$(mktemp)";       TMP_FILES+=("${IOC_FILE}")
WORKFLOW_FILE="$(mktemp)";  TMP_FILES+=("${WORKFLOW_FILE}")
LIFECYCLE_HITS_FILE="$(mktemp)"; TMP_FILES+=("${LIFECYCLE_HITS_FILE}")

scan_package_json() {
  local pj="$1"
  local pkg ver
  pkg="$(awk -F'"' '/"name"[[:space:]]*:/    { print $4; exit }' "${pj}" 2>/dev/null || true)"
  ver="$(awk -F'"' '/"version"[[:space:]]*:/ { print $4; exit }' "${pj}" 2>/dev/null || true)"
  [[ -z "${pkg}" || -z "${ver}" ]] && return 0
  grep -qxF "${pkg}" "${PKG_INDEX}" || return 0
  if grep -qxF "${pkg}|${ver}" "${NORM_LIST}"; then
    printf 'INSTALLED  %s@%s  %s\n' "${pkg}" "${ver}" "${pj}" >> "${INSTALLED_FILE}"
  fi
}

scan_lockfile() {
  local lf="$1"
  local hay
  if [[ "${lf}" == *.lockb ]]; then
    if command -v strings >/dev/null 2>&1; then
      hay="$(strings "${lf}" 2>/dev/null || true)"
    else
      return 0
    fi
  else
    hay="$(cat "${lf}" 2>/dev/null || true)"
  fi
  [[ -z "${hay}" ]] && return 0
  while IFS='|' read -r pkg ver; do
    [[ -z "${pkg}" || -z "${ver}" ]] && continue
    if grep -qF "${pkg}@${ver}" <<< "${hay}" \
       || grep -qF "\"${pkg}\": \"${ver}\"" <<< "${hay}" \
       || grep -qF "\"${pkg}\":\"${ver}\"" <<< "${hay}"; then
      printf 'LOCKFILE   %s@%s  %s\n' "${pkg}" "${ver}" "${lf}" >> "${LOCK_FILE}"
    fi
  done < "${NORM_LIST}"
}

build_name_expr() {
  local -a names=("$@")
  local out=()
  local idx=0
  for n in "${names[@]}"; do
    if [[ ${idx} -eq 0 ]]; then
      out+=(\( -name "${n}")
    else
      out+=(-o -name "${n}")
    fi
    idx=$((idx + 1))
  done
  out+=(\))
  printf '%s\n' "${out[@]}"
}

build_path_expr() {
  local -a patterns=("$@")
  local out=()
  local idx=0
  for p in "${patterns[@]}"; do
    if [[ ${idx} -eq 0 ]]; then
      out+=(\( -path "*/${p}")
    else
      out+=(-o -path "*/${p}")
    fi
    idx=$((idx + 1))
  done
  out+=(\))
  printf '%s\n' "${out[@]}"
}

echo "[step 1] Scanning installed node_modules/**/package.json against --packages list…"
while IFS= read -r -d '' pj; do
  scan_package_json "${pj}"
done < <(find "${ROOTS[@]}" "${PRUNE_EXPR[@]}" \
  -type f \
  \( -path '*/node_modules/*/package.json' -o -path '*/node_modules/@*/*/package.json' \) \
  -print0 2>/dev/null)

echo "[step 2] Scanning lockfiles (package-lock.json, pnpm-lock.yaml, yarn.lock, bun.lock, bun.lockb) against --packages list…"
while IFS= read -r -d '' lf; do
  scan_lockfile "${lf}"
done < <(find "${ROOTS[@]}" "${PRUNE_EXPR[@]}" \
  -type f \
  \( -name package-lock.json -o -name pnpm-lock.yaml -o -name yarn.lock -o -name bun.lock -o -name bun.lockb \) \
  -not -path '*/node_modules/*' \
  -print0 2>/dev/null)

IOC_HITS=0
if [[ ${#IOC_NAMES[@]} -gt 0 ]]; then
  echo "[step 3] Scanning for IOC filenames (${#IOC_NAMES[@]} provided)…"
  ioc_expr=()
  while IFS= read -r line; do ioc_expr+=("${line}"); done < <(build_name_expr "${IOC_NAMES[@]}")
  while IFS= read -r -d '' f; do
    printf 'IOC        %s  %s\n' "$(basename "${f}")" "${f}" >> "${IOC_FILE}"
  done < <(find "${ROOTS[@]}" "${PRUNE_EXPR[@]}" \
    -type f "${ioc_expr[@]}" \
    -print0 2>/dev/null)
fi

WORKFLOW_HITS=0
if [[ ${#WORKFLOW_PATTERNS[@]} -gt 0 ]]; then
  echo "[step 4] Scanning for rogue workflow files (${#WORKFLOW_PATTERNS[@]} pattern(s) provided)…"
  wf_expr=()
  while IFS= read -r line; do wf_expr+=("${line}"); done < <(build_path_expr "${WORKFLOW_PATTERNS[@]}")
  while IFS= read -r -d '' f; do
    printf 'WORKFLOW   %s  %s\n' "$(basename "${f}")" "${f}" >> "${WORKFLOW_FILE}"
  done < <(find "${ROOTS[@]}" "${PRUNE_EXPR[@]}" \
    -type f "${wf_expr[@]}" \
    -print0 2>/dev/null)
fi

LIFECYCLE_HITS=0
if [[ ${#LIFECYCLE_KEYWORDS[@]} -gt 0 ]]; then
  echo "[step 5] Scanning package.json files for suspicious lifecycle scripts (${#LIFECYCLE_KEYWORDS[@]} keyword(s))…"
  # Build alternation regex from keywords (escape special chars by passing them literally;
  # callers should supply safe substrings).
  KW_REGEX=""
  for kw in "${LIFECYCLE_KEYWORDS[@]}"; do
    if [[ -z "${KW_REGEX}" ]]; then
      KW_REGEX="${kw}"
    else
      KW_REGEX="${KW_REGEX}|${kw}"
    fi
  done
  while IFS= read -r -d '' pj; do
    if grep -lE "\"(preinstall|postinstall|prepare)\"[[:space:]]*:[[:space:]]*\"[^\"]*(${KW_REGEX})" "${pj}" >/dev/null 2>&1; then
      name="$(awk -F'"' '/"name"[[:space:]]*:/ { print $4; exit }' "${pj}")"
      printf 'LIFECYCLE  %s  %s\n' "${name:-<unknown>}" "${pj}" >> "${LIFECYCLE_HITS_FILE}"
    fi
  done < <(find "${ROOTS[@]}" "${PRUNE_EXPR[@]}" \
    -type f -name package.json \
    -print0 2>/dev/null)
fi

INSTALLED_HITS="$(wc -l < "${INSTALLED_FILE}"      | tr -d ' ')"
LOCK_HITS="$(wc      -l < "${LOCK_FILE}"           | tr -d ' ')"
IOC_HITS="$(wc       -l < "${IOC_FILE}"            | tr -d ' ')"
WORKFLOW_HITS="$(wc  -l < "${WORKFLOW_FILE}"       | tr -d ' ')"
LIFECYCLE_HITS="$(wc -l < "${LIFECYCLE_HITS_FILE}" | tr -d ' ')"

TOTAL=$((INSTALLED_HITS + LOCK_HITS + IOC_HITS + WORKFLOW_HITS + LIFECYCLE_HITS))

echo
echo "=========================================================================="
echo " SCAN SUMMARY"
echo "  Installed package matches    : ${INSTALLED_HITS}"
echo "  Lockfile pin matches         : ${LOCK_HITS}"
echo "  IOC files                    : ${IOC_HITS}$([[ -z "${IOCS_FILE}" ]] && echo '   (skipped — no --iocs)')"
echo "  Rogue workflow files         : ${WORKFLOW_HITS}$([[ -z "${WORKFLOWS_FILE}" ]] && echo '   (skipped — no --workflows)')"
echo "  Suspicious lifecycle scripts : ${LIFECYCLE_HITS}$([[ -z "${LIFECYCLE_FILE}" ]] && echo '   (skipped — no --lifecycle)')"
echo "=========================================================================="

if [[ "${TOTAL}" -eq 0 ]]; then
  echo "CLEAN — no matches in any provided category."
  exit 0
fi

echo
[[ "${INSTALLED_HITS}" -gt 0 ]] && { echo "=== INSTALLED matches (${INSTALLED_HITS}) ==="; sort -u "${INSTALLED_FILE}";      echo; }
[[ "${LOCK_HITS}"      -gt 0 ]] && { echo "=== LOCKFILE matches (${LOCK_HITS}) ===";       sort -u "${LOCK_FILE}";           echo; }
[[ "${IOC_HITS}"       -gt 0 ]] && { echo "=== IOC files (${IOC_HITS}) ===";                sort -u "${IOC_FILE}";            echo; }
[[ "${WORKFLOW_HITS}"  -gt 0 ]] && { echo "=== Rogue workflow files (${WORKFLOW_HITS}) ===";  sort -u "${WORKFLOW_FILE}";       echo; }
[[ "${LIFECYCLE_HITS}" -gt 0 ]] && { echo "=== Suspicious lifecycle scripts (${LIFECYCLE_HITS}) ==="; sort -u "${LIFECYCLE_HITS_FILE}"; echo; }

cat <<'NEXT'
==========================================================================
MANUAL REMEDIATION REQUIRED (this script does NOT modify or delete anything).
==========================================================================

If "INSTALLED", "LOCKFILE", "IOC", or "LIFECYCLE" reported hits:
  1. Stop all npm / pnpm / yarn / bun operations on the affected project.
  2. Back up untracked work to external storage before any cleanup.
  3. Rotate credentials reachable from the affected machine:
       - npm tokens: `npm token revoke <id>` then `npm login`
       - GitHub Personal Access Tokens
       - AWS / GCP / Azure keys
       - SSH keys (generate new pairs)
       - CI/CD secrets (GitHub Actions, etc.)
       - any credentials in .env files or shell history
  4. In each affected repo (manually):
       Remove node_modules and the lockfile pin.
       `npm cache clean --force`  (or `pnpm store prune`, `yarn cache clean --all`)
       Reinstall pinned to a known-good pre-compromise version.
  5. Run `npm audit signatures` to verify remaining package signatures.
  6. Preserve copies of any IOC files for forensics before deleting them.

If "WORKFLOW" reported hits:
  - Verify manually that the workflow is rogue (filenames may collide with legit files).
  - If confirmed: disable GitHub Actions in affected repos (Settings > Actions > Disable),
    delete unknown self-hosted runners, audit the GitHub account for unknown repositories.

Defensive posture going forward:
  - Pin versions in package.json (strip "^" and "~").
  - Set `ignore-scripts=true` in ~/.npmrc.
  - Consider Socket Firewall (sfw) for npm command wrapping.
  - Prefer pnpm with strict supply-chain settings (https://pnpm.io/supply-chain-security).
NEXT
exit 1
