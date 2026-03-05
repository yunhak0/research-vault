# Scripts

Vault 관리를 위한 자동화 스크립트입니다.

## 스크립트 목록

| 스크립트 | 명령어 | 설명 |
|----------|--------|------|
| `daily_start.sh` | `daily-start` | 어제 데이터 수집 + 오늘 빈 템플릿 생성 |
| `daily_update.sh` | `daily-update [날짜]` | 기존 daily note에 누락분 추가 |
| `setup_daily.sh` | 1회 실행 | 설치 (chmod + alias 등록) |
| `update_index.py` | `uv run --with pyyaml python ...` | Master/Project Index 자동 업데이트 |

## 설정 파일

| 파일 | 위치 | 설명 |
|------|------|------|
| `daily.conf` | `.vault/daily.conf` | Git 추적 대상 저장소 경로 (한 줄에 하나) |

`daily.conf`는 `setup.sh` 실행 시 자동 생성됩니다. 수동으로 편집하려면:

```
# .vault/daily.conf
/Users/user/Documents/github/my-project
/Users/user/Documents/github/another-repo
```

## 설치

```bash
bash .vault/scripts/setup_daily.sh
source ~/.zshrc
```

## 워크플로우

1. **터미널**: `daily-start` → raw data 수집 + 오늘 빈 템플릿
2. **Claude**: "일일 시작 처리해줘" → raw data 읽기 + Level 3 daily note 생성
3. **누락 시**: `daily-update` → 추가 데이터 수집 → Claude에게 병합 요청

## Index 업데이트

```bash
uv run --with pyyaml python .vault/scripts/update_index.py [vault_path]
```

- `00_master_index.md` (전체 vault 대시보드) 생성
- 각 프로젝트의 `00_project_index.md` 생성
- YAML frontmatter 메타데이터 파싱하여 테이블 생성

## 경로 감지

모든 스크립트는 **자신의 위치 기준**으로 vault root를 자동 감지합니다:
- `daily_start.sh` → `SCRIPT_DIR/../..` = vault root
- 하드코딩된 경로 없음 — vault를 어디로 옮겨도 동작
