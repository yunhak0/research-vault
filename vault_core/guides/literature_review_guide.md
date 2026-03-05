---
guide_for: literature_review
version: 2.1
last_updated: 2026-02-25
---

# 문헌 리뷰 작성 가이드

## 1. 목적

읽은 논문의 핵심 내용을 체계적으로 정리하고,
우리 연구와의 연결점을 명확히 하여
논문 작성 시 효율적으로 인용할 수 있도록 한다.

## 2. ID 규칙

```
LIT-[NNN]

예시: LIT-001, LIT-013

- LIT: 고정 문자열 (Literature)
- NNN: 3자리 순번 (전체 vault에서 유일)
```

문헌 리뷰는 항상 프로젝트에 독립적이다.
프로젝트에서 참조할 때는 Obsidian wiki-link를 사용한다: `[[LIT-001_scVI]]`

## 3. 파일 위치

```
01_Global/literature/LIT-[NNN]_[PaperName].md

예시: 01_Global/literature/LIT-013_FlowMatching.md
```

모든 문헌 리뷰는 `01_Global/literature/` 폴더에 저장된다.
프로젝트 폴더 내에 문헌 리뷰를 저장하지 않는다.

## 4. 섹션별 작성 규칙

### 4.1 제목 (Title)

**형식**: 원 논문 제목 그대로 사용. 필요시 한글 번역 병기 가능.

### 4.2 메타 정보 (Metadata)

**필수 항목**:

| 항목 | 작성 규칙 | 예시 |
|------|----------|------|
| 저자 | 전체 저자 또는 "First Author et al." | "Vaswani et al." |
| 연도 | 출판 연도 | 2017 |
| 학회/저널 | 약어 사용 가능 | "NeurIPS 2017" |
| DOI/링크 | 접근 가능한 링크 | "https://arxiv.org/abs/1706.03762" |

### 4.3 한 줄 요약 (One-line Summary)

**목적**: 논문의 핵심 contribution을 한 문장으로 압축
**형식**: "X를 통해 Y를 달성/제안/증명" 구조 권장

**좋은 예**: "Self-attention만으로 구성된 Transformer 아키텍처를 제안하여 RNN 없이도 기계 번역에서 SOTA 성능을 달성했다."
**나쁜 예**: "Transformer에 대한 논문이다." (contribution이 드러나지 않음)

### 4.4 연구 질문 (Research Question)

**목적**: 저자들이 답하려는 핵심 질문 파악
**형식**: 물음표로 끝나는 질문

**찾는 방법**:
1. Abstract의 첫 부분 확인
2. Introduction의 마지막 문단 확인
3. 명시적 RQ가 없으면 논문 목적에서 추론

### 4.5 방법 (Methods)

**필수 내용**:
1. 제안하는 모델/알고리즘의 핵심 구조
2. 주요 기법 (novelty가 있는 부분)
3. 데이터셋

**형식**: bullet points 또는 짧은 단락

### 4.6 주요 결과 (Key Results)

**필수 내용**:
1. 주요 메트릭과 수치
2. 베이스라인 대비 성능
3. 핵심 실험 결과

**형식**: 테이블 권장

### 4.7 한계 (Limitations)

**필수 내용**:
1. 저자가 인정한 한계 (Discussion/Conclusion에서)
2. 내가 발견한 한계
3. 우리 연구 맥락에서의 gap

### 4.8 우리 연구와의 연결 (Connection to Our Research)

**필수 내용**:
1. 채택할 것 (적용 가능한 아이디어/방법)
2. 피할 것 (이 논문의 한계로 인해)
3. 확장할 것 (이 논문을 넘어서)

### 4.9 인용할 내용 (Quotable Content)

**필수 내용**:
1. 직접 인용할 문장 (따옴표로)
2. 핵심 수치
3. 페이지/섹션 번호

## 5. 문헌 리뷰 상태 (Status) 정의

| 상태 | 정의 |
|------|------|
| Draft | 읽는 중, 일부만 정리됨 |
| Completed | 전체 정리 완료 |
| Key Paper | 우리 연구의 핵심 참고 문헌 |

## 6. Obsidian ↔ Notion 아카이빙 규칙

- status가 Completed 또는 Key Paper일 때 아카이빙
- Type: LIT
- 아카이빙 후 Obsidian frontmatter에 `notion_url` 추가
- Obsidian 원본은 절대 삭제하지 않음

## 7. 흔한 실수와 주의사항

| 실수 | 문제점 | 올바른 방법 |
|------|--------|------------|
| 논문 전체 요약 시도 | 시간 낭비, 핵심 놓침 | 우리 연구와 관련된 부분 중심 |
| 우리 연구 연결 없음 | 왜 읽었는지 불명확 | 항상 "우리 연구와의 연결" 작성 |
| 인용 정보 누락 | 논문 작성 시 재탐색 필요 | 읽을 때 바로 기록 |
| 수치 없는 결과 정리 | 구체성 부족 | 핵심 수치 반드시 포함 |
| 한계 분석 없음 | 비판적 읽기 부족 | 한계점 반드시 기록 |