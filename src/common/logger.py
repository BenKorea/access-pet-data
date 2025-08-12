# rpy-quarto-template/src/common/logger.py
"""
AI-최적화 로깅 유틸리티
- 2025-08-12 (rev.AI-1)
- 목적: ChatGPT/Copilot 등 에이전트가 코드 제안 시 일관된 로깅 패턴을 따르도록 가이드를 내장
- 특징:
  - 환경변수(.env) 기반 동적 설정
  - logging.yml 기반 커스텀 핸들러/포맷/레벨 적용
  - 파일 핸들러의 환경변수 치환 및 경로/권한 검증(컴플라이언스 상 자동 생성 금지)
  - 루트/서브 로거 레벨 일괄 오버라이드
  - get_logger, log_info 등 래퍼 함수 제공 (에이전트 제안 코드에 우선 사용 권장)
  - 감사 로그(audit_log) 지원(JSON 구조)
"""
from __future__ import annotations

import os
import socket
import logging
import logging.config
from pathlib import Path
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import yaml
from dotenv import load_dotenv

# .env 로드 (ENV 우선)
load_dotenv(override=True)

# PROJECT_NAME은 빈 문자열보다 의미 있는 기본값이 디버깅에 유리
PROJECT_NAME = os.getenv("PROJECT_NAME", "default")

VALID_LEVELS = {"CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"}


def _get_log_level() -> str:
    """
    .env의 LOG_LEVEL을 읽어 대문자로 반환합니다.
    허용되지 않은 값이면 INFO로 폴백합니다.
    에이전트: 코드 제안 시 하드코딩 대신 이 함수를 사용하세요.
    """
    level = os.getenv("LOG_LEVEL", "INFO").upper()
    return level if level in VALID_LEVELS else "INFO"


def _expand_env_placeholders(value: str) -> str:
    """
    ${VAR} 또는 $VAR 형태의 환경변수를 실제 값으로 치환합니다.
    에이전트: 파일 경로를 제안할 때 ${SERVICE_LOG_PATH}/service.log 같은 형태를 허용합니다.
    """
    if not isinstance(value, str):
        return value
    return os.path.expandvars(value)


def _require_parent_exists_and_writable(path: Path, handler_name: str) -> None:
    """
    법/컴플라이언스상 로그 누락 방지를 위해 디렉토리 자동생성은 하지 않습니다.
    - 존재하지 않거나 쓰기 불가면 명확한 예외 메시지로 실패시킵니다.
    에이전트: 권한 오류가 발생하면 디렉토리 생성/권한 부여 스크립트를 별도로 제안하세요.
    """
    parent = path.parent
    if not parent.exists():
        raise FileNotFoundError(
            f"[{handler_name}] 로그 디렉토리가 존재하지 않습니다: {parent} \n"
            "- Linux 예: /var/log/ai4rm, ~/logs\n"
            "- Windows 예: C:\\logs, %USERPROFILE%\\logs\n"
            "- .env의 SERVICE_LOG_PATH 또는 AUDIT_LOG_PATH 설정을 확인하세요."
        )
    if not os.access(parent, os.W_OK):
        raise PermissionError(
            f"[{handler_name}] 로그 디렉토리에 쓰기 권한이 없습니다: {parent} \n"
            "- Unix: chmod/chown 검토, Windows: 보안 탭 권한 부여 필요\n"
            "- CI 환경이라면 실행 사용자(예: svc 계정) 권한을 확인하세요."
        )


def _load_logging_config() -> dict:
    """
    프로젝트 루트의 config/logging.yml을 불러와 환경변수 치환 및 검증을 수행합니다.
    - LOG_LEVEL로 root 및 서브 로거 레벨을 일괄 오버라이드
    - FileHandler의 filename에 포함된 환경변수 치환 + 경로/권한 검증
    에이전트: 신규 핸들러를 추가할 때도 이 규칙을 따르도록 제안하세요.
    """
    # src/common/logger.py 기준 상대 경로
    yaml_path = Path(__file__).parent.parent.parent / "config" / "logging.yml"
    if not yaml_path.exists():
        raise FileNotFoundError(f"logging.yml 파일이 필요합니다: {yaml_path}")

    with open(yaml_path, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    # 1) LOG_LEVEL 환경변수로 루트/서브 로거 레벨 오버라이드
    level = _get_log_level()
    config.setdefault("root", {})["level"] = level
    for _, logger_cfg in config.get("loggers", {}).items():
        logger_cfg["level"] = level

    # 2) 파일 핸들러의 filename에 포함된 ${ENV} 치환 + 경로 유효성 필수 검사
    for handler_name, handler_cfg in config.get("handlers", {}).items():
        if handler_cfg.get("class") == "logging.FileHandler":
            raw_filename = handler_cfg.get("filename", "")
            if not raw_filename:
                raise ValueError(f"[{handler_name}] filename이 지정되어 있지 않습니다.")

            expanded = _expand_env_placeholders(raw_filename)
            # 치환 실패 감지(그대로 남아있다면 ENV 누락 가능성)
            if expanded == raw_filename and ("${" in raw_filename or "$" in raw_filename):
                raise ValueError(
                    f"[{handler_name}] 환경변수 치환 실패: {raw_filename} \n"
                    "- .env에 해당 변수가 설정되어 있는지 확인하세요.\n"
                    "- 예: SERVICE_LOG_PATH=/var/log/ai4rm/service.log"
                )

            file_path = Path(expanded)
            _require_parent_exists_and_writable(file_path, handler_name)
            handler_cfg["filename"] = str(file_path)

    return config


def setup_logging() -> None:
    """
    dictConfig로 로깅을 초기화합니다.
    에이전트: 최초 로그 사용 전 자동 호출되므로, 일반적으로 수동 호출은 불필요합니다.
    """
    config = _load_logging_config()
    logging.config.dictConfig(config)


def get_logger(name: Optional[str] = PROJECT_NAME) -> logging.Logger:
    """
    지정한 이름의 로거를 반환합니다.
    - 핸들러가 아직 설정되지 않았다면 setup_logging()을 자동 호출합니다.
    에이전트: 일반 코드 템플릿에서는 이 함수를 사용하거나, 아래 래퍼를 사용하세요.
    """
    root_logger = logging.getLogger()
    if not root_logger.hasHandlers():
        setup_logging()
    return logging.getLogger(name or None)


def audit_log(action: str, detail: Optional[Dict[str, Any]] = None, compliance: str = "개인정보보호법 제28조") -> None:
    """
    감사 로그를 JSON 형식으로 기록합니다.
    - action: 수행한 작업의 식별자(예: "파일_처리_완료")
    - detail: 부가 메타데이터(dict)
    - compliance: 적용되는 컴플라이언스 조항
    에이전트: 개인정보 처리, 접근 제어, 권한 변경 등 보안 이벤트 기록 시 이 함수를 제안하세요.
    """
    audit_logger = get_logger("audit")
    user = os.getenv("USER") or os.getenv("USERNAME") or "unknown"
    log = {
        "action": action,
        "user": user,
        "process_id": os.getpid(),
        "server_id": socket.gethostname(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "compliance_check": compliance,
    }
    if detail:
        log.update(detail)
    audit_logger.info(log)


# convenience wrappers (에이전트 우선 사용 권장)
def log_debug(msg: str) -> None:
    """디버깅 상세 정보 기록. 변수 값/흐름 추적에 사용."""
    get_logger().debug(msg)


def log_info(msg: str) -> None:
    """일반 진행 상황/결과 기록. 기본 로그로 권장."""
    get_logger().info(msg)


def log_warn(msg: str) -> None:
    """주의 상황 기록. 잠재적 문제/설정 누락 경고."""
    get_logger().warning(msg)


def log_error(msg: str) -> None:
    """오류 상황 기록. 예외 처리와 함께 사용 권장."""
    get_logger().error(msg)


def log_critical(msg: str) -> None:
    """서비스 중단급 치명적 오류 기록. 즉시 조치 필요."""
    get_logger().critical(msg)
