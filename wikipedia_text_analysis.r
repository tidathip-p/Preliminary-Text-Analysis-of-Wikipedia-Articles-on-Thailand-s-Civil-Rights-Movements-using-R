# Step 1: Data Scraping

# Install and load necessary packages
install.packages(c("rvest",
                   "xml2", 
                   "dplyr", 
                   "tokenizers", 
                   "tm", 
                   "SnowballC", 
                   "topicmodels", 
                   "ggplot2", 
                   "tidyverse", 
                   "wordcloud"))

library(rvest)
library(xml2)
library(dplyr)
library(tokenizers)
library(tm)
library(SnowballC)
library(topicmodels)
library(ggplot2)
library(tidyverse)
library(wordcloud)

# Define URLs
urls <- c(
  "https://en.wikipedia.org/wiki/1973_Thai_popular_uprising",
  "https://en.wikipedia.org/wiki/6_October_1976_massacre",
  "https://en.wikipedia.org/wiki/Black_May_(1992)",
  "https://en.wikipedia.org/wiki/2006_Thai_coup_d%27%C3%A9tat",
  "https://en.wikipedia.org/wiki/2010_Thai_political_protests",
  "https://en.wikipedia.org/wiki/2014_Thai_coup_d%27%C3%A9tat",
  "https://en.wikipedia.org/wiki/2020%E2%80%932021_Thai_protests"
)

# Data Scraping
article_content <- list()

for (url in urls) {
  webpage <- read_html(url)
  article_title <- html_text(html_nodes(webpage, "h1"))
  article_paragraphs <- html_text(html_nodes(webpage, "p"))
  article_content[[url]] <- list(title = article_title, content = article_paragraphs)
}

# View scraped data
print(article_content)

# Step 2: Data Cleaning and Preparation

cleaned_texts <- list()

for (url in names(article_content)) {
  paragraphs <- article_content[[url]]$content
  text <- paste(paragraphs, collapse = " ")
  tokens <- tokenize_words(text)
  tokens <- unlist(tokens)
  tokens <- tokens[!tokens %in% stopwords("en")]
  tokens <- wordStem(tokens, language = "en")
  cleaned_text <- paste(tokens, collapse = " ")
  cleaned_texts[[url]] <- list(title = article_content[[url]]$title, content = cleaned_text)
}

# View cleaned data
print(cleaned_texts)

# Convert to Data Frame
structured_data <- data.frame(
  url = character(),
  title = character(),
  content = character(),
  stringsAsFactors = FALSE
)

for (url in names(cleaned_texts)) {
  article <- cleaned_texts[[url]]
  structured_data <- rbind(
    structured_data,
    data.frame(
      url = url,
      title = article$title,
      content = article$content,
      stringsAsFactors = FALSE
    )
  )
}

# View structured data
View(structured_data)

# Step 3: Visualisation and Analysis

# 3.1 Word Cloud Generation

# Install and load necessary package
install.packages("wordcloud")
library(wordcloud)

# Create a function to generate and plot word clouds
generate_wordcloud <- function(text, title) {
  word_freq <- table(unlist(strsplit(text, "\\s+")))
  wordcloud(words = names(word_freq), freq = word_freq, max.words = 100,
            random.order = FALSE, colors = brewer.pal(8, "Dark2"),
            main = title)
}

# Generate and plot word clouds one by one
for (i in 1:nrow(structured_data)) {
  dev.new() 
  generate_wordcloud(structured_data$content[i], structured_data$title[i])
  readline(prompt = "Press [enter] to see the next word cloud...")
}

# 3.2 Sentiment Analysis

# 3.2.1 Install and Load Packages

install.packages("sentimentr")
install.packages("tidytext")

library(sentimentr)
library(tidytext)

# 3.2.2 Perform Sentiment Analysis 

# Create a custom function to perform sentiment analysis
analyze_sentiment <- function(text) {
  sentences <- get_sentences(text)
  sentiment <- sentiment(sentences)
  return(sentiment)
}

# Analyze sentiment for each article
sentiment_data <- list()

for (url in names(cleaned_texts)) {
  article <- cleaned_texts[[url]]$content
  sentiment <- analyze_sentiment(article)
  sentiment_data[[url]] <- list(
    title = cleaned_texts[[url]]$title,
    sentiment = sentiment
  )
}

# View sentiment data 
print(sentiment_data[[1]]) 

# 3.2.3 Aggregate Sentiment Scores

# Create a data frame to store aggregated sentiment scores
sentiment_scores <- data.frame(
  url = character(),
  title = character(),
  average_sentiment = numeric(),
  stringsAsFactors = FALSE
)

for (url in names(sentiment_data)) {
  article_sentiment <- sentiment_data[[url]]$sentiment
  avg_sentiment <- mean(article_sentiment$sentiment)
  
  sentiment_scores <- rbind(
    sentiment_scores,
    data.frame(
      url = url,
      title = sentiment_data[[url]]$title,
      average_sentiment = avg_sentiment,
      stringsAsFactors = FALSE
    )
  )
}

# View aggregated sentiment scores
View(sentiment_scores)

# 3.2.4 Visualize Sentiment Scores 

# Install and load necessary package
install.packages("ggplot2")
library(ggplot2)

# Plot the average sentiment scores for each article
ggplot(sentiment_scores, aes(x = reorder(title, average_sentiment), y = average_sentiment)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Average Sentiment Scores of Wikipedia Articles on Thai Civil Rights Movements",
       x = "Article Title",
       y = "Average Sentiment Score") +
  theme_minimal()
