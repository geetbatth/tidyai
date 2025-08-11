#!/usr/bin/env bash
# ==============================================================================
# TIDYAI - INTELLIGENT FOLDER ORGANIZATION TOOL (macOS/Linux Shell Port)
# Version: 2.1.0 (OpenAI-compatible provider support)
# Dependencies: bash, curl, jq
# Environment:
#   export TidyAIOpenAIAPIKey="your-openai-key"             # legacy var (kept)
#   export TIDYAI_API_KEY="your-key"                        # new preferred var
#   export TIDYAI_PROVIDER="openai|openrouter|azure|..."    # optional
#   export TIDYAI_API_BASE="https://api.openai.com"         # optional
#   export TIDYAI_API_PATH="/v1/chat/completions"           # optional
#   export TIDYAI_MODEL="gpt-4o-mini"                       # optional
#   export TIDYAI_AUTH_HEADER="Authorization"               # optional
#   export TIDYAI_AUTH_SCHEME="Bearer"                      # optional ('' for none)
#   export AZURE_API_VERSION="2024-02-15-preview"           # optional (azure)
# Run:
#   ./tidyai.sh [provider/options] "/path/to/folder"
# ==============================================================================

set -Eeuo pipefail

# ----------------------------
# Colors and UI helpers
# ----------------------------
COLOR_RESET=$'\033[0m'
COLOR_PRIMARY=$'\033[31m'   # DarkRed-ish
COLOR_SECONDARY=$'\033[33m' # Yellow
COLOR_SUCCESS=$'\033[32m'   # Green
COLOR_WARNING=$'\033[33m'   # Yellow
COLOR_ERROR=$'\033[31m'     # Red
COLOR_INFO=$'\033[37m'      # White
COLOR_ACCENT=$'\033[33m'    # DarkYellow-ish

color_echo() {
  local color="${2:-$COLOR_INFO}"
  if [[ "${3:-}" == "-n" ]]; then
    printf "%s%s%s" "${color}" "$1" "${COLOR_RESET}"
  else
    printf "%s%s%s\n" "${color}" "$1" "${COLOR_RESET}"
  fi
}

show_logo() {
  clear || true
  echo ""
  color_echo "    ############ #### ########   ####  ####     ##########    ####" "$COLOR_PRIMARY"
  color_echo "    ############ #### ########   ####  ####     ##########    ####" "$COLOR_PRIMARY"
  color_echo "        ####     #### ####  #### ####  ####     ####  ####    ####" "$COLOR_PRIMARY"
  color_echo "        ####     #### ####  #### ####  ####     ####  ####    ####" "$COLOR_ACCENT"
  color_echo "        ####     #### ####  ####  ########      ##########    ####" "$COLOR_ACCENT"
  color_echo "        ####     #### ####  ####   ######       ##########    ####" "$COLOR_ACCENT"
  color_echo "        ####     #### ####  ####    ####        ####  ####    ####" "$COLOR_SECONDARY"
  color_echo "        ####     #### ########      ####        ####  ####    ####" "$COLOR_SECONDARY"
  color_echo "        ####     #### ########      ####        ####  #### ## ####" "$COLOR_SECONDARY"
  echo ""
}

# ----------------------------
# Provider/Model configuration (defaults + env)
# ----------------------------
DEFAULT_API_BASE="https://api.openai.com"
DEFAULT_API_PATH="/v1/chat/completions"

PROVIDER="${TIDYAI_PROVIDER:-openai}"
API_BASE="${TIDYAI_API_BASE:-$DEFAULT_API_BASE}"
API_PATH="${TIDYAI_API_PATH:-$DEFAULT_API_PATH}"
MODEL_NAME="${TIDYAI_MODEL:-gpt-4o-mini}"
AUTH_HEADER="${TIDYAI_AUTH_HEADER:-Authorization}"
AUTH_SCHEME="${TIDYAI_AUTH_SCHEME:-Bearer}"
AZURE_API_VERSION="${AZURE_API_VERSION:-2024-02-15-preview}"

# API key resolution (prefer new var, fallback to legacy)
OPENAI_API_KEY="${TIDYAI_API_KEY:-${TidyAIOpenAIAPIKey:-}}"

configure_provider() {
  # Set sensible defaults for known providers unless overridden by explicit flags/env
  local p="${1:-$PROVIDER}"
  case "$p" in
    openai)
      API_BASE="${API_BASE:-$DEFAULT_API_BASE}"
      API_PATH="${API_PATH:-$DEFAULT_API_PATH}"
      AUTH_HEADER="${AUTH_HEADER:-Authorization}"
      AUTH_SCHEME="${AUTH_SCHEME:-Bearer}"
      ;;
    openrouter)
      API_BASE="${API_BASE:-https://openrouter.ai/api}"
      API_PATH="${API_PATH:-/v1/chat/completions}"
      AUTH_HEADER="${AUTH_HEADER:-Authorization}"
      AUTH_SCHEME="${AUTH_SCHEME:-Bearer}"
      ;;
    groq)
      API_BASE="${API_BASE:-https://api.groq.com/openai}"
      API_PATH="${API_PATH:-/v1/chat/completions}"
      AUTH_HEADER="${AUTH_HEADER:-Authorization}"
      AUTH_SCHEME="${AUTH_SCHEME:-Bearer}"
      ;;
    fireworks)
      API_BASE="${API_BASE:-https://api.fireworks.ai/openai}"
      API_PATH="${API_PATH:-/v1/chat/completions}"
      AUTH_HEADER="${AUTH_HEADER:-Authorization}"
      AUTH_SCHEME="${AUTH_SCHEME:-Bearer}"
      ;;
    together)
      API_BASE="${API_BASE:-https://api.together.xyz}"
      API_PATH="${API_PATH:-/v1/chat/completions}"
      AUTH_HEADER="${AUTH_HEADER:-Authorization}"
      AUTH_SCHEME="${AUTH_SCHEME:-Bearer}"
      ;;
    perplexity)
      API_BASE="${API_BASE:-https://api.perplexity.ai}"
      API_PATH="${API_PATH:-/v1/chat/completions}"
      AUTH_HEADER="${AUTH_HEADER:-Authorization}"
      AUTH_SCHEME="${AUTH_SCHEME:-Bearer}"
      ;;
    deepseek)
      API_BASE="${API_BASE:-https://api.deepseek.com}"
      API_PATH="${API_PATH:-/v1/chat/completions}"
      AUTH_HEADER="${AUTH_HEADER:-Authorization}"
      AUTH_SCHEME="${AUTH_SCHEME:-Bearer}"
      ;;
    lmstudio)
      API_BASE="${API_BASE:-http://localhost:1234}"
      API_PATH="${API_PATH:-/v1/chat/completions}"
      AUTH_HEADER="${AUTH_HEADER:-Authorization}"
      AUTH_SCHEME="${AUTH_SCHEME:-Bearer}"
      ;;
    localai|vllm)
      API_BASE="${API_BASE:-http://localhost:8000}"
      API_PATH="${API_PATH:-/v1/chat/completions}"
      AUTH_HEADER="${AUTH_HEADER:-Authorization}"
      AUTH_SCHEME="${AUTH_SCHEME:-Bearer}"
      ;;
    azure)
      # For Azure: set API_BASE to https://{resource}.openai.azure.com
      # MODEL_NAME should be deployment name; we build the path with deployment and api-version
      API_BASE="${API_BASE:-}"
      if [[ -z "$API_BASE" ]]; then
        color_echo "Azure selected but TIDYAI_API_BASE/--api-base not set (e.g., https://<resource>.openai.azure.com)" "$COLOR_WARNING"
      fi
      API_PATH="${API_PATH:-/openai/deployments/${MODEL_NAME}/chat/completions?api-version=${AZURE_API_VERSION}}"
      AUTH_HEADER="${AUTH_HEADER:-api-key}"
      AUTH_SCHEME="${AUTH_SCHEME:-}" # no 'Bearer' for Azure
      ;;
    *)
      # Unknown: treat as generic OpenAI-compatible; user must supply base/path if needed
      API_BASE="${API_BASE:-$DEFAULT_API_BASE}"
      API_PATH="${API_PATH:-$DEFAULT_API_PATH}"
      AUTH_HEADER="${AUTH_HEADER:-Authorization}"
      AUTH_SCHEME="${AUTH_SCHEME:-Bearer}"
      ;;
  esac
}

# ----------------------------
# CLI args parsing
# ----------------------------
FOLDER_ARG=""
parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      --provider)
        PROVIDER="$2"; shift 2 ;;
      --api-base)
        API_BASE="$2"; shift 2 ;;
      --api-path)
        API_PATH="$2"; shift 2 ;;
      --model)
        MODEL_NAME="$2"; shift 2 ;;
      --api-key)
        OPENAI_API_KEY="$2"; shift 2 ;;
      --api-key-env)
        # read key from provided env var name at runtime
        local var="$2"; OPENAI_API_KEY="${!var:-}"; shift 2 ;;
      --auth-header)
        AUTH_HEADER="$2"; shift 2 ;;
      --auth-scheme)
        AUTH_SCHEME="$2"; shift 2 ;;
      --azure-api-version)
        AZURE_API_VERSION="$2"; shift 2 ;;
      -h|--help)
        usage; exit 0 ;;
      --) shift; break ;;
      -*)
        color_echo "Unknown option: $1" "$COLOR_ERROR"; usage; exit 1 ;;
      *)
        # First non-flag is folder path; rest (if any) ignored
        if [[ -z "$FOLDER_ARG" ]]; then
          FOLDER_ARG="$1"; shift
        else
          shift
        fi
        ;;
    esac
  done
}

# ----------------------------
# Env/dependency checks
# ----------------------------
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    color_echo "Error: required command '$1' not found." "$COLOR_ERROR"
    if [[ "$1" == "jq" ]]; then
      color_echo "Install jq: macOS: brew install jq | Ubuntu/Debian: sudo apt-get install -y jq | Arch: sudo pacman -S jq" "$COLOR_INFO"
    elif [[ "$1" == "curl" ]]; then
      color_echo "Install curl: macOS: brew install curl | Ubuntu/Debian: sudo apt-get install -y curl" "$COLOR_INFO"
    fi
    exit 1
  }
}

check_env() {
  require_cmd "curl"
  require_cmd "jq"
  if [[ -z "${OPENAI_API_KEY}" ]]; then
    color_echo "Error: API key not configured!" "$COLOR_ERROR"
    echo ""
    color_echo "Set one of:" "$COLOR_INFO"
    color_echo "  export TIDYAI_API_KEY=\"your-key\"               # preferred" "$COLOR_ACCENT"
    color_echo "  export TidyAIOpenAIAPIKey=\"your-key\"           # legacy (kept for compat)" "$COLOR_ACCENT"
    color_echo "Or pass --api-key or --api-key-env ENVVAR" "$COLOR_INFO"
    exit 1
  fi
  if [[ -z "${API_BASE}" || -z "${API_PATH}" ]]; then
    color_echo "Error: API base/path not set." "$COLOR_ERROR"
    color_echo "Got base='${API_BASE:-}' path='${API_PATH:-}' provider='$PROVIDER'." "$COLOR_WARNING"
    color_echo "Set via --api-base/--api-path or env TIDYAI_API_BASE/TIDYAI_API_PATH." "$COLOR_INFO"
    exit 1
  fi
}

# Computed after parsing + provider selection
OPENAI_API_URL=""  # will be API_BASE + API_PATH

# ----------------------------
# Portable stat helpers (Linux/macOS)
# ----------------------------
stat_size() {
  local path="$1"
  if stat -c %s "$path" >/dev/null 2>&1; then
    stat -c %s "$path"
  else
    stat -f %z "$path"
  fi
}
stat_mtime_epoch() {
  local path="$1"
  if stat -c %Y "$path" >/dev/null 2>&1; then
    stat -c %Y "$path"
  else
    stat -f %m "$path"
  fi
}

json_escape() {
  # minimal JSON string escaper
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

file_ext() {
  local name="$1"
  local base="${name##*/}"
  if [[ "$base" == .* && "$base" != ".bashrc" && "$base" != ".zshrc" ]]; then
    # hidden file without extension perhaps
    echo ""
    return
  fi
  if [[ "$base" == *.* ]]; then
    echo ".${base##*.}"
  else
    echo ""
  fi
}

file_emoji() {
  # ASCII-style tags (no emoji for terminal compatibility)
  local ext="${1,,}"
  case "$ext" in
    ".txt") echo "[TXT]" ;;
    ".doc"|".docx") echo "[DOC]" ;;
    ".pdf") echo "[PDF]" ;;
    ".jpg"|".jpeg"|".png"|".gif") echo "[IMG]" ;;
    ".mp4"|".avi"|".mkv") echo "[VID]" ;;
    ".mp3"|".wav") echo "[AUD]" ;;
    ".zip"|".rar") echo "[ZIP]" ;;
    ".exe"|".msi") echo "[EXE]" ;;
    ".lnk") echo "[LNK]" ;;
    ".cmd") echo "[CMD]" ;;
    ".py") echo "[PY]" ;;
    ".js") echo "[JS]" ;;
    ".html") echo "[HTM]" ;;
    ".css") echo "[CSS]" ;;
    ".json") echo "[JSN]" ;;
    ".xml") echo "[XML]" ;;
    ".csv") echo "[CSV]" ;;
    ".xlsx"|".xls") echo "[XLS]" ;;
    "folder") echo "[DIR]" ;;
    *) echo "[FILE]" ;;
  esac
}

# ----------------------------
# Undo System (.tidyai file)
# ----------------------------
undo_file_path() {
  local target="$1"
  printf "%s/.tidyai" "$target"
}

undo_exists() {
  [[ -f "$(undo_file_path "$1")" ]]
}

save_undo_state() {
  local target="$1"
  local original_json="$2"  # array of {name,type,fullPath}
  local new_structure="$3"  # AI structure array
  local ts
  ts="$(date "+%Y-%m-%d %H:%M:%S")"
  local payload
  payload="$(jq -n \
    --arg ts "$ts" \
    --arg tp "$target" \
    --arg ver "2.1.0" \
    --argjson orig "$original_json" \
    --argjson new "$new_structure" \
    '{timestamp:$ts, targetPath:$tp, originalStructure:$orig, newStructure:$new, version:$ver}'
  )"
  printf "%s" "$payload" >"$(undo_file_path "$target")"
  color_echo "Undo information saved successfully" "$COLOR_SUCCESS"
}

invoke_undo() {
  local target="$1"
  color_echo "Starting undo operation..." "$COLOR_INFO"
  local undo_file
  undo_file="$(undo_file_path "$target")"
  if [[ ! -f "$undo_file" ]]; then
    color_echo "No undo data found" "$COLOR_ERROR"
    return 1
  fi

  local restored=0 skipped=0
  color_echo "Restoring original folder structure..." "$COLOR_INFO"
  color_echo "Organization from: $(jq -r '.timestamp' "$undo_file")" "$COLOR_ACCENT"

  # Iterate subfolders (exclude .tidyai)
  local item
  shopt -s dotglob nullglob
  for item in "$target"/*; do
    [[ "$(basename "$item")" == ".tidyai" ]] && continue
    if [[ -d "$item" ]]; then
      color_echo "  Processing folder: $(basename "$item")" "$COLOR_ACCENT"
      local content
      for content in "$item"/* "$item"/.*; do
        [[ "$(basename "$content")" == "." || "$(basename "$content")" == ".." ]] && continue
        [[ ! -e "$content" ]] && continue
        local dest="$target/$(basename "$content")"
        if [[ -e "$dest" ]]; then
          color_echo "    Conflict: $(basename "$content") already exists in root - overwriting" "$COLOR_WARNING"
          rm -rf -- "$dest"
        fi
        mv -f -- "$content" "$dest" && {
          color_echo "    Restored: $(basename "$dest")" "$COLOR_INFO"
          ((restored++)) || true
        } || {
          color_echo "    Failed to restore: $(basename "$content")" "$COLOR_ERROR"
          ((skipped++)) || true
        }
      done
      # Remove empty folder
      rmdir "$item" 2>/dev/null && color_echo "    Removed empty folder: $(basename "$item")" "$COLOR_SUCCESS" || true
    fi
  done
  shopt -u dotglob nullglob

  color_echo "Restoration summary: $restored files restored, $skipped failed" "$COLOR_INFO"
  rm -f -- "$undo_file"
  color_echo "Undo completed successfully! Original folder structure has been restored." "$COLOR_SUCCESS"
}

show_undo_prompt_if_any() {
  local target="$1"
  if ! undo_exists "$target"; then
    return 0
  fi
  local undo_file
  undo_file="$(undo_file_path "$target")"
  color_echo "========================================" "$COLOR_PRIMARY"
  color_echo "TIDYAI WAS HERE BEFORE!" "$COLOR_WARNING"
  color_echo "========================================" "$COLOR_PRIMARY"
  color_echo "This folder was organized on: $(jq -r '.timestamp' "$undo_file")" "$COLOR_INFO"
  color_echo "Path: $(jq -r '.targetPath' "$undo_file")" "$COLOR_ACCENT"
  echo ""
  color_echo "What would you like to do?" "$COLOR_INFO"
  color_echo "  [Y] Undo - Restore the original messy structure" "$COLOR_WARNING"
  color_echo "  [N] Continue - Organize again with fresh AI suggestions" "$COLOR_SUCCESS"
  echo -n "${COLOR_INFO}Your choice (Y/N): ${COLOR_RESET}"
  read -r resp
  if [[ "$resp" =~ ^[Yy]$ ]]; then
    invoke_undo "$target" || true
    return 2
  else
    color_echo "Keeping current organization. Continuing with new organization..." "$COLOR_INFO"
    rm -f -- "$undo_file" || true
    return 0
  fi
}

# ----------------------------
# Scanner (non-recursive)
# ----------------------------
scan_folder() {
  local target="$1"
  color_echo "Scanning folder: $target" "$COLOR_INFO" >&2
  echo "" >&2

  local items_json="[]"
  local total=0 processed=0

  shopt -s dotglob nullglob
  local entry
  # include hidden items, exclude '.' and '..'
  for entry in "$target"/* "$target"/.*; do
    local base
    base="$(basename "$entry")"
    if [[ "$base" == "." || "$base" == ".." ]]; then
      continue
    fi
    ((total++)) || true
  done

  processed=0
  for entry in "$target"/* "$target"/.*; do
    local base
    base="$(basename "$entry")"
    if [[ "$base" == "." || "$base" == ".." ]]; then
      continue
    fi
    ((processed++)) || true
    local pct=$(( processed * 100 / (total==0?1:total) ))
    # Simple textual progress every 25%
    if (( processed % 50 == 0 || pct == 25 || pct == 50 || pct == 75 || pct == 90 || pct == 100 )); then
      local barw=40
      local filled=$(( pct * barw / 100 ))
      local empty=$(( barw - filled ))
      printf "\r[%s%s] %d%% (%d/%d)" "$(printf '#%.0s' $(seq 1 $filled))" "$(printf -- '-%.0s' $(seq 1 $empty))" "$pct" "$processed" "$total" >&2
    fi

    if [[ -d "$entry" ]]; then
      # Folder metadata (direct children only)
      local files_count=0 subfolders_count=0
      local child
      for child in "$entry"/* "$entry"/.*; do
        local cbase
        cbase="$(basename "$child")"
        [[ "$cbase" == "." || "$cbase" == ".." ]] && continue
        [[ ! -e "$child" ]] && continue
        if [[ -d "$child" ]]; then
          ((subfolders_count++)) || true
        else
          ((files_count++)) || true
        fi
      done
      # sample up to 5 files (first 5)
      local samples_json="[]"
      local count=0
      for child in "$entry"/* "$entry"/.*; do
        local cbase
        cbase="$(basename "$child")"
        [[ "$cbase" == "." || "$cbase" == ".." ]] && continue
        [[ ! -e "$child" ]] && continue
        if [[ -f "$child" ]]; then
          local sname="$cbase"
          local sext
          sext="$(file_ext "$sname")"
          local ssize
          ssize="$(stat_size "$child" 2>/dev/null || echo 0)"
          # Ensure ssize is a valid number
          if ! [[ "$ssize" =~ ^[0-9]+$ ]]; then
            ssize=0
          fi
          local sitem
          sitem="$(jq -n --arg name "$sname" --arg ext "$sext" --argjson size "$ssize" '{name:$name, extension:$ext, size:$size}')"
          samples_json="$(jq -c --argjson obj "$sitem" '. + [$obj]' <<<"$samples_json")"
          ((count++)) || true
          if (( count >= 5 )); then
            break
          fi
        fi
      done
      local mtime
      mtime="$(stat_mtime_epoch "$entry" 2>/dev/null || echo 0)"
      local now
      now="$(date +%s)"
      local thirty=$((30*24*3600))
      local age="old"
      if (( now - mtime < thirty )); then age="recent"; fi

      local item
      item="$(jq -n \
        --arg name "$base" \
        --arg type "folder" \
        --argjson fileCount "$files_count" \
        --argjson subfolderCount "$subfolders_count" \
        --argjson isEmpty "$([[ $files_count -eq 0 && $subfolders_count -eq 0 ]] && echo true || echo false)" \
        --argjson sampleFiles "$samples_json" \
        --arg age "$age" \
        '{name:$name,type:$type,fileCount:$fileCount,subfolderCount:$subfolderCount,isEmpty:$isEmpty,sampleFiles:$sampleFiles,age:$age}'
      )"
      items_json="$(jq -c --argjson obj "$item" '. + [$obj]' <<<"$items_json")"
    else
      # File info
      local size
      size="$(stat_size "$entry" 2>/dev/null || echo 0)"
      local fname="$base"
      local ext
      ext="$(file_ext "$fname")"
      local mtime
      mtime="$(stat_mtime_epoch "$entry" 2>/dev/null || echo 0)"
      local now
      now="$(date +%s)"
      local thirty=$((30*24*3600))
      local age="old"
      if (( now - mtime < thirty )); then age="recent"; fi
      local sizeClass="small"
      if (( size > 100*1024*1024 )); then sizeClass="large"
      elif (( size > 10*1024*1024 )); then sizeClass="medium"
      fi
      local item
      item="$(jq -n \
        --arg name "$fname" \
        --arg type "file" \
        --arg ext "$ext" \
        --arg sizeClass "$sizeClass" \
        --arg age "$age" \
        '{name:$name,type:$type,ext:$ext,size:$sizeClass,age:$age}'
      )"
      items_json="$(jq -c --argjson obj "$item" '. + [$obj]' <<<"$items_json")"
    fi
  done
  shopt -u dotglob nullglob
  echo "" >&2
  color_echo "Scanned $total items successfully!" "$COLOR_SUCCESS" >&2
  echo "" >&2

  printf '%s' "$items_json"
}

build_batch_json() {
  local items_json="$1"     # array
  local existing_json="$2"  # array of {folderName}
  local context="${3:-General}"
  local existing_names
  existing_names="$(jq -c '[ .[].folderName ]' <<<"${existing_json:-[]}" 2>/dev/null || echo "[]")"
  local count
  count="$(jq 'length' <<<"$items_json")"
  jq -n --argjson items "$items_json" --argjson existing "$existing_names" --arg ctx "$context" --argjson count "$count" \
     '{items:$items, count:$count, existingFolders:$existing, context:$ctx}'
}

# ----------------------------
# OpenAI-Compatible Communication
# ----------------------------
invoke_openai() {
  local json_data="$1"        # batch json
  local request_type="$2"     # batch | recovery | conflict
  local existing_folders="$3" # array of names
  local batch_number="${4:-1}"

  local system_message=""
  local prompt=""
  if [[ "$request_type" == "batch" ]]; then
    system_message="You are TidyAI, an intelligent file organization expert. Analyze file names and size, patterns, dates, projects, and purposes. Create meaningful folder structures based on content similarity and purpose, not just file extensions. Think like a human organizing their digital workspace - group related files together."
    local fileCount folderCount totalCount
    fileCount="$(jq '[.items[] | select(.type=="file")] | length' <<<"$json_data")"
    folderCount="$(jq '[.items[] | select(.type=="folder")] | length' <<<"$json_data")"
    totalCount=$(( fileCount + folderCount ))
    local existing_text="No existing folders - create new structure"
    if [[ "$(jq '(.existingFolders|length)>0' <<<"$json_data")" == "true" ]]; then
      existing_text="Existing folders to reuse: $(jq -r '.existingFolders|join(", ")' <<<"$json_data")"
    fi

    read -r -d '' prompt <<EOF || true
Organize these $totalCount items ($fileCount files and $folderCount folders) into logical, intelligent folders based on content patterns and purpose.

ORGANIZATION PRINCIPLES:
- Each item appears in EXACTLY ONE folder (zero duplicates allowed)
- Preserve ALL original filenames exactly as provided
- Create 3-8 meaningful folders with descriptive names
- Group by purpose, project, or content type
- Avoid generic names like "Other" or "Miscellaneous"
- Consider file extensions, names, dates, and folder contents for context

CRITICAL: ORGANIZE BOTH FILES AND FOLDERS!
- You MUST organize folders just like files - they are items to be moved, not just context
- Folders should appear in your response as items to be organized
- Group related folders together (e.g., "Project1", "Project2" folders into a "Projects" parent folder)
- Move folders based on their names, contents, and purpose
- A folder is an item that can be moved into another folder - treat it exactly like a file
- Balance folder sizes (avoid 1-item folders unless specialized)
- Use clear, professional folder names
- Prioritize logical grouping over alphabetical sorting
- Folders can be moved into other folders or merged based on content similarity

🚨 CRITICAL: SAMPLE FILES ARE CONTEXT ONLY! 🚨
- When you see "sampleFiles" in folder data, these are files INSIDE the folder for context
- DO NOT organize sample files as separate items - they are already inside their parent folder
- Only organize the folder itself, not the files listed in "sampleFiles"
- Sample files help you understand folder content but should NEVER appear in your response
- FORBIDDEN: Never include any filename from "sampleFiles" arrays in your organization response
- ONLY organize items with "type": "file" or "type": "folder" at the root level

- Files with similar purposes (installation files, documentation, media)
- Sequential files or series (parts 1, 2, 3 or chapters)

FOLDER NAMING:
- Use specific, descriptive names that reflect the actual content
- Include context like dates, projects, or purposes when relevant
- Avoid generic names like "Documents" or "Files"
- Examples: "Invoice Records 2024", "Project Phoenix Documentation", "System Installation Files"

$existing_text

Items to organize (both files AND folders):
$(printf '%s' "$json_data")

Respond with ONLY valid JSON (no explanations):
[{"folderName": "Descriptive Name", "items": [{"name": "exact-filename-or-foldername"}]}]
EOF
  elif [[ "$request_type" == "recovery" ]]; then
    system_message="You are TidyAI recovery processor. Place missed files into the most appropriate existing folders. Only create new folders if absolutely necessary."
    local existing_text="Current folder structure: $(jq -r 'join(", ")' <<<"${existing_folders:-[]}")"
    read -r -d '' prompt <<EOF || true
These files were missed during batch processing and need to be organized.
$existing_text

ORGANIZATION PRINCIPLES:
- Each file appears in EXACTLY ONE folder
- Preserve ALL original filenames exactly
- REUSE existing folders when appropriate
- Only create new folders if absolutely necessary
- Group by file type and purpose

Missed files to organize:
$(printf '%s' "$json_data")

Respond with ONLY valid JSON (no explanations):
[{"folderName": "Folder Name", "items": [{"name": "exact-filename.ext"}]}]
EOF
  else
    system_message="You are an expert at file organization. You MUST respond with ONLY valid JSON - no explanations, no markdown, no extra text. Choose the most logical folder for each file based on its name and type."
    prompt="$json_data"
  fi

  # Clean to ascii and normalize newlines (best-effort)
  system_message="$(printf '%s' "$system_message" | LC_ALL=C tr -c '\11\12\15\40-\176' '?' )"
  prompt="$(printf '%s' "$prompt" | LC_ALL=C tr -c '\11\12\15\40-\176' '?' )"

  local request_body
  request_body="$(jq -n \
    --arg model "$MODEL_NAME" \
    --arg sys "$system_message" \
    --arg usr "$prompt" \
    --argjson max_tokens 16384 \
    --argjson temperature "$( [[ "$request_type" == "conflict" ]] && echo 0.1 || echo 0.3 )" \
    '{model:$model, messages:[{role:"system",content:$sys},{role:"user",content:$usr}], max_tokens:$max_tokens, temperature:$temperature}'
  )"

  local size
  size="$(printf '%s' "$request_body" | wc -c | awk '{print $1}')"
  if (( size > 100000 )); then
    color_echo "WARNING: Large request size may cause truncation" "$COLOR_WARNING"
  fi

  # Compose auth header value
  local header_value
  if [[ -n "$AUTH_SCHEME" ]]; then
    header_value="$AUTH_SCHEME $OPENAI_API_KEY"
  else
    header_value="$OPENAI_API_KEY"
  fi

  local http
  set +e
  http="$(curl -sS \
    -H "$AUTH_HEADER: ${header_value}" \
    -H "Content-Type: application/json" \
    -X POST "$OPENAI_API_URL" \
    -d "$request_body")"
  local rc=$?
  set -e
  if (( rc != 0 )) || [[ -z "$http" ]]; then
    color_echo "Error communicating with API at $OPENAI_API_URL" "$COLOR_ERROR"
    return 1
  fi

  # Extract content and finish_reason via jq
  local finish_reason
  finish_reason="$(jq -r '.choices[0].finish_reason // ""' <<<"$http" 2>/dev/null || echo "")"
  if [[ "$finish_reason" == "length" ]]; then
    color_echo "ERROR: Response was truncated due to token limit!" "$COLOR_ERROR"
    return 1
  fi
  local content
  content="$(jq -r '.choices[0].message.content // ""' <<<"$http" 2>/dev/null || echo "")"
  if [[ -z "$content" || "$content" == "null" ]]; then
    color_echo "Empty response received from provider" "$COLOR_ERROR"
    # Try to print API error if present
    local err
    err="$(jq -r '.error.message? // empty' <<<"$http" 2>/dev/null || true)"
    if [[ -n "$err" ]]; then
      color_echo "API Error Details: $err" "$COLOR_WARNING"
    fi
    return 1
  fi

  printf '%s' "$content"
}

extract_json_array() {
  # Try to extract a clean JSON array from AI content (handle ```json ... ``` too)
  local content="$1"
  local block
  block="$(printf '%s\n' "$content" | sed -n '/```json/,/```/p' | sed '1d;$d' || true)"
  if [[ -z "$block" ]]; then
    block="$(printf '%s\n' "$content" | sed -n '/```/,/```/p' | sed '1d;$d' || true)"
  fi
  if [[ -z "$block" ]]; then
    block="$content"
  fi

  # If block is a single object, wrap into array for uniformity
  if jq -e '.' >/dev/null 2>&1 <<<"$block"; then
    if jq -e 'type=="array"' >/dev/null 2>&1 <<<"$block"; then
      printf '%s' "$block"
      return 0
    else
      printf '[%s]' "$block"
      return 0
    fi
  fi

  # Fallback: attempt to locate first array looking-ish
  # If jq fails entirely, propagate as-is (will fail later)
  printf '%s' "$block"
}

filter_only_existing_items() {
  local ai_json="$1"      # array of {folderName, items:[{name}]}
  local items_json="$2"   # scanned items array with .name
  local names
  names="$(jq -c '[ .[].name ]' <<<"$items_json")"
  jq --argjson names "$names" '
    map(.items |= map(select(.name as $n | $names | index($n)))) |
    map(select(.items | length > 0))
  ' <<<"$ai_json"
}

show_tree() {
  local structure="$1"  # array
  if [[ "$(jq 'length' <<<"$structure")" -eq 0 ]]; then
    color_echo "+-- No reorganization suggested - folder is already well organized!" "$COLOR_SUCCESS"
    echo ""
    return
  fi

  color_echo "Proposed Organization Structure:" "$COLOR_PRIMARY"
  echo ""
  local count
  count="$(jq 'length' <<<"$structure")"
  local i
  for (( i=0; i<count; i++ )); do
    local folderName items_len
    folderName="$(jq -r ".[$i].folderName" <<<"$structure")"
    items_len="$(jq ".[$i].items|length" <<<"$structure")"
    color_echo "+-- $(file_emoji folder) ${folderName} (${items_len} files)" "$COLOR_PRIMARY"
    local j
    for (( j=0; j<items_len; j++ )); do
      local name ext emoji
      name="$(jq -r ".[$i].items[$j].name" <<<"$structure")"
      ext="$(file_ext "$name")"
      emoji="$(file_emoji "$ext")"
      color_echo "    +-- ${emoji} ${name}" "$COLOR_INFO"
    done
    if (( i < count-1 )); then
      color_echo "|" "$COLOR_INFO"
    fi
  done
  echo ""
}

# ----------------------------
# Organization Planner
# ----------------------------
confirm_and_apply() {
  local target="$1"
  local structure="$2"

  if [[ "$(jq 'length' <<<"$structure")" -eq 0 ]]; then
    color_echo "No changes to apply." "$COLOR_INFO"
    return 0
  fi

  color_echo "========================================" "$COLOR_PRIMARY"
  color_echo "Would you like to apply these changes?" "$COLOR_INFO"
  echo ""
  echo -n "${COLOR_INFO}Apply organization? (Y/N): ${COLOR_RESET}"
  read -r confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    color_echo "Organization cancelled. No files were moved." "$COLOR_WARNING"
    echo ""
    return 0
  fi

  # Build original structure snapshot (for undo)
  local original="[]"
  shopt -s dotglob nullglob
  local entry
  for entry in "$target"/* "$target"/.*; do
    local base
    base="$(basename "$entry")"
    [[ "$base" == "." || "$base" == ".." || "$base" == ".tidyai" ]] && continue
    local typ="file"
    [[ -d "$entry" ]] && typ="folder"
    local obj
    obj="$(jq -n --arg name "$base" --arg type "$typ" --arg full "$entry" '{name:$name,type:$type,fullPath:$full}')"
    original="$(jq -c --argjson obj "$obj" '. + [$obj]' <<<"$original")"
  done
  shopt -u dotglob nullglob

  # Save undo state
  save_undo_state "$target" "$original" "$structure" || {
    color_echo "Warning: Could not save undo information" "$COLOR_WARNING"
    echo -n "${COLOR_INFO}Continue without undo capability? (Y/N): ${COLOR_RESET}"
    read -r cont
    if [[ ! "$cont" =~ ^[Yy]$ ]]; then
      color_echo "Organization cancelled." "$COLOR_WARNING"
      return 1
    fi
  }

  apply_organization "$target" "$structure"
  show_post_organization_prompt "$target"
}

apply_organization() {
  local target="$1"
  local structure="$2"

  local fcount
  fcount="$(jq 'length' <<<"$structure")"
  local i
  for (( i=0; i<fcount; i++ )); do
    local folderName destFolder
    folderName="$(jq -r ".[$i].folderName" <<<"$structure")"
    destFolder="$target/$folderName"
    mkdir -p -- "$destFolder"

    local items_len
    items_len="$(jq ".[$i].items|length" <<<"$structure")"
    local j
    for (( j=0; j<items_len; j++ )); do
      local name src dest
      name="$(jq -r ".[$i].items[$j].name" <<<"$structure")"
      src="$target/$name"
      dest="$destFolder/$name"
      if [[ ! -e "$src" ]]; then
        color_echo "    Skipped (not found): $name" "$COLOR_WARNING"
        continue
      fi
      if [[ -e "$dest" ]]; then
        # Safe behavior: do not rename; skip conflicts
        color_echo "    Conflict: $name already exists in '$folderName' - skipping" "$COLOR_WARNING"
        continue
      fi
      mv -- "$src" "$dest" && color_echo "    Moved: $name -> $folderName/" "$COLOR_INFO" || color_echo "    Failed to move: $name" "$COLOR_ERROR"
    done
  done
}

show_post_organization_prompt() {
  local target="$1"
  echo ""
  color_echo "========================================" "$COLOR_PRIMARY"
  color_echo "*** ORGANIZATION COMPLETE! ***" "$COLOR_SUCCESS"
  color_echo "========================================" "$COLOR_PRIMARY"
  color_echo "Your files have been organized successfully!" "$COLOR_INFO"
  echo ""
  color_echo "How does it look?" "$COLOR_INFO"
  color_echo "  [K] Keep it - I love the new organization!" "$COLOR_SUCCESS"
  color_echo "  [U] Undo - Put everything back the way it was" "$COLOR_WARNING"
  echo ""
  echo -n "${COLOR_INFO}Your decision (K/U): ${COLOR_RESET}"
  read -r ans
  if [[ "$ans" =~ ^[Uu]$ ]]; then
    echo ""
    if invoke_undo "$target"; then
      color_echo "Organization has been undone successfully!" "$COLOR_SUCCESS"
    else
      color_echo "Failed to undo organization" "$COLOR_ERROR"
    fi
  else
    color_echo "Keeping the new organization. Undo data will remain available." "$COLOR_SUCCESS"
    color_echo "You can run TidyAI again to undo this organization later." "$COLOR_INFO"
  fi
}

# ----------------------------
# Batch and recovery workflow
# ----------------------------
process_single_batch() {
  local target="$1"
  local items="$2" # scanned items array

  color_echo "Processing all $(jq 'length' <<<"$items") items in single batch..." "$COLOR_INFO"
  echo ""

  local batch_json
  batch_json="$(build_batch_json "$items" "[]")"
  local content
  if ! content="$(invoke_openai "$batch_json" "batch" "[]" 1)"; then
    color_echo "Failed to get response from provider" "$COLOR_ERROR"
    return 1
  fi

  local ai_array
  ai_array="$(extract_json_array "$content")"
  if ! jq -e '.' >/dev/null 2>&1 <<<"$ai_array"; then
    color_echo "Error processing AI response (invalid JSON)" "$COLOR_ERROR"
    return 1
  fi
  ai_array="$(filter_only_existing_items "$ai_array" "$items")"
  show_tree "$ai_array"
  confirm_and_apply "$target" "$ai_array"
}

merge_structures() {
  local master="$1"  # array
  local batch="$2"   # array
  # Merge by folderName, concatenating items
  jq -c -s '
    add
    | group_by(.folderName)
    | map({folderName: .[0].folderName, items: (map(.items) | add)})
  ' <(printf '%s' "$master") <(printf '%s' "$batch")
}

get_missed_files() {
  local items="$1"      # scanned items at root
  local structure="$2"  # ai structure
  local organized
  organized="$(jq -c '[ .[].items[].name ]' <<<"$structure")"
  jq -c --argjson organized "$organized" '
    [ .[] | select(.name as $n | $organized | index($n) | not) ]
  ' <<<"$items"
}

create_unorganized_folder_json() {
  local missed="$1" # array of scanned item objects
  jq -c '
    {
      folderName: "Unorganized Files",
      items: [ .[] | {name: .name} ]
    }
  ' <<<"$missed"
}

process_in_batches() {
  local target="$1"
  local items="$2"
  color_echo "Starting multi-batch processing for $(jq 'length' <<<"$items") items..." "$COLOR_INFO"
  echo ""

  local master="[]"
  local all_sorted
  all_sorted="$(jq -c 'sort_by(.name)' <<<"$items")"
  local total
  total="$(jq 'length' <<<"$all_sorted")"
  local batch_size=75
  local idx=0
  local batch_number=1
  while (( idx < total )); do
    local end=$(( idx + batch_size ))
    if (( end > total )); then end=$total; fi
    local current
    current="$(jq -c ".[$idx:$end]" <<<"$all_sorted")"
    local existing_names
    existing_names="$(jq -c '[ .[].folderName ]' <<<"$master")"
    local batch_json
    batch_json="$(build_batch_json "$current" "$(jq -c '.' <<<"$master")")"
    color_echo "Processing batch $batch_number ... ($((end-idx)) items)" "$COLOR_INFO"
    local content
    if ! content="$(invoke_openai "$batch_json" "batch" "$existing_names" "$batch_number")"; then
      color_echo "Batch $batch_number failed - skipping" "$COLOR_ERROR"
    else
      local ai_array
      ai_array="$(extract_json_array "$content")"
      if jq -e '.' >/dev/null 2>&1 <<<"$ai_array"; then
        ai_array="$(filter_only_existing_items "$ai_array" "$current")"
        master="$(merge_structures "$master" "$ai_array")"
        color_echo "Batch $batch_number completed successfully" "$COLOR_SUCCESS"
      else
        color_echo "Batch $batch_number returned invalid JSON - skipping" "$COLOR_WARNING"
      fi
    fi
    idx=$end
    ((batch_number++)) || true
    echo ""
  done

  color_echo "Performing final validation..." "$COLOR_INFO"
  local missed
  missed="$(get_missed_files "$items" "$master")"
  if [[ "$(jq 'length' <<<"$missed")" -gt 0 ]]; then
    color_echo "Found $(jq 'length' <<<"$missed") files that need recovery processing..." "$COLOR_WARNING"
    # Recovery pass: single batch on missed files to existing folders
    local existing_names
    existing_names="$(jq -c '[ .[].folderName ]' <<<"$master")"
    local recovery_payload
    recovery_payload="$(jq -c '[ .[] | {name:.name,type:"file"} ]' <<<"$missed")"
    local rec_batch
    rec_batch="$(jq -n --argjson items "$recovery_payload" '{items:$items}')" # minimal shape for prompt consistency
    local rec_content
    if rec_content="$(invoke_openai "$rec_batch" "recovery" "$existing_names" 1)"; then
      local rec_array
      rec_array="$(extract_json_array "$rec_content")"
      if jq -e '.' >/dev/null 2>&1 <<<"$rec_array"; then
        rec_array="$(filter_only_existing_items "$rec_array" "$missed")"
        master="$(merge_structures "$master" "$rec_array")"
      fi
    fi
    # Any still-missed go to "Unorganized Files"
    local still_missed
    still_missed="$(get_missed_files "$items" "$master")"
    if [[ "$(jq 'length' <<<"$still_missed")" -gt 0 ]]; then
      color_echo "Moving final $(jq 'length' <<<"$still_missed") files to 'Unorganized Files' folder..." "$COLOR_WARNING"
      local unorganized
      unorganized="$(create_unorganized_folder_json "$still_missed")"
      master="$(jq -c --argjson obj "$unorganized" '. + [$obj]' <<<"$master")"
      color_echo "Created 'Unorganized Files' folder" "$COLOR_SUCCESS"
    fi
  fi

  color_echo "Multi-batch processing completed successfully!" "$COLOR_SUCCESS"
  echo ""
  show_tree "$master"
  confirm_and_apply "$target" "$master"
}

# ----------------------------
# Main / Usage
# ----------------------------
usage() {
  cat <<USAGE
Usage:
  $(basename "$0") [options] /path/to/folder

Provider options (preconfigured defaults you can override with other flags):
  --provider openai|openrouter|azure|groq|fireworks|together|perplexity|deepseek|lmstudio|localai|vllm

Generic API options (OpenAI-compatible):
  --api-base URL           Default: https://api.openai.com (or provider default)
  --api-path PATH          Default: /v1/chat/completions
  --model NAME             Default: gpt-4o-mini
  --api-key KEY            Inline API key (discouraged; prefer env)
  --api-key-env VAR        Read API key from environment variable VAR
  --auth-header NAME       Default: Authorization (azure uses: api-key)
  --auth-scheme SCHEME     Default: Bearer; set '' to omit (azure)

Azure specifics:
  --azure-api-version VER  Default: 2024-02-15-preview
  Note: For Azure set --api-base "https://<resource>.openai.azure.com"
        and --model to your deployment name; path is auto-built.

Environment variables (can replace flags):
  TIDYAI_PROVIDER, TIDYAI_API_BASE, TIDYAI_API_PATH, TIDYAI_MODEL,
  TIDYAI_API_KEY (or legacy TidyAIOpenAIAPIKey),
  TIDYAI_AUTH_HEADER, TIDYAI_AUTH_SCHEME, AZURE_API_VERSION

Examples:
  TIDYAI_API_KEY=sk-... ./tidyai.sh --provider openai ~/Downloads
  TIDYAI_API_KEY=... ./tidyai.sh --provider openrouter --model openrouter/gpt-4o-mini ~/stuff
  TIDYAI_API_KEY=... ./tidyai.sh --provider groq --model llama-3.1-70b-versatile ~/data
  TIDYAI_API_KEY=... ./tidyai.sh --provider lmstudio --api-base http://localhost:1234 --model qwen2.5:7b ~/dir
  # Azure (deployment name in --model)
  ./tidyai.sh --provider azure --api-base https://myres.openai.azure.com --model myDeployment --api-key-env AZURE_OPENAI_KEY ~/dir
USAGE
}

main() {
  # Parse options before showing logo / validating env
  parse_args "$@"

  # Apply provider defaults (can be overridden by flags)
  configure_provider "$PROVIDER"
  OPENAI_API_URL="${API_BASE}${API_PATH}"

  check_env
  show_logo

  local target="${FOLDER_ARG:-}"
  if [[ -z "$target" ]]; then
    usage
    exit 1
  fi

  # Trim quotes and normalize
  target="${target%\"}"
  target="${target#\"}"
  if [[ ! -d "$target" ]]; then
    color_echo "Error: Folder path does not exist or is not accessible." "$COLOR_ERROR"
    color_echo "   Path: $target" "$COLOR_WARNING"
    exit 1
  fi
  color_echo "Provider: " "$COLOR_INFO" -n; color_echo "$PROVIDER" "$COLOR_ACCENT"
  color_echo "API URL: " "$COLOR_INFO" -n; color_echo "$OPENAI_API_URL" "$COLOR_ACCENT"
  color_echo "Model: " "$COLOR_INFO" -n; color_echo "$MODEL_NAME" "$COLOR_ACCENT"
  color_echo "Target Folder: " "$COLOR_INFO" -n
  color_echo "$target" "$COLOR_ACCENT"
  echo ""

  # Undo prompt if .tidyai exists
  local undo_status=0
  if show_undo_prompt_if_any "$target"; then
    :
  fi
  undo_status=$?
  if (( undo_status == 2 )); then
    color_echo "Undo operation completed. Exiting..." "$COLOR_SUCCESS"
    exit 0
  fi

  # Scan
  local items
  items="$(scan_folder "$target")"
  # Debug: show what scan_folder returned
  # color_echo "DEBUG: scan_folder returned: '$items'" "$COLOR_WARNING"
  # color_echo "DEBUG: items length: ${#items}" "$COLOR_WARNING"
  
  # Check if scan_folder returned valid JSON and has items
  if [[ -z "$items" ]]; then
    color_echo "Failed to scan folder - empty result returned." "$COLOR_ERROR"
    exit 1
  fi
  
  if ! jq -e '.' >/dev/null 2>&1 <<<"$items"; then
    color_echo "Failed to scan folder - invalid JSON returned." "$COLOR_ERROR"
    color_echo "Raw output: $items" "$COLOR_ERROR"
    exit 1
  fi
  if [[ "$(jq 'length' <<<"$items")" -eq 0 ]]; then
    color_echo "The folder appears to be empty or inaccessible." "$COLOR_WARNING"
    exit 0
  fi

  # Decide single vs multi-batch
  local total
  total="$(jq 'length' <<<"$items")"
  if (( total <= 75 )); then
    process_single_batch "$target" "$items" || true
  else
    process_in_batches "$target" "$items" || true
  fi

  color_echo "Press Enter to exit..." "$COLOR_INFO"
  read -r || true
}

main "$@"
