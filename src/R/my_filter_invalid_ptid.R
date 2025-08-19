my_filter_invalid_ptid <- function(dt, id_col) {
  stopifnot(id_col %in% names(dt))
  
  valid_pattern <- "^(\\d{4,8}|[TSE].*)$"
  
  invalid_rows <- dt[!grepl(valid_pattern, get(id_col), ignore.case = TRUE), ]
  
  return(invalid_rows)
}