maryland <- function(input_path){
  
  tmp_cont <- rvest::read_html(input_path) %>% html_table()
  tmp_cont <- tmp_cont[[1]] %>% as_tibble()
  colnames(tmp_cont) <- tmp_cont[1,]
  tmp_cont <- slice(tmp_cont, -1)
  
  return(tmp_cont)
}