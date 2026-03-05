#!/bin/bash
# ==============================================================================
# setup_daily.sh — Daily Note 자동화 시스템 설치
#
# 실행: bash <vault_path>/.vault/scripts/setup_daily.sh
# ==============================================================================

set -euo pipefail

# 경로 자동 감지
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPTS_DIR="$VAULT_ROOT/.vault/scripts"

echo "━━━ Daily Note 자동화 시스템 설치 ━━━"
echo ""
echo "Vault: $VAULT_ROOT"
echo ""

# 1. 디렉토리 생성
echo "[1/3] 디렉토리 생성..."
mkdir -p "$VAULT_ROOT/.vault/daily_data"
mkdir -p "$VAULT_ROOT/ZZ_Temp/Claude"
echo "  ✅ .vault/daily_data/"
echo "  ✅ ZZ_Temp/Claude/"

# 2. 실행 권한
echo ""
echo "[2/3] 스크립트 실행 권한 설정..."
chmod +x "$SCRIPTS_DIR/daily_start.sh"
chmod +x "$SCRIPTS_DIR/daily_update.sh"
echo "  ✅ daily_start.sh"
echo "  ✅ daily_update.sh"

# 3. Shell alias
echo ""
echo "[3/3] Shell alias 등록..."

SHELL_RC="$HOME/.zshrc"
if [[ ! -f "$SHELL_RC" ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if grep -q "daily-start" "$SHELL_RC" 2>/dev/null; then
    echo "  ℹ️  alias가 이미 등록되어 있습니다."
    echo "  ⚠️  경로가 변경되었다면 수동으로 업데이트하세요:"
    echo "      alias daily-start='$SCRIPTS_DIR/daily_start.sh'"
    echo "      alias daily-update='$SCRIPTS_DIR/daily_update.sh'"
else
    {
        echo ""
        echo "# === Daily Note 자동화 ==="
        echo "alias daily-start='$SCRIPTS_DIR/daily_start.sh'"
        echo "alias daily-update='$SCRIPTS_DIR/daily_update.sh'"
    } >> "$SHELL_RC"
    echo "  ✅ alias 등록 완료 ($SHELL_RC)"
fi

echo ""
echo "━━━ 설치 완료 ━━━"
echo ""
echo "⚠️  터미널에서 아래 실행 후 사용하세요:"
echo "  source $SHELL_RC"
echo ""
echo "사용법:"
echo "  daily-start          → 어제 데이터 수집 + 오늘 빈 템플릿 생성"
echo "  daily-update         → 어제 daily note에 누락분 추가"
echo "  daily-update 날짜    → 특정 날짜 daily note 추가 업데이트"
echo ""
echo "Claude에서:"
echo "  \"일일 시작\" → 스크립트 실행 + Level 3 daily note 자동 생성"
echo ""
