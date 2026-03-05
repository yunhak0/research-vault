---
guide_for: notion_archive
version: 2.1
last_updated: 2026-02-25
---

# Notion 아카이빙 가이드

## 1. 목적

Obsidian에서 최종 상태에 도달한 문서를 Notion Research Archive에 보존한다.
Notion 아카이브는 **결론 중심 요약본**으로, Obsidian 원본의 전체 내용을 복사하지 않는다.
의사결정 기록과 핵심 인사이트를 빠르게 조회할 수 있는 레퍼런스 역할을 한다.

## 2. 아카이빙 대상

### 2.1 대상 문서 타입

| 타입 | 대상 문서 | 아카이빙 시점 |
|------|----------|-------------|
| PRB | `_overview.md` | Resolved 또는 장기 Investigating 중간 기록 |
| FND | 개별 FND 문서 | Validated |
| LIT | 개별 LIT 문서 | Completed / Key Paper |
| ENG | 개별 ENG 문서 | Completed (선택적) |
| WRT | 개별 WRT 문서 | Completed (제출 버전) |

### 2.2 아카이빙하지 않는 것

| 타입 | 사유 |
|------|------|
| INV | _overview.md를 통해 간접 기록 |
| LRN | _overview.md를 통해 간접 기록 |
| RES | _overview.md를 통해 간접 기록 (FND 승격 시 FND로 아카이빙) |
| Daily notes | Obsidian 전용 |
| Claude sessions | Obsidian 전용 |

### 2.3 아카이빙 조건

| 조건 | 설명 |
|------|------|
| Status 요건 | 타입별 위 표 참조 |
| 사용자 승인 | Claude가 제안 → 사용자 확인 후 실행 |
| 중복 확인 | 동일 ID가 Notion에 이미 존재하지 않을 것 |

## 3. 아카이빙 프로세스

### 3.1 사전 확인

1. Obsidian 문서의 frontmatter에서 `status` 확인
2. Notion Research Archive에 동일 `doc_id`가 있는지 검색
3. 사용자에게 아카이빙 의향 확인

### 3.2 Notion Properties 매핑

```
Name:           → frontmatter.title
userDefined:ID: → frontmatter.doc_id
Type:           → ID 접두어에서 추출 (PRB/FND/LIT/ENG/WRT)
Status:         → frontmatter.status
Project:        → frontmatter.project 기반
                  - "P001" → "P001_scDiffuser"
                  - project 없음 (LIT 등) → "Global"
Tags:           → frontmatter.tags 중 Notion 옵션에 매칭되는 것만
Created:        → frontmatter.created (PRB는 period 시작일)
Archived:       → 오늘 날짜
Obsidian Path:  → vault 내 상대 경로
Related IDs:    → frontmatter.related_docs에서 ID 추출 후 쉼표로 연결
```

### 3.3 Notion 본문 작성

1. 템플릿의 공통 구조 (요약 → 핵심 내용 → 결론 → 관련 문서) 적용
2. 타입에 맞는 "핵심 내용" 섹션 구조 선택 (notion_archive 템플릿 참조)
3. Obsidian 원본에서 해당 섹션의 핵심만 발췌/압축
4. 불필요한 세부사항, 체크리스트, 메모는 생략

### 3.4 사후 처리

1. Notion 페이지 생성 후 반환된 URL 확인
2. Obsidian 원본 frontmatter에 `notion_url` 추가
3. Obsidian 원본은 **절대 삭제하지 않음**

## 4. 본문 작성 규칙

### 4.1 요약 섹션

- **분량**: 1-2문장
- **내용**: 핵심 결론을 담은 압축 요약

### 4.2 핵심 내용 — 타입별

**PRB**: 문제 정의 + 핵심 발견 목록 + 해결책(또는 현황)
**FND**: 핵심 결정 + 검증 근거 + 설계 결정 사항
**LIT**: 방법 + 주요 결과 + 우리 연구와의 연결
**ENG**: 목표 + 개선 결과 (Before/After) + 검증
**WRT**: 섹션 본문 전체 또는 핵심 발췌

### 4.3 결론 섹션

- **Resolved/Completed**: 핵심 결론과 시사점
- **Validated**: 검증 근거
- **Rejected**: Rejection Reason 전문 포함

### 4.4 관련 문서 섹션

wiki-link 대신 텍스트로 변환. 링크 타입 이모지와 설명 유지.

## 5. Tags 매핑 규칙

| Notion 옵션 | 매칭되는 Obsidian tags |
|-------------|----------------------|
| foundation-model | foundation-model |
| single-cell | single-cell, scrna-seq |
| diffusion | diffusion, ldm, flow-matching |
| vae | vae, autoencoder, cvae |
| transformer | transformer, attention |
| batch-correction | batch-correction, batch-effect |

매칭되지 않는 태그는 무시. 새 태그 필요 시 사용자 확인 후 DB 스키마 먼저 업데이트.

## 6. 레거시 호환

기존에 아카이빙된 IDEA, EXP, LOG, ANA, SEC 타입은 Notion에 그대로 유지.
신규 아카이빙은 PRB, FND, LIT, ENG, WRT 타입만 사용.

## 7. 흔한 실수와 주의사항

| 실수 | 올바른 방법 |
|------|------------|
| Obsidian 전체 내용 그대로 복사 | 핵심만 발췌/압축 |
| notion_url 추가 누락 | 아카이빙 후 반드시 frontmatter에 URL 추가 |
| Notion에 없는 Tag 옵션 사용 | 매칭 옵션만 사용, 없으면 생략 |
| Obsidian 원본 삭제 | 절대 삭제하지 않음 |
| 중복 아카이빙 | 생성 전 동일 ID로 Notion 검색 |
| wiki-link 그대로 삽입 | 텍스트로 변환 |
| INV/LRN/RES 개별 아카이빙 | _overview.md만 아카이빙 |
