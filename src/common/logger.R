# rpy-quarto-template/src/common/logger.R
# - 2025-08-13
# - .env 기반 동적 설정 (LOG_LEVEL, PROJECT_NAME, LOG_PATH 또는 SERVICE_LOG_PATH)
# - 콘솔 포맷: [YYYY-mm-dd HH:MM:SS] [LEVEL] [LOGGER_NAME] message
# - 파일 포맷: JSON Lines (1행 1로그)
# - 경로/권한 검증: 로그 디렉토리가 없거나 쓰기 불가면 즉시 stop()
# - Python src/common/logger.py와 변수명·동작을 최대한 통일
# - 편의 함수: log_debug/info/warn/error/critical, audit_log()

# 패키지: logger (https://cran.r-project.org/package=logger)
# 필요 패키지: logger, dotenv, jsonlite, fs

# rpy-quarto-template/src/common/logger.R
# R 환경 로거 – Python logger.py와 공통 규칙

if (!requireNamespace("logger", quietly = TRUE)) stop("install.packages('logger')")
if (!requireNamespace("dotenv", quietly = TRUE)) stop("install.packages('dotenv')")
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("install.packages('jsonlite')")
if (!requireNamespace("fs", quietly = TRUE)) stop("install.packages('fs')")

..r_logger_state <- new.env(parent = emptyenv())
..r_logger_state$initialized <- FALSE
..r_logger_state$logger_name <- ""

.VALID_LEVELS <- c("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG")

.level_to_threshold <- function(level) {
  lvl <- toupper(level %||% "INFO")
  if (!lvl %in% .VALID_LEVELS) lvl <- "INFO"
  switch(
    lvl,
    "CRITICAL" = logger::FATAL,
    "ERROR"    = logger::ERROR,
    "WARNING"  = logger::WARN,
    "INFO"     = logger::INFO,
    "DEBUG"    = logger::DEBUG
  )
}

`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0 && !is.na(a) && a != "") a else b

.require_parent_exists_and_writable <- function(path, tag = "file") {
  parent <- fs::path_dir(path)
  if (!fs::dir_exists(parent)) stop(sprintf("[%s] 로그 디렉토리가 존재하지 않습니다: %s", tag, parent))
  if (!fs::file_access(parent, mode = "write")) stop(sprintf("[%s] 로그 디렉토리에 쓰기 권한이 없습니다: %s", tag, parent))
}

# 여기서 fmt → format 으로 변경
.console_layout <- logger::layout_glue_generator(
  format = "[{format(time, '%Y-%m-%d %H:%M:%S', tz = Sys.timezone())}] [{level}] [{.logger_name}] {msg}"
)

.json_layout <- function(name_getter) {
  force(name_getter)
  function(level, msg, namespace = NA_character_, .logcall = sys.call(-1), .topcall = sys.call(1), .topenv = parent.frame()) {
    rec <- list(
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
      level = as.character(level),
      logger = name_getter(),
      message = as.character(msg),
      pid = Sys.getpid(),
      host = tryCatch(system("hostname", intern = TRUE)[1], error = function(e) NA_character_)
    )
    paste0(jsonlite::toJSON(rec, auto_unbox = TRUE), "\n")
  }
}

.current_logger_name <- function() ..r_logger_state$logger_name %||% ""

init_logger <- function(name = Sys.getenv("PROJECT_NAME", "")) {
  dotenv::load_dot_env(override = TRUE)
  level_env <- Sys.getenv("LOG_LEVEL", "INFO")
  project_name <- name %||% Sys.getenv("PROJECT_NAME", "")
  log_path <- Sys.getenv("LOG_PATH", NA_character_)
  service_log_path <- Sys.getenv("SERVICE_LOG_PATH", NA_character_)
  file_path <- log_path %||% service_log_path

  thr <- .level_to_threshold(level_env)
  logger::log_threshold(thr)
  ..r_logger_state$logger_name <- project_name

  logger::log_appender(logger::appender_console, index = 1)
  logger::log_layout(.console_layout, index = 1)

  if (!is.na(file_path) && nzchar(file_path)) {
    .require_parent_exists_and_writable(file_path, tag = "file_handler")
    logger::log_appender(logger::appender_file(file_path), index = 2)
    logger::log_layout(.json_layout(.current_logger_name), index = 2)
  }

  ..r_logger_state$initialized <- TRUE
  invisible(TRUE)
}

.log_with <- function(level_fun, msg) {
  if (!isTRUE(..r_logger_state$initialized)) init_logger()
  level_fun(msg)
  invisible(NULL)
}

log_debug    <- function(msg) .log_with(logger::log_debug, msg)
log_info     <- function(msg) .log_with(logger::log_info, msg)
log_warn     <- function(msg) .log_with(logger::log_warn, msg)
log_error    <- function(msg) .log_with(logger::log_error, msg)
log_critical <- function(msg) .log_with(logger::log_fatal, msg)

audit_log <- function(action, detail = NULL, compliance = "개인정보보호법 제28조") {
  if (!isTRUE(..r_logger_state$initialized)) init_logger()
  payload <- list(
    action = as.character(action),
    user = Sys.getenv("USER", unset = "unknown"),
    process_id = Sys.getpid(),
    server_id = tryCatch(system("hostname", intern = TRUE)[1], error = function(e) NA_character_),
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    compliance_check = compliance
  )
  if (!is.null(detail)) {
    if (is.list(detail)) payload <- c(payload, detail)
    else payload$detail <- as.character(detail)
  }
  logger::log_info(jsonlite::toJSON(payload, auto_unbox = TRUE))
  invisible(TRUE)
}

get_logger <- function(name = Sys.getenv("PROJECT_NAME", "")) {
  ..r_logger_state$logger_name <- as.character(name)
  invisible(..r_logger_state$logger_name)
}

