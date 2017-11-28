library(dplyr)
library(rdrop2)
library(rsconnect)
setwd("/Users/ikennedy/OneDrive - UW/UW/SOC 538/Final Project/Tweet Rater")
token <- readRDS("droptoken.rds")
db_dir = 'tweetratings'
response_dir = 'tweetratings/responses'
tweet_df = drop_read_csv(file.path(db_dir, "test_tweets.csv"), dtoken=token, row.names=1, colClasses = 'character')
#download responses from DB
#Collect existing files in responses and bind to a DF

  #Find all file names
file_names = drop_dir(path=response_dir, dtoken=token)$name
  #Read those files -> Bind them
rated_tweets = data_frame(round=integer(0),
                          user=character(0),
                          rating=integer(0),
                          stereotype=integer(0),
                          X=character(0), 
                          X.1=character(0),
                          timestamp = character(0))

#run through the filenames and bind each one to rated_tweets
for(file in file_names){
  tmp = drop_read_csv(file.path(response_dir,file), dtoken=token)
  rated_tweets = rbind(rated_tweets,tmp) %>% distinct()
  drop_move(from_path = file.path(response_dir,file), 
            to_path = file.path("tweetratings/responsearchive",file), dtoken=token)
}

#check if there's a ratedtweets file and bind existing tweets if there is
if(drop_exists("tweetratings/ratedtweets.csv", dtoken=token)){
  rated_tweets = rbind(drop_read_csv("tweetratings/ratedtweets.csv", row.names = 1,  dtoken=token), 
                       rated_tweets) %>% distinct()
}

write.csv(rated_tweets,"ratedtweets.csv")
drop_upload("ratedtweets.csv", path=db_dir, dtoken=token)

#Check the df for ratings >6 and collect those tweet IDs
finished_tweets = rated_tweets %>% count(X) %>% filter(n>6)
#Drop those tweet IDs from test_tweets.csv and update that file
new_tweet_set = tweet_df %>% subset(!(id %in% finished_tweets$X))
write.csv(new_tweet_set, file = "test_tweets.csv")
drop_move(from_path = "tweetratings/test_tweets.csv", 
          to_path = "tweetratings/tweetarchive/test_tweets.csv", 
          autorename = TRUE, dtoken = token)
drop_upload("test_tweets.csv", path=db_dir, dtoken=token)
deployApp()
y
