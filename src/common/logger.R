# logger/logger.R
# R 초간단 로깅 모듈

library(logger)
library(yaml)

# 로거 초기화
init_logger <- function() {
  config <- yaml::read_yaml("config/logger.yml")
  
  # 로그 레벨 설정
  logger::log_threshold(get(config$LOG_LEVEL, envir = asNamespace("logger")))
  
  # 간단한 출력 형식: [timestamp] [level] message
  logger::log_layout(logger::layout_glue_generator(
    format = '[{format(time, "%Y-%m-%d %H:%M:%S")}] [{toupper(level)}] {msg}'
  ))
  
  logger::log_info("R 로거 초기화 완료")
}

# 로그 함수들 (logger 패키지 함수 그대로 사용)
log_debug <- logger::log_debug
log_info <- logger::log_info  
log_warn <- logger::log_warn
log_error <- logger::log_error
