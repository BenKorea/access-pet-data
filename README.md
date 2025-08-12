# 프로젝트 목적
R과 Python, Quarto 기반 웹사이트 개발 프로젝트 준비과정에서 반복적으로 생성되는 파일과 설정을 template로 제공합니다. 

# Agent 최적화 안내 (Copilot/ChatGPT/Claude 등 공통)
이 템플릿의 `README.md`는 에이전트가 프로젝트 규칙을 빠르게 이해하고 일관된 코드를 제안하도록 돕는 **지침 문서**입니다. GitHub에서는 `.github/copilot-instructions.md`로 심볼릭 링크하여 Copilot이 우선 참고하도록 구성할 수 있습니다.

## README.md 목적
- 에이전트에게 **필수 규칙을 간결히 요약**하여 잘못된 코드 제안을 줄입니다.
- 로컬/원격 환경 차이(예: Wiki 링크 경로)에서 생길 수 있는 혼란을 미리 방지합니다.

## 주요 지침 요약
- 모든 Python 로깅은 `src/common/logger.py` 기반으로 작성
- 로그 레벨, 경로, 프로젝트명은 **.env**에서 관리 (`LOG_LEVEL`, `SERVICE_LOG_PATH`, `PROJECT_NAME` 등)
- 로깅 포맷, 핸들러 설정은 **config/logging.yml**에서 관리
- **경로·권한 오류는 반드시 예외 처리** (로그 디렉토리 자동 생성 금지)
- 코드에서는 **`log_info`, `log_error` 등 래퍼 함수 우선 사용** (직접 `logging.getLogger` 호출 지양)

## 로깅 프레임워크 안내
이 프로젝트는 환경변수(.env)와 logging.yml 기반의 표준화된 파이썬 로깅 프레임워크를 제공합니다.
- 환경변수(.env)로 로그 레벨, 경로, 프로젝트명 등 동적 설정
- logging.yml로 핸들러/포맷/레벨 등 커스텀 설정
- 경로 및 권한 검증, 환경변수 치환 지원
- get_logger, log_info 등 편의 함수 및 감사 로그(audit_log) 지원

**스크립트에서 로깅이 필요할 때는 반드시 `src/common/logger.py`를 사용하십시오.**

자세한 사용법, 설정 예시, 고급 기능은 [**Wiki**의 문서](wiki/logging-reference.md)를 참고하십시오.

## Wiki 링크 (로컬/원격 차이 안내)
- 로컬에서는 `wiki/logging-reference.md` 같은 상대 경로가 보이더라도, **GitHub 원격 저장소에서는 동작하지 않을 수 있습니다.**
- GitHub에서 Wiki 문서는 별도 저장소로 관리되므로, **Repository의 Wiki 탭으로 직접 이동**하여 확인하십시오.
- 필요 시 절대 링크 형태를 병기하십시오(예: `https://github.com/<OWNER>/<REPO>/wiki/Logging-Reference`).

## Copilot/ChatGPT 스크립트 제안 지침
- **극단적으로 간결·직관·디버그 친화적** 코드를 우선 제안
- Windows/Linux/Mac 간 경로 차이와 권한 이슈를 **사전 고지**하고, 필요 시 대체 경로 예시를 함께 제안
- 에러 메시지(예: 환경변수 치환 실패, 권한 오류)를 기반으로 **수정 가이드라인**까지 함께 제안

---

- `renv.lock`: R 패키지 의존성 관리
- 기타 상세 문서는 Wiki를 참고해 주십시오.
