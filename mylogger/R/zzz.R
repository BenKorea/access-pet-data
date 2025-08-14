.onLoad <- function(libname, pkgname) {
  if (isTRUE(getOption("project.logger.env.loaded"))) return(invisible())
  
  candidates <- character(0)
  
  # 1) 명시 경로
  dotenv_path <- Sys.getenv("DOTENV_PATH", "")
  if (nzchar(dotenv_path)) candidates <- c(candidates, dotenv_path)
  
  # 2) 현재 작업 디렉토리
  candidates <- c(candidates, ".env")
  
  # 3) here::here(".env") (가능하면)
  if (requireNamespace("here", quietly = TRUE)) {
    candidates <- c(candidates, here::here(".env"))
  }
  
  # 실제 존재하는 첫 파일 선택
  candidates <- unique(normalizePath(candidates[file.exists(candidates)], mustWork = FALSE))
  if (length(candidates) > 0L) {
    env_file <- candidates[[1]]
    
    # dotenv 선호, 없으면 readRenviron 폴백
    ok <- FALSE
    if (requireNamespace("dotenv", quietly = TRUE)) {
      try({
        dotenv::load_dotenv(env_file, override = TRUE)
        ok <- TRUE
      }, silent = TRUE)
    }
    if (!ok) {
      # 단순 KEY=VALUE 포맷만 지원
      try(readRenviron(env_file), silent = TRUE)
    }
  }
  
  options("project.logger.env.loaded" = TRUE)
  
  # 기존 옵션 가드(초기 세팅)
  op <- options()
  if (is.null(op[["project.logger.config"]])) {
    options("project.logger.config" = NULL)
  }
}
