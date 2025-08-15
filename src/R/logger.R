library(logger)


# .env 환경변수 로드
if (!requireNamespace("dotenv", quietly = TRUE)) {
  install.packages("dotenv")
}
library(dotenv)
dotenv::load_dot_env(file = ".env")

# 환경변수 읽기 및 기본값
LOG_LEVEL <- toupper(Sys.getenv("LOG_LEVEL", "DEBUG"))
PROJECT_NAME <- Sys.getenv("PROJECT_NAME", "Template")
SERVICE_LOG_PATH <- Sys.getenv("SERVICE_LOG_PATH", "logs/dev.log")

# 로그 디렉토리 체크
log_dir <- dirname(SERVICE_LOG_PATH)
if (!dir.exists(log_dir)) {
  stop(sprintf("로그 디렉토리가 없습니다: %s", log_dir))
}

# 로그 파일 경로
log_file <- SERVICE_LOG_PATH

# 콘솔/파일 동시 출력
log_appender(appender_tee(log_file))

# 포맷
log_layout(layout_glue_generator(
  format = '[{format(time, "%Y-%m-%d %H:%M:%S")}] [{toupper(level)}] [{PROJECT_NAME}] {msg}'
))

# 레벨 설정
valid_levels <- c("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG")
if (!LOG_LEVEL %in% valid_levels) LOG_LEVEL <- "DEBUG"
log_threshold(LOG_LEVEL)

log_info(sprintf("로깅 레벨: %s, 로그 경로: %s", LOG_LEVEL, log_file))

