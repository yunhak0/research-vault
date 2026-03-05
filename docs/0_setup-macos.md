# macOS 환경 설치 가이드

이 문서는 macOS에서 Research Vault를 사용하기 위해 필요한 도구들을 설치하는 과정을 안내합니다.

## 목차

1. [Homebrew 설치](#1-homebrew-설치)
2. [기본 도구 설치](#2-기본-도구-설치)
3. [uv 설치](#3-uv-설치)
4. [nvm + Node.js 설치](#4-nvm--nodejs-설치)
5. [Claude Desktop 설치](#5-claude-desktop-설치)
6. [Claude Code 설치](#6-claude-code-설치)
7. [다음 단계](#다음-단계)

---

## 1. Homebrew 설치

**Homebrew**는 macOS용 패키지 관리자입니다. 터미널에서 명령어 하나로 다양한 도구를 설치할 수 있게 해줍니다.

**1) 터미널을 엽니다.**

- Spotlight (Cmd + Space) → "Terminal" 검색하여 실행

**2) Homebrew를 설치합니다.**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

설치 과정에서 macOS 비밀번호를 입력해야 할 수 있습니다.

**3) (Apple Silicon Mac만 해당) PATH를 설정합니다.**

M1/M2/M3/M4 Mac을 사용하는 경우, 설치 완료 후 출력되는 안내에 따라 PATH를 추가합니다:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**4) 설치를 확인합니다.**

```bash
brew --version
```

버전 번호가 출력되면 성공입니다.

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| `brew: command not found` (Apple Silicon) | 위 3번의 PATH 설정을 확인. 터미널을 닫고 새로 열기 |
| Xcode 관련 오류 | `xcode-select --install` 실행 후 재시도 |

---

## 2. 기본 도구 설치

```bash
brew install git jq
```

각 도구의 역할:

| 도구 | 용도 |
|------|------|
| `git` | 소스 코드 버전 관리 |
| `jq` | JSON 데이터 처리 (Claude Code hooks에 필요) |

> `curl`은 macOS에 기본 포함되어 있으므로 별도 설치가 불필요합니다.

설치를 확인합니다.

```bash
git --version
jq --version
```

---

## 3. uv 설치

**uv**는 Python 패키지 관리 도구입니다. 기존의 pip, venv, virtualenv를 대체하며, 훨씬 빠른 속도로 패키지를 설치합니다.

**1) 설치 스크립트를 실행합니다.**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**2) 셸 설정을 다시 불러옵니다.**

```bash
source ~/.zshrc
```

> macOS는 기본 셸이 zsh입니다.

**3) 설치를 확인합니다.**

```bash
uv --version
```

버전 번호가 출력되면 성공입니다 (예: `uv 0.6.x`).

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| `uv: command not found` | `source ~/.zshrc` 실행 후 재시도. 안 되면 터미널을 닫고 새로 열기 |

---

## 4. nvm + Node.js 설치

**nvm(Node Version Manager)**은 Node.js의 여러 버전을 설치하고 전환할 수 있는 도구입니다. Claude Code와 일부 MCP 서버 실행에 Node.js가 필요합니다.

**1) nvm을 설치합니다.**

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
```

**2) 셸 설정을 다시 불러옵니다.**

```bash
source ~/.zshrc
```

> `~/.zshrc` 파일이 없다는 오류가 나오면 먼저 `touch ~/.zshrc`로 생성한 후, 1번 설치를 다시 실행합니다.

**3) nvm 설치를 확인합니다.**

```bash
command -v nvm
```

`nvm`이 출력되면 성공입니다.

> `which nvm`은 동작하지 않습니다. nvm은 실행 파일이 아닌 셸 함수이기 때문입니다.

**4) Node.js LTS 버전을 설치합니다.**

```bash
nvm install --lts
```

**5) 설치를 확인합니다.**

```bash
node --version
npx --version
```

버전 번호가 출력되면 성공입니다.

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| `nvm: command not found` | 터미널을 닫고 새로 열기 |
| `node: command not found` | `nvm use --lts` 실행 |

---

## 5. Claude Desktop 설치

**1) Claude Desktop을 다운로드합니다.**

- [claude.ai/download](https://claude.ai/download)에서 macOS용 `.dmg` 파일을 다운로드합니다.

**2) 설치합니다.**

다운로드한 `.dmg` 파일을 열고, Claude 아이콘을 Applications 폴더로 드래그합니다.

**3) 로그인합니다.**

Claude 앱을 실행하고 계정으로 로그인합니다. 유료 구독(Pro/Team/Enterprise)이 필요합니다.

---

## 6. Claude Code 설치

**1) Claude Code를 설치합니다.**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

> 이 방식으로 설치하면 자동 업데이트가 지원됩니다.

Homebrew를 선호하는 경우:

```bash
brew install --cask claude-code
```

> Homebrew로 설치하면 자동 업데이트가 되지 않습니다. `brew upgrade claude-code`로 수동 업데이트해야 합니다.

**2) 셸 설정을 다시 불러옵니다.**

```bash
source ~/.zshrc
```

**3) 설치를 확인합니다.**

```bash
claude --version
```

**4) 인증을 진행합니다.**

```bash
claude
```

처음 실행하면 브라우저에서 로그인하라는 안내가 나옵니다. 안내에 따라 인증을 완료합니다.

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| `claude: command not found` | `source ~/.zshrc` 실행 후 재시도. 안 되면 터미널을 닫고 새로 열기 |

---

## 다음 단계

도구 설치가 완료되었습니다. 다음으로 MCP 서버 설정과 Research Vault 설치를 진행합니다:

→ [공통 설정 가이드 (MCP 서버 + Vault)](1_setup-common.md)
