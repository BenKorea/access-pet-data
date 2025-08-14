# R/logger.R
# 프로젝트 전용 로거 유틸리티 (Python logger.py와 API 패턴 통일 + 디버깅 메시지 추가)

.logger_env <- new.env(parent = emptyenv())

# --- .env 로더(소스 사용 시에도 1회 보장) -----------------------------
.load_env_once <- function() {
  if (isTRUE(getOption("project.logger.env.loaded"))) return(invisible(TRUE))
  
  candidates <- character(0)
  dotenv_path <- Sys.getenv("DOTENV_PATH", "")
  if (nzchar(dotenv_path)) candidates <- c(candidates, dotenv_path)
  candidates <- c(candidates, ".env")
  if (requireNamespace("here", quietly = TRUE)) {
    candidates <- c(candidates, here::here(".env"))
  }
  
  candidates <- unique(normalizePath(candidates[file.exists(candidates)], mustWork = FALSE))
  if (length(candidates) > 0L) {
    env_file <- candidates[[1]]
    message("[DEBUG] loading .env: ", env_file)
    
    ok <- FALSE
    if (requireNamespace("dotenv", quietly = TRUE)) {
      try({
        dotenv::load_dotenv(env_file, override = TRUE)
        ok <- TRUE
      }, silent = TRUE)
    }
    if (!ok) {
      try(readRenviron(env_file), silent = TRUE)
    }
  } else {
    message("[DEBUG] .env not found (skip)")
  }
  
  options("project.logger.env.loaded" = TRUE)
  invisible(TRUE)
}
# --------------------------------------------------------------------

# 내부 함수: 로그 디렉토리 검증
check_parent <- function(path) {
  message("[DEBUG] check_parent() path = ", path)
  parent <- dirname(path)
  message("[DEBUG] check_parent() parent = ", parent)
  if (!dir.exists(parent)) stop(sprintf("로그 디렉토리 없음: %s", parent), call. = FALSE)
  if (file.access(parent, 2) != 0) stop(sprintf("로그 디렉토리 쓰기 불가: %s", parent), call. = FALSE)
}

# 내부 함수: 로그 레벨 검증
get_log_level <- function() {
  lvl <- toupper(Sys.getenv("LOG_LEVEL", "INFO"))
  valid <- c("DEBUG", "INFO", "WARN", "ERROR", "CRITICAL")
  message("[DEBUG] get_log_level() -> ", lvl)
  if (!(lvl %in% valid)) "INFO" else lvl
}

# 로거 초기화 (Python setup_logging()과 동일)
setup_logging <- function() {
  # ✅ .env 자동 로드 (패키지 로드 없이 source()로만 써도 동작)
  .load_env_once()
  
  message("[DEBUG] setup_logging() 시작")
  proj <- Sys.getenv("PROJECT_NAME", "")
  lvl  <- get_log_level()
  svc  <- Sys.getenv("SERVICE_LOG_PATH", "")
  aud  <- Sys.getenv("AUDIT_LOG_PATH", "")
  
  message("[DEBUG] PROJECT_NAME: ", proj)
  message("[DEBUG] LOG_LEVEL: ", lvl)
  message("[DEBUG] SERVICE_LOG_PATH: ", svc)
  message("[DEBUG] AUDIT_LOG_PATH: ", aud)
  
  miss <- c(
    if (!nzchar(proj)) "PROJECT_NAME",
    if (!nzchar(svc)) "SERVICE_LOG_PATH",
    if (!nzchar(aud)) "AUDIT_LOG_PATH"
  )
  if (length(miss)) stop(sprintf("로깅 환경변수 누락: %s", paste(miss, collapse=", ")), call.=FALSE)
  
  check_parent(svc)
  check_parent(aud)
  
  want <- list(proj = proj, lvl = lvl, svc = svc, aud = aud)
  if (isTRUE(identical(getOption("project.logger.config"), want))) {
    message("[DEBUG] 기존 로거 설정과 동일 → 초기화 생략")
    return(invisible(TRUE))
  }
  
  message("[DEBUG] logger::log_threshold() → ", lvl)
  logger::log_threshold(lvl)
  
  message("[DEBUG] logger::log_layout() 설정")
  logger::log_layout(logger::layout_glue_generator(
    format = "[{format(Sys.time(), '%Y-%m-%d %H:%M:%S')}] [{level}] [{namespace}] {msg}"
  ))
  
  message("[DEBUG] 서비스 로그 핸들러 추가 → ", svc)
  logger::log_appender(logger::appender_file(svc), namespace = proj)
  
  message("[DEBUG] 감사 로그 핸들러 추가 → ", aud)
  logger::log_appender(logger::appender_file(aud), namespace = "audit")
  
  .logger_env$proj <- proj
  options("project.logger.config" = want)
  
  message("[DEBUG] setup_logging() 완료")
  invisible(TRUE)
}

# 지정 네임스페이스 로거 반환
get_logger <- function(name = NULL) {
  ns <- if (is.null(name)) .logger_env$proj else name
  message("[DEBUG] get_logger() namespace = ", ns)
  structure(list(namespace = ns), class = "mylogger")
}

# 내부 공통 출력 함수
.log <- function(level, msg, ns) {
  message("[DEBUG] .log() level=", level, ", namespace=", ns, ", msg=", msg)
  switch(level,
         DEBUG    = logger::log_debug(msg, namespace = ns),
         INFO     = logger::log_info(msg, namespace = ns),
         WARN     = logger::log_warn(msg, namespace = ns),
         ERROR    = logger::log_error(msg, namespace = ns),
         CRITICAL = logger::log_error(msg, namespace = ns),
         logger::log_info(msg, namespace = ns)
  )
}

# 래퍼 API
log_debug    <- function(msg) .log("DEBUG", msg, .logger_env$proj)
log_info     <- function(msg) .log("INFO",  msg, .logger_env$proj)
log_warn     <- function(msg) .log("WARN",  msg, .logger_env$proj)
log_error    <- function(msg) .log("ERROR", msg, .logger_env$proj)
log_critical <- function(msg) .log("CRITICAL", msg, .logger_env$proj)

# 감사 로그
audit_log <- function(action, detail = list(), compliance = "개인정보보호법 제28조") {
  payload <- c(list(
    action = action,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    user = Sys.getenv("USER", "unknown"),
    compliance_check = compliance
  ), detail)
  
  message("[DEBUG] audit_log() payload:")
  print(payload)
  
  msg <- paste(names(payload), payload, sep = "=", collapse = ", ")
  logger::log_info(msg, namespace = "audit")
}

# 레벨 제어
set_level <- function(level) {
  level <- toupper(level)
  message("[DEBUG] set_level() → ", level)
  logger::log_threshold(level)
}
get_level <- function() {
  lvl <- getOption("project.logger.config")$lvl %||% "INFO"
  message("[DEBUG] get_level() → ", lvl)
  lvl
}

# 종료
shutdown_logging <- function() {
  message("[DEBUG] shutdown_logging() 실행")
  # 상태가 꼬이는 경우를 피하기 위해 특정 네임스페이스만 리셋하거나, 필요 시 빈 문자열로 루트 적용
  ns_proj <- tryCatch(.logger_env$proj, error = function(e) NULL)
  if (is.character(ns_proj) && length(ns_proj) == 1 && nzchar(ns_proj)) {
    try(logger::log_appender(logger::appender_console(), namespace = ns_proj), silent = TRUE)
  } else {
    try(logger::log_appender(logger::appender_console(), namespace = ""), silent = TRUE)
  }
  try(logger::log_threshold("INFO"), silent = TRUE)
  options("project.logger.config" = NULL)
  rm(list = ls(envir = .logger_env), envir = .logger_env)
  invisible(TRUE)
}

`%||%` <- function(x, y) if (is.null(x) || is.na(x)) y else x
