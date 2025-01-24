
get_from_wikipedia <- function(url) {
  doc <- GET(url)
  doc <- readHTMLTable(doc=content(doc, "text"))
  doc <- doc$constituents
  doc[,colnames(doc)] <- lapply(doc[,colnames(doc)], FUN=as.character)
  doc_col_names <- as.character(doc[1,])
  doc_col_names <- gsub(pattern='[^A-Za-z0-9]', replacement='_', doc_col_names)
  doc_col_names <- gsub(pattern='_{2,}', replacement='_', doc_col_names)
  doc_col_names <- gsub(pattern='^_{1,}|_{1,}$', replacement='', doc_col_names)
  doc_col_names <- tolower(doc_col_names)
  colnames(doc) <- doc_col_names
  doc <- doc[-1,]
  
  return(doc)
}

make_gics_sub_industry_list <- function(doc) {
  gicsSubIndustryList <- tolower(unique(doc$gics_sub_industry))
  gicsSubIndustryList <- gicsSubIndustryList[order(gicsSubIndustryList)]
  
  return(gicsSubIndustryList)
}

get_prices <- function(symbol, startDateTxt) {
  startDate <- as.Date(startDateTxt)
  startYear <- as.numeric(format(startDate, '%Y'))
  startMonth <- as.numeric(format(startDate, '%m'))
  
  prices  <- tq_get(x = symbol, get = 'stock.prices', from = startDateTxt)
  prices$sales <- prices$volume * prices$adjusted
  prices$month <- format(prices$date, '%Y-%m')
  volume <- aggregate(volume ~ month, data=prices, FUN=sum)
  sales <- aggregate(sales ~ month, data=prices, FUN=sum)
  prices <- merge(volume, sales, by='month', all=TRUE)
  prices$price <- prices$sales/prices$volume
  prices$volume <- prices$sales <- NULL
  prices <- ts(prices$price[order(prices$month)], frequency=12, start=c(startYear, startMonth))
  
  return(prices)
}

get_prices_df <- function(prices) {
  prices_df <- data.frame(date=as.Date(prices), price=as.numeric(prices))
  prices_df$delta <- c(NA, diff(prices_df$price, lag=1))
  
  return(prices_df)
}
