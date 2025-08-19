my_pad_ptid <- function(id) {
  id_trim <- trimws(as.character(id))
  is_numeric <- !is.na(id_trim) & grepl("^\\d+$", id_trim)
  
  result <- id_trim
  result[is_numeric] <- sprintf("%08d", as.integer(id_trim[is_numeric]))
  return(result)
}
