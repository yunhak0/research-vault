---
template_for: notion_archive
version: 2.1
last_updated: 2026-02-25
---

# Notion 아카이빙 템플릿 (범용)

> 이 템플릿은 Obsidian 문서를 Notion Research Archive에 아카이빙할 때 사용한다.
> 아카이빙 대상: `_overview.md` (PRB 타입), FND, LIT, ENG, WRT 개별 문서.
> learned/resolved/investigating 내 개별 문서는 아카이빙하지 않음.

---

## Notion Properties 매핑

| Notion Property | 값 소스 |
|-----------------|---------|
| Name | Obsidian frontmatter `title` |
| ID | Obsidian frontmatter `doc_id` |
| Type | ID에서 추출 (PRB, FND, LIT, ENG, WRT) |
| Status | Obsidian frontmatter `status` |
| Project | Obsidian frontmatter `project` 기반 → "P001_scDiffuser" 또는 "Global" |
| Tags | Obsidian frontmatter `tags` 중 Notion 옵션에 매칭되는 것만 |
| Created | Obsidian frontmatter `created` (또는 `period` 시작일) |
| Archived | 아카이빙 실행 날짜 (오늘) |
| Obsidian Path | vault 내 상대 경로 |
| Related IDs | Obsidian frontmatter `related_docs` 배열에서 ID만 추출하여 쉼표로 연결 |

---

## Notion 페이지 본문 구조

```markdown
# {title}

## 요약
→ 문서의 핵심을 1-2문장으로 압축

## 핵심 내용
→ 타입별 핵심 섹션 (아래 타입별 가이드 참조)

## 결론
→ 최종 판단, 결과, 또는 상태 변경 사유

## 관련 문서
→ related IDs를 나열하며, 각 문서와의 관계를 한 줄로 기술
```

---

## 타입별 "핵심 내용" 섹션 가이드

### PRB (Problem Overview → _overview.md)
```markdown
## 핵심 내용
### 문제 정의
→ 문제의 핵심을 2-3문장으로

### 핵심 발견
→ 번호 매겨진 발견 목록 (LRN/RES 참조 포함)

### 해결책
→ 최종 해결책 요약 (Resolved인 경우)
→ 현재 진행 상황 (Investigating인 경우)
```

### FND (Foundation)
```markdown
## 핵심 내용
### 핵심 결정
→ 확립된 설계 결정의 What + Why

### 검증 근거
→ 실험적 증거 요약 (메트릭, W&B Run)

### 설계 결정 사항
→ 주요 선택과 그 이유
```

### LIT (Literature Review)
```markdown
## 핵심 내용
### 방법
→ 논문의 핵심 방법론 요약 (3-5문장)

### 주요 결과
→ 핵심 수치/발견 요약

### 우리 연구와의 연결
→ 채택할 것 / 피할 것 / 확장할 것
```

### ENG (Engineering)
```markdown
## 핵심 내용
### 목표
→ 엔지니어링 작업의 목표와 배경

### 개선 결과
→ Before/After 성능 지표 비교

### 검증
→ 회귀 테스트 결과, 품질 회귀 방어 확인
```

### WRT (Writing — Paper Section)
```markdown
## 핵심 내용
→ 해당 섹션의 본문 전체 또는 핵심 발췌
```

---

## 레거시 타입 (참조용, 신규 생성 금지)

기존에 아카이빙된 IDEA, EXP, LOG, ANA, SEC 타입은 Notion에 유지하되,
신규 아카이빙은 PRB, FND, LIT, ENG, WRT 타입만 사용한다.
