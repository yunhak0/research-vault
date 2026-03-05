# Task: setup.sh 테스트 통과시키기

## 실행
```bash
cd ~/Documents/github/research-vault
bash tests/test_setup.sh
```

## 성공 조건
- `FAIL: 0`
- `PASS: 30+` (uv 있으면 ~45, 없으면 ~40)
- Exit code 0

## 실패 시
1. **개별 테스트 재실행**: `bash tests/test_setup.sh test_실패한함수명`
2. **verbose**: `bash tests/test_setup.sh -v test_실패한함수명` → TEST_ROOT 보존
3. 원인이 setup.sh면 `setup.sh` 수정, 테스트면 `tests/test_setup.sh` 수정
4. 전체 재실행으로 확인

## 아키텍처
- `setup.sh`에 source guard 있음 → `source setup.sh`로 함수만 로드
- 테스트는 core 함수 직접 호출: `_install_vault`, `_ensure_repo`, `_setup_project`
- stdin 파이핑 없음 — read 순서 문제 없음

## 테스트 목록 (`bash tests/test_setup.sh -l`)
| 함수 | 검증 |
|------|------|
| test_install | vault 구조, config.yaml |
| test_install_idempotent | 재실행 시 config 보존 |
| test_ensure_repo_git | git init |
| test_ensure_repo_uv | uv init (uv 필요) |
| test_ensure_repo_existing | 기존 repo 보존 |
| test_setup_project_basic | agent-docs, symlink, placeholder, config |
| test_setup_project_existing_agent_docs | 기존 파일 보존 + 추가 |
| test_setup_project_existing_claude_md | CLAUDE.md 덮어쓰기 방지 |
| test_setup_project_vault_collision | 중복 프로젝트 ID 거부 |
| test_full_flow_uv | uv → setup 전체 (uv 필요) |
| test_full_flow_git | git → setup 전체 |
| test_multiple_projects | vault에 3개 프로젝트 |
