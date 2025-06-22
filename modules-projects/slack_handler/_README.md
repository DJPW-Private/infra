# Handles various types of Slack messages

## Post feature
  - If post_id == null
    - Post message

## Update feature
  - Keeps track of the Slack post's timestamp in DDB
  - If post_id != null
    - Check if post_id exists in DDB
      - if exists
        - Update the post
      - else
        - Write the post
        - Record post_id & post_ts in DDB

## Append feature
  - Keeps track of the Slack post's timestamp in DDB
  - If post_id != null
    1. Reads the post
    2. Appends the new message
    3. Rewrites the post
 
## Repost feature
  - post_ID is deleted from DynamoDB
  - Invokes Update feature


## get_user_id(user_name)
  - Returns user_id 

## get_channel_id(channel_name) 
  - Returns channel id

  - DynamoDB: used to store the post_id (such as a subject, partial timestamp - e.g. hour, or any field that associates the post with the timestamp), and post_timestamp.
  - Lambda: used to:
    - post Slack messages
    - query & updated DDB
      - If post_id is not supplied, use Post feature
        - Otherwise: use Update feature
