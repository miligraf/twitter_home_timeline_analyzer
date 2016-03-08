# twitter_home_timeline_analyzer

## Description
Retrieve a user's Twitter home timeline and send via email the list of the tweets that contain provided keywords.

## Requirements
- Twitter App consumer key and secret.

Per account, you'll need:
- Email address to which a list of matching tweets will be sent.
- Twitter account access tokens.
- Gmail account credentials.
- Array of keywords.

## TODO
- Use Mail gem.
- Decouple TwitterAccount class and create new classes for each required process.