# Load necessary libraries
library(twitteR)
library(tm)
library(wordcloud)
library(syuzhet)
library(RColorBrewer)

# Set up Twitter API access with placeholder credentials
consumer_key <- "your_consumer_key"
consumer_secret <- "your_consumer_secret"
access_token <- "your_access_token"
access_secret <- "your_access_secret"

# Clear existing OAuth file if needed
if (file.exists(".httr-oauth")) {
  file.remove(".httr-oauth")
  cat(".httr-oauth file removed.\n")
}

# Authenticate with Twitter API
setup_twitter_oauth(consumer_key, consumer_secret, access_token, access_secret)

# Function to clean the tweets
clean_tweet <- function(tweet) {
  tweet <- gsub("&amp", "", tweet)
  tweet <- gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", tweet)
  tweet <- gsub("@\\w+", "", tweet)
  tweet <- gsub("[[:punct:]]", "", tweet)
  tweet <- gsub("[[:digit:]]", "", tweet)
  tweet <- gsub("http\\w+", "", tweet)
  tweet <- gsub("[ \t]{2,}", "", tweet)
  tweet <- gsub("^\\s+|\\s+$", "", tweet)
  tolower(tweet)
}

# Function to fetch tweets and perform sentiment analysis
get_sentiment_analysis <- function(search_term, num_tweets) {
  # Fetch tweets
  tweets <- tryCatch(
    searchTwitter(search_term, n = num_tweets, lang = "en"),
    error = function(e) {
      message("Failed to fetch tweets: ", e$message)
      return(NULL)
    }
  )
  
  if (is.null(tweets) || length(tweets) == 0) {
    message("No tweets fetched or error occurred.")
    return(NULL)
  }
  
  tweet_texts <- sapply(tweets, function(x) x$getText())
  
  # Clean tweets
  clean_tweets <- tryCatch(
    sapply(tweet_texts, clean_tweet),
    error = function(e) {
      message("Failed to clean tweets: ", e$message)
      return(NULL)
    }
  )
  
  if (is.null(clean_tweets) || length(clean_tweets) == 0) {
    message("No valid tweets to analyze.")
    return(NULL)
  }
  
  # Create a corpus
  corpus <- Corpus(VectorSource(clean_tweets))
  
  # Text processing
  corpus <- tm_map(corpus, content_transformer(tolower))
  corpus <- tm_map(corpus, removePunctuation)
  corpus <- tm_map(corpus, removeNumbers)
  corpus <- tm_map(corpus, removeWords, stopwords("en"))
  corpus <- tm_map(corpus, stripWhitespace)
  
  # Check if corpus is empty
  if (length(corpus) == 0) {
    message("No valid text found after processing tweets.")
    return(NULL)
  }
  
  # Wordcloud visualization
  tryCatch(
    wordcloud(corpus, min.freq = 2, scale = c(3, 0.5), colors = brewer.pal(8, "Dark2"), random.color = TRUE, max.words = 100),
    error = function(e) {
      message("Failed to create wordcloud: ", e$message)
      return(NULL)
    }
  )
  
  # Sentiment analysis
  tryCatch(
    {
      sentiments <- get_nrc_sentiment(clean_tweets)
      sentiment_scores <- colSums(sentiments[,])
      
      # Plot sentiment scores
      barplot(sentiment_scores, las = 2, col = rainbow(10), ylab = "Count", main = "Sentiment Scores")
    },
    error = function(e) {
      message("Failed to perform sentiment analysis: ", e$message)
      return(NULL)
    }
  )
}

# Example usage of the function
search_term <- "Data Science"
num_tweets <- 100
get_sentiment_analysis(search_term, num_tweets)
