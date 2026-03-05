#!/bin/bash
# ==============================================================================
# daily_start.sh — 일일 연구 시작 스크립트
# 
# 사용법:
#   daily-start              # 일일 시작 (어제 raw data 수집 + 오늘 빈 템플릿 생성)
#   daily-start --collect    # 데이터 수집만 (Claude 처리 없이)
#   daily-start --help       # 도움말
#
# 설치: setup_daily.sh 실행 또는 수동으로:
#   chmod +x .vault/scripts/daily_start.sh
#   alias daily-start='<vault_path>/.vault/scripts/daily_start.sh'
# ==============================================================================

set -euo pipefail

# ─── 경로 자동 감지 ──────────────────────────────────────────────────────────
# 스크립트 위치에서 vault root 추론: .vault/scripts/daily_start.sh → ../../
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ─── 설정 ────────────────────────────────────────────────────────────────────
DAILY_DATA_DIR="$VAULT_ROOT/.vault/daily_data"
CLAUDE_SESSION_DIR="$VAULT_ROOT/ZZ_Temp/Claude"
DAILY_NOTE_DIR="$VAULT_ROOT/01_Global/daily"
LAST_START_FILE="$DAILY_DATA_DIR/last_start_time"
DAILY_CONF="$VAULT_ROOT/.vault/daily.conf"

# Git repos: daily.conf에서 읽기 (한 줄에 하나, # 주석 무시)
GIT_REPOS=()
if [[ -f "$DAILY_CONF" ]]; then
    while IFS= read -r line; do
        # 공백/주석/빈줄 무시
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"
        [[ -z "$line" ]] && continue
        # ~ 확장
        eval line="$line"
        GIT_REPOS+=("$line")
    done < "$DAILY_CONF"
fi

# ─── 유틸리티 ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# ─── 초기화 ───────────────────────────────────────────────────────────────────
init() {
    mkdir -p "$DAILY_DATA_DIR"
    mkdir -p "$CLAUDE_SESSION_DIR"
    mkdir -p "$DAILY_NOTE_DIR"
}

# ─── 시간 관리 ─────────────────────────────────────────────────────────────────
get_last_start_time() {
    if [[ -f "$LAST_START_FILE" ]]; then
        cat "$LAST_START_FILE"
    else
        # 첫 실행: 어제 09:00 기본값
        date -v-1d "+%Y-%m-%dT09:00:00" 2>/dev/null || date -d "yesterday" "+%Y-%m-%dT09:00:00"
    fi
}

save_start_time() {
    local now
    now=$(date "+%Y-%m-%dT%H:%M:%S")
    echo "$now" > "$LAST_START_FILE"
    echo "$now"
}

# ─── 데이터 수집: Claude 세션 ──────────────────────────────────────────────────
collect_claude_sessions() {
    local start_date="$1"
    local end_date="$2"
    local found=0
    
    echo "## Claude 대화 내역"
    echo ""
    
    local current_date="$start_date"
    while [[ "$current_date" < "$end_date" ]] || [[ "$current_date" == "$end_date" ]]; do
        local pattern="CLAUDE-${current_date}-*.md"
        
        for file in "$CLAUDE_SESSION_DIR"/$pattern; do
            [[ -f "$file" ]] || continue
            [[ "$(basename "$file")" == "TEMPLATE.md" ]] && continue
            found=1
            local filename
            filename=$(basename "$file")
            echo "### 📅 ${current_date} — $filename"
            echo ""
            cat "$file"
            echo ""
            echo "---"
            echo ""
        done
        
        current_date=$(date -j -v+1d -f "%Y-%m-%d" "$current_date" "+%Y-%m-%d" 2>/dev/null || \
            date -d "$current_date + 1 day" "+%Y-%m-%d" 2>/dev/null)
    done
    
    if [[ $found -eq 0 ]]; then
        echo "⚠️ **Claude 세션 기록 없음** — 수집 기간(${start_date} ~ ${end_date})에 세션 파일이 없습니다."
        echo ""
        echo "> 대화 내역을 정리한 후 \`daily-update\` 명령으로 추가할 수 있습니다."
        echo ""
    fi
}

# ─── 데이터 수집: Obsidian 변경 ────────────────────────────────────────────────
collect_obsidian_changes() {
    local since="$1"
    local until="$2"
    
    echo "## Obsidian Vault 변경 내역"
    echo ""
    echo "**수집 기간**: $since ~ $until"
    echo ""
    
    local since_ref=$(mktemp)
    local until_ref=$(mktemp)
    touch -t "$(echo "$since" | sed 's/[-T:]//g' | cut -c1-12)" "$since_ref" 2>/dev/null || \
    touch -d "$since" "$since_ref" 2>/dev/null || true
    touch -t "$(echo "$until" | sed 's/[-T:]//g' | cut -c1-12)" "$until_ref" 2>/dev/null || \
    touch -d "$until" "$until_ref" 2>/dev/null || true
    
    local total=0
    local new_count=0
    local mod_count=0
    
    echo "| 상태 | 날짜 | 파일 | 수정 시간 |"
    echo "|------|------|------|----------|"
    
    while IFS= read -r -d '' file; do
        local rel_path="${file#$VAULT_ROOT/}"
        
        # 제외 패턴
        [[ "$rel_path" == .obsidian/* ]] && continue
        [[ "$rel_path" == .vault/* ]] && continue
        [[ "$rel_path" == .git/* ]] && continue
        [[ "$rel_path" == .claude/* ]] && continue
        [[ "$rel_path" == ZZ_Temp/Claude/* ]] && continue
        [[ "$rel_path" == .* ]] && continue
        
        local mod_time
        mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -c1-16)
        local mod_date
        mod_date=$(echo "$mod_time" | cut -d' ' -f1)
        local create_time
        create_time=$(stat -f "%SB" -t "%Y-%m-%dT%H:%M:%S" "$file" 2>/dev/null || echo "unknown")
        
        if [[ "$create_time" != "unknown" ]] && [[ "$create_time" > "$since" ]]; then
            echo "| 🆕 | 📅 ${mod_date} | \`$rel_path\` | $mod_time |"
            new_count=$((new_count + 1))
        else
            echo "| 📝 | 📅 ${mod_date} | \`$rel_path\` | $mod_time |"
            mod_count=$((mod_count + 1))
        fi
        total=$((total + 1))
    done < <(find -L "$VAULT_ROOT" -name "*.md" \
        -newer "$since_ref" ! -newer "$until_ref" \
        -print0 2>/dev/null)
    
    rm -f "$since_ref" "$until_ref"
    
    echo ""
    if [[ $total -eq 0 ]]; then
        echo "변경된 Obsidian 문서가 없습니다."
    else
        echo "**총 ${total}개 파일** (새 파일: ${new_count}, 수정: ${mod_count})"
    fi
    echo ""
}

# ─── 데이터 수집: Git 변경 ─────────────────────────────────────────────────────
collect_git_changes() {
    local since="$1"
    local until="$2"
    
    echo "## Git 변경 내역 (dev-code)"
    echo ""
    echo "**수집 기간**: $since ~ $until"
    echo ""
    
    if [[ ${#GIT_REPOS[@]} -eq 0 ]]; then
        echo "⚠️ 추적 대상 Git 저장소가 없습니다. \`.vault/daily.conf\`에 경로를 추가하세요."
        echo ""
        return
    fi
    
    for repo_path in "${GIT_REPOS[@]}"; do
        local repo_name
        repo_name=$(basename "$repo_path")
        
        if [[ ! -d "$repo_path/.git" ]]; then
            continue
        fi
        
        echo "### $repo_name"
        echo ""
        
        local commit_count
        commit_count=$(cd "$repo_path" && git log \
            --since="$since" --until="$until" \
            --oneline 2>/dev/null | wc -l | tr -d ' ')
        
        if [[ "$commit_count" -eq 0 ]]; then
            echo "이 기간에 커밋이 없습니다."
        else
            echo "#### 커밋 로그 (${commit_count}건)"
            echo ""
            echo "| 날짜/시간 | Hash | 메시지 |"
            echo "|------------|------|--------|"
            cd "$repo_path" && git log \
                --since="$since" --until="$until" \
                --pretty=format:"| 📅 %ad | \`%h\` | %s |" \
                --date=format:"%Y-%m-%d %H:%M" 2>/dev/null
            echo ""
            echo ""
            
            echo "#### 변경 통계"
            echo "\`\`\`"
            cd "$repo_path" && git diff --stat \
                "$(git log --since="$since" --until="$until" --format="%H" --reverse 2>/dev/null | head -1)^" \
                "$(git log --since="$since" --until="$until" --format="%H" 2>/dev/null | head -1)" \
                2>/dev/null || echo "(통계 생성 실패)"
            echo "\`\`\`"
        fi
        echo ""
        
        local unstaged
        unstaged=$(cd "$repo_path" && git diff --stat 2>/dev/null) || true
        local staged
        staged=$(cd "$repo_path" && git diff --cached --stat 2>/dev/null) || true
        
        if [[ -n "$unstaged" ]] || [[ -n "$staged" ]]; then
            echo "#### ⚠️ 미커밋 변경사항"
            echo ""
            if [[ -n "$staged" ]]; then
                echo "**Staged:**"
                echo "\`\`\`"
                echo "$staged"
                echo "\`\`\`"
            fi
            if [[ -n "$unstaged" ]]; then
                echo "**Unstaged:**"
                echo "\`\`\`"
                echo "$unstaged"
                echo "\`\`\`"
            fi
            echo ""
        fi
    done
}

# ─── 데이터 수집: 기존 Daily Note ──────────────────────────────────────────────
collect_existing_daily_note() {
    local target_date="$1"
    local daily_file="$DAILY_NOTE_DIR/DAILY-${target_date}.md"
    
    echo "## 기존 Daily Note 내용"
    echo ""
    
    if [[ -f "$daily_file" ]]; then
        local content_after_frontmatter
        content_after_frontmatter=$(sed '1,/^---$/{ /^---$/!d; /^---$/d; }' "$daily_file" | sed '/^---$/,/^---$/d' | sed '/^[[:space:]]*$/d' | sed '/^#/d' | sed '/^- \[ \][[:space:]]*$/d' | sed '/^\*\*/d' | tr -d '[:space:]')
        
        if [[ -z "$content_after_frontmatter" ]]; then
            echo "📋 Daily note 존재하지만 빈 템플릿 상태입니다. 사용자 입력 내용 없음."
            echo ""
        else
            echo "📋 사용자가 직접 작성한 내용이 포함되어 있습니다."
            echo "**⚠️ Claude: 이 내용을 보존하면서 raw data를 병합하세요.**"
            echo ""
            echo "\`\`\`markdown"
            cat "$daily_file"
            echo "\`\`\`"
            echo ""
        fi
    else
        echo "이 날짜의 daily note가 아직 없습니다."
        echo ""
    fi
}

# ─── Raw Data 파일 생성 ───────────────────────────────────────────────────────
generate_raw_data() {
    local target_date="$1"
    local since="$2"
    local until="$3"
    local end_date="$4"
    local output_file="$DAILY_DATA_DIR/${target_date}_raw.md"
    
    local days_span=0
    if command -v python3 &>/dev/null; then
        days_span=$(python3 -c "from datetime import date; print((date.fromisoformat('$end_date') - date.fromisoformat('$target_date')).days)" 2>/dev/null || echo 0)
    fi
    
    {
        echo "---"
        echo "type: daily-raw-data"
        echo "date: $target_date"
        echo "period_start: $since"
        echo "period_end: $until"
        echo "period_days: $((days_span + 1))"
        echo "generated: $(date '+%Y-%m-%dT%H:%M:%S')"
        echo "---"
        echo ""
        echo "# Raw Data: $target_date"
        echo ""
        
        if [[ $days_span -gt 0 ]]; then
            echo "> ⚠️ **다일 수집**: ${target_date} ~ ${end_date} (${days_span}일간 공백 포함)"
            echo "> 각 항목에 날짜가 표시되어 있으니 Claude는 날짜별 작업을 구분해서 정리하세요."
            echo ""
        fi
        
        collect_existing_daily_note "$target_date"
        collect_claude_sessions "$target_date" "$end_date"
        collect_obsidian_changes "$since" "$until"
        collect_git_changes "$since" "$until"
        
    } > "$output_file"
    
    echo "$output_file"
}

# ─── 오늘 빈 템플릿 생성 ──────────────────────────────────────────────────────
create_today_template() {
    local today="$1"
    local template_file="$DAILY_NOTE_DIR/DAILY-${today}.md"
    
    if [[ -f "$template_file" ]]; then
        log_warn "오늘의 daily note가 이미 존재합니다: DAILY-${today}.md"
        return 0
    fi
    
    local template_src="$VAULT_ROOT/.vault/templates/daily_note.md"
    if [[ -f "$template_src" ]]; then
        sed "s/\[YYYY-MM-DD\]/${today}/g" "$template_src" > "$template_file"
    else
        cat > "$template_file" << EOF
---
doc_id: DAILY-${today}
title: ${today} 연구일지
created: ${today}
date: ${today}
tags: [daily]
---

# ${today} 연구일지

## 오늘의 목표
- [ ] 
- [ ] 
- [ ] 

## 작업 기록

### [PROJECT_ID]

**수행:**
- 

**문제:**
- 

**해결:**
- 

**관련 문서:**
- 

## 아이디어/메모

## 내일 할 일
- [ ] 
- [ ] 

## 회고

**잘된 점:**
- 

**개선할 점:**
- 

**배운 점:**
- 
EOF
    fi
    
    log_info "오늘의 daily note 템플릿 생성: DAILY-${today}.md"
}

# ─── 메인 ──────────────────────────────────────────────────────────────────────
main() {
    local mode="${1:---full}"
    
    case "$mode" in
        --help|-h)
            echo "사용법: daily-start [옵션]"
            echo ""
            echo "옵션:"
            echo "  (없음)      전체 실행 (데이터 수집 + 오늘 템플릿 생성)"
            echo "  --collect   데이터 수집만 (raw data 파일 생성)"
            echo "  --help      이 도움말 표시"
            echo ""
            echo "Vault: $VAULT_ROOT"
            echo "Config: $DAILY_CONF"
            echo "Git repos: ${#GIT_REPOS[@]}개"
            echo ""
            echo "관련 명령어:"
            echo "  daily-update [날짜]   기존 daily note에 누락분 추가"
            exit 0
            ;;
    esac
    
    init
    
    local last_start
    last_start=$(get_last_start_time)
    local now
    now=$(save_start_time)
    local today
    today=$(date "+%Y-%m-%d")
    local yesterday
    yesterday=$(date -v-1d "+%Y-%m-%d" 2>/dev/null || date -d "yesterday" "+%Y-%m-%d")
    
    local target_date
    target_date=$(echo "$last_start" | cut -d'T' -f1)
    local end_date="$yesterday"
    
    log_section "일일 시작"
    log_info "Vault: $VAULT_ROOT"
    log_info "이전 시작: $last_start"
    log_info "현재 시작: $now"
    log_info "대상 날짜: $target_date"
    log_info "Git repos: ${#GIT_REPOS[@]}개"
    if [[ "$target_date" != "$yesterday" ]]; then
        log_info "수집 기간: ${target_date} ~ ${end_date} (다일 수집)"
    fi
    
    log_section "데이터 수집 중..."
    local raw_file
    raw_file=$(generate_raw_data "$target_date" "$last_start" "$now" "$end_date")
    log_info "Raw data 저장: $raw_file"
    
    if [[ "$mode" != "--collect" ]]; then
        log_section "오늘 템플릿 생성"
        create_today_template "$today"
    fi
    
    log_section "완료"
    echo ""
    echo -e "  ${CYAN}📁 Raw data${NC}: $raw_file"
    echo -e "  ${CYAN}📄 대상 note${NC}: $DAILY_NOTE_DIR/DAILY-${target_date}.md"
    echo -e "  ${CYAN}📄 오늘 note${NC}: $DAILY_NOTE_DIR/DAILY-${today}.md"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  다음 단계: Claude에서 ${GREEN}\"일일 시작 처리해줘\"${NC}"
    echo "  → raw data를 읽고 Level 3 daily note 자동 생성"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"
