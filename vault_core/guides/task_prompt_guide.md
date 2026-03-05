# Task Prompt 작성 가이드

## 개요

Task Prompt는 **Claude Desktop(연구)에서 Claude Code(구현)로 작업을 넘기는** 핸드오프 문서이다.
Desktop에서 분석·설계·아이디어 빌딩을 마친 후, 서버의 Claude Code가 읽고 바로 구현에 착수할 수 있도록 작성한다.

## 핵심 원칙

### 1. Self-contained
Claude Code는 이 프롬프트 **하나**와 코드베이스만 보고 작업을 시작한다. Vault의 연구 문서를 직접 읽을 수 없으므로, 필요한 맥락은 프롬프트 안에 포함하거나 `agent-docs/obsidian/` 경로로 참조한다.

### 2. 검증 가능
"잘 구현해줘"가 아니라 "이 테스트가 통과하면 완료"처럼 Claude Code가 스스로 완료 여부를 판단할 수 있어야 한다.

### 3. 적절한 범위
하나의 프롬프트 = 하나의 작업 단위. 너무 크면 분할한다. `todo.md`의 체크리스트 하나에 대응하는 크기가 적절하다.

## 파일 위치

| 종류 | 위치 | 예시 |
|------|------|------|
| **프로젝트 전체** 대상 구현 | `agent-docs/tasks/prompts/` | 리팩토링, 새 모듈, 인프라 |
| **특정 문제(PRB)** 대상 구현 | `agent-docs/obsidian/problems/PRB-###/prompts/` | 해당 문제 해결을 위한 코드 변경 |

## 파일명 규칙

```
PROMPT-###_{slug}.md
```

- `###`: 위치(tasks/prompts/ 또는 PRB 폴더) 내에서 순차 부여
- `slug`: 2-5 단어 영어 소문자 kebab-case

예시:
- `PROMPT-001_residual-context-separation.md`
- `PROMPT-002_wandb-metric-logging.md`

## 상태 관리

| 상태 | 의미 |
|------|------|
| `Pending` | Desktop에서 작성 완료, Code가 아직 착수 안 함 |
| `In Progress` | Code가 구현 중 |
| `Done` | 구현 + 검증 완료 |
| `Cancelled` | 취소됨 (사유를 본문에 기록) |

Claude Code가 착수 시 `Pending` → `In Progress`, 검증 통과 시 → `Done`으로 업데이트한다.

## 작성 팁

### 배경 섹션
- 연구적 맥락이 길면 요약만 쓰고 `agent-docs/obsidian/` 문서를 경로로 참조
- Claude Code가 접근할 수 있는 경로만 사용 (repo 내부 경로)

### 구현 요구사항
- 의사코드나 함수 시그니처를 포함하면 정확도 향상
- "기존 `src/model/encoder.py`의 `Encoder` 클래스에 메서드 추가"처럼 정확한 위치 지정
- 변경하면 안 되는 것(부작용 방지)도 명시

### 검증 기준
- 체크박스 형태로 작성
- 가능하면 자동화된 검증: `pytest tests/test_encoder.py`, `python scripts/validate.py`
- 메트릭 기준이 있으면 수치 명시: "val/pearson > 0.75 for 3 consecutive epochs"

## todo.md 연동

프롬프트 작성 후 `agent-docs/tasks/todo.md`에 해당 항목을 추가하면, Claude Code가 세션 시작 시 자동으로 인식한다:

```markdown
# Todo

- [ ] PROMPT-001: Residual context separation 구현 (`tasks/prompts/PROMPT-001_residual-context-separation.md`)
- [ ] PROMPT-002: W&B metric logging 추가 (`tasks/prompts/PROMPT-002_wandb-metric-logging.md`)
```

## 워크플로우 전체 흐름

```
[Claude Desktop]                    [Git]              [Server Claude Code]
                                     │
 1. 연구 분석 + 설계                  │
 2. INV/FND 문서 작성                 │
 3. PROMPT-### 작성                   │
 4. todo.md에 항목 추가               │
                                     │
 5. 사용자: git push ──────────────→  │
                                     │  ──────────────→ 6. git pull
                                     │                  7. todo.md 읽기
                                     │                  8. PROMPT 읽기 + 구현
                                     │                  9. 검증 + status=Done
                                     │                  10. lessons.md 업데이트
                                     │
 11. 결과 확인 ←─────────────────────  │  ←───────────── git push
 12. RES/LRN 문서 작성                │
```
