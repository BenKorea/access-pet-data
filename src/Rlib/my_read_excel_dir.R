my_read_excel_dir <- function(directory, pattern = "\\.xlsx$", validate_columns = TRUE, strict_validation = FALSE) {
  logger::log_debug("엑셀 파일 읽기 시작: 디렉토리 = {directory}, 패턴 = {pattern}, validate_columns = {validate_columns}, strict_validation = {strict_validation}")
  
  # 1. 디렉토리 존재 확인
  logger::log_debug("디렉토리 존재: {dir.exists(directory)}")
  logger::log_debug("list.files() 실행 전 working dir: {getwd()}")
  
  # 2. 파일 목록 추출
  file_paths <- list.files(directory, pattern, full.names = TRUE)
  logger::log_debug("검색된 파일 수: {length(file_paths)}")
  logger::log_debug("파일 경로: {paste(file_paths, collapse = ', ')}")
  
  # 3. 파일 존재 여부와 파일별 실제 파일 존재 확인
  if (length(file_paths) > 0) {
    exist_check <- sapply(file_paths, file.exists)
    logger::log_debug("각 파일 존재 여부: {paste(exist_check, collapse=', ')}")
  }
  
  if (length(file_paths) == 0) {
    logger::log_error("패턴에 맞는 파일을 찾을 수 없음: {pattern}")
    logger::log_debug("실패 디렉토리 목록: {list.dirs(directory, recursive=FALSE)}")
    stop("No files found matching pattern: ", pattern)
  }
  
  logger::log_debug("파일 목록(basename): {paste(basename(file_paths), collapse = ', ')}")
  
  # 4. 컬럼명 검증 (옵션)
  if (validate_columns) {
    logger::log_debug("컬럼명 검증 시작, file_paths: {toString(file_paths)}")
    
    # 파일 1개라도 깨지면 예외 잡기
    column_names_list <- list()
    for (i in seq_along(file_paths)) {
      tryCatch({
        column_names_list[[i]] <- colnames(readxl::read_excel(file_paths[i], n_max = 0))
        logger::log_debug("컬럼 추출 성공: {basename(file_paths[i])}, 컬럼: {toString(column_names_list[[i]])}")
      }, error = function(e) {
        logger::log_error("컬럼 추출 실패: {basename(file_paths[i])}, 에러: {e$message}")
      })
    }
    logger::log_debug("모든 파일의 컬럼명 추출 완료, list 길이: {length(column_names_list)}")
    
    # 첫 파일 기준 컬럼
    reference_columns <- column_names_list[[1]]
    logger::log_debug("기준 컬럼 수: {length(reference_columns)}")
    logger::log_info("Reference columns (from {basename(file_paths[1])}):")
    logger::log_info("{paste(reference_columns, collapse = ', ')}")
    
    mismatched_files <- c()
    for (i in seq_along(column_names_list)) {
      if (!identical(sort(column_names_list[[i]]), sort(reference_columns))) {
        mismatched_files <- c(mismatched_files, basename(file_paths[i]))
        logger::log_warn("컬럼 불일치: {basename(file_paths[i])}, 컬럼: {toString(column_names_list[[i]])}")
      }
    }
    logger::log_debug("컬럼명 불일치 파일 수: {length(mismatched_files)}")
    
    if (length(mismatched_files) > 0) {
      logger::log_info("컬럼명 불일치 파일 상세 정보:")
      for (i in which(basename(file_paths) %in% mismatched_files)) {
        logger::log_info("Mismatched file: {basename(file_paths[i])}")
        logger::log_debug("Columns: {paste(column_names_list[[i]], collapse = ', ')}")
        missing_cols <- setdiff(reference_columns, column_names_list[[i]])
        extra_cols <- setdiff(column_names_list[[i]], reference_columns)
        if (length(missing_cols) > 0) {
          logger::log_info("Missing columns: {paste(missing_cols, collapse = ', ')}")
        }
        if (length(extra_cols) > 0) {
          logger::log_info("Extra columns: {paste(extra_cols, collapse = ', ')}")
        }
      }
      if (strict_validation) {
        logger::log_error("strict_validation=TRUE로 인해 중단")
        stop("Column validation failed. ", length(mismatched_files), " file(s) have different columns.")
      } else {
        logger::log_warn("Column differences detected in {length(mismatched_files)} file(s).")
        logger::log_info("INFO: Proceeding with rbind - Missing columns will be filled with NA values.")
      }
    } else {
      logger::log_info("SUCCESS: Column validation passed - All {length(file_paths)} files have consistent columns")
    }
  }
  
  logger::log_debug("데이터 읽기 시작 - 모든 파일을 문자형으로 읽음")
  # 각 파일을 문자형으로 읽어 data.table 리스트로 저장
  data_list <- list()
  for (i in seq_along(file_paths)) {
    logger::log_debug("파일 읽기: {basename(file_paths[i])}")
    tryCatch({
      data_list[[i]] <- data.table::as.data.table(readxl::read_excel(file_paths[i], col_types = "text"))
      logger::log_debug("읽기 완료: {basename(file_paths[i])}, 행수: {nrow(data_list[[i]])}, 컬럼수: {ncol(data_list[[i]])}")
    }, error = function(e) {
      logger::log_error("파일 읽기 실패: {basename(file_paths[i])}, 에러: {e$message}")
      data_list[[i]] <- NULL
    })
  }
  logger::log_debug("개별 파일 읽기 완료: {length(data_list)}개 파일, 유효데이터: {sum(sapply(data_list, is.data.frame))}")
  
  # 컬럼명 기준으로 행결합, 누락컬럼은 NA로 채움
  logger::log_debug("rbindlist 실행 전 NA 체크: {sum(sapply(data_list, is.null))}개 NULL")
  data <- data.table::rbindlist(data_list, use.names = TRUE, fill = TRUE)
  logger::log_debug("데이터 결합 완료: {nrow(data)}행 {ncol(data)}열, NA수: {sum(is.na(data))}")
  logger::log_info("엑셀 파일 읽기 완료: 총 {nrow(data)}행의 데이터")
  
  return(data)
}
