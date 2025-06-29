import boto3
import json
import os
import logging
import requests# File: modules/lambda-slack_handler/python/slack_handler.py
import boto3
import json
import os
import logging
import requests

# Logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS Clients
dynamodb = boto3.client('dynamodb')
secretsmanager = boto3.client('secretsmanager')

# Environment variables
TABLE_NAME = os.environ['TABLE_NAME']
SECRET_NAME = os.environ['SECRET_NAME']

def get_slack_token():
    """
    Retrieve the Slack token from AWS Secrets Manager.

    Returns:
        str: The Slack token.

    Raises:
        Exception: If there is an error retrieving the Slack token.
    """
    try:
        secret_value = secretsmanager.get_secret_value(SecretId=SECRET_NAME)
        return json.loads(secret_value['SecretString'])['SLACK_TOKEN']
    except Exception as e:
        logger.error("Failed to retrieve Slack token: %s", str(e))
        raise

def get_user_id(username, token):
    """
    Get the Slack user ID for a given username.

    Args:
        username (str): The username to search for.
        token (str): The Slack token.

    Returns:
        str or None: The user ID if found, otherwise None.
    """
    url = "https://slack.com/api/users.list"
    headers = {'Authorization': f'Bearer {token}'}
    resp = requests.get(url, headers=headers).json()
    for member in resp.get("members", []):
        if member.get("name") == username:
            return member.get("id")
    return None

def get_channel_id(channel_name, token):
    """
    Get the Slack channel ID for a given channel name.

    Args:
        channel_name (str): The channel name to search for.
        token (str): The Slack token.

    Returns:
        str or None: The channel ID if found, otherwise None.
    """
    url = "https://slack.com/api/conversations.list"
    headers = {'Authorization': f'Bearer {token}'}
    resp = requests.get(url, headers=headers).json()
    for channel in resp.get("channels", []):
        if channel.get("name") == channel_name.strip("#"):
            return channel.get("id")
    return None

def get_post_ts(post_id):
    """
    Retrieve the timestamp of a post from DynamoDB.

    Args:
        post_id (str): The ID of the post.

    Returns:
        str or None: The timestamp of the post if found, otherwise None.
    """
    try:
        resp = dynamodb.get_item(
            TableName=TABLE_NAME,
            Key={'post_id': {'S': post_id}}
        )
        return resp['Item']['post_ts']['S'] if 'Item' in resp else None
    except Exception as e:
        logger.error("DynamoDB get_item error: %s", str(e))
        return None

def put_post_ts(post_id, ts):
    """
    Store the timestamp of a post in DynamoDB.

    Args:
        post_id (str): The ID of the post.
        ts (str): The timestamp to store.
    """
    try:
        dynamodb.put_item(
            TableName=TABLE_NAME,
            Item={
                'post_id': {'S': post_id},
                'post_ts': {'S': ts}
            }
        )
    except Exception as e:
        logger.error("DynamoDB put_item error: %s", str(e))

def delete_post_id(post_id):
    """
    Delete a post ID from DynamoDB.

    Args:
        post_id (str): The ID of the post to delete.
    """
    try:
        dynamodb.delete_item(
            TableName=TABLE_NAME,
            Key={'post_id': {'S': post_id}}
        )
    except Exception as e:
        logger.error("DynamoDB delete_item error: %s", str(e))

def post_message(channel_id, text, token):
    """
    Post a message to a Slack channel.

    Args:
        channel_id (str): The ID of the channel.
        text (str): The message text.
        token (str): The Slack token.

    Returns:
        str or None: The timestamp of the posted message if successful, otherwise None.
    """
    url = "https://slack.com/api/chat.postMessage"
    headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
    data = {"channel": channel_id, "text": text}
    resp = requests.post(url, headers=headers, json=data).json()
    return resp.get("ts") if resp.get("ok") else None

def update_message(channel_id, ts, text, token):
    """
    Update a Slack message.

    Args:
        channel_id (str): The ID of the channel.
        ts (str): The timestamp of the message to update.
        text (str): The new message text.
        token (str): The Slack token.
    """
    url = "https://slack.com/api/chat.update"
    headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
    data = {"channel": channel_id, "ts": ts, "text": text}
    requests.post(url, headers=headers, json=data)

def get_message_text(channel_id, ts, token):
    """
    Retrieve the text of a Slack message.

    Args:
        channel_id (str): The ID of the channel.
        ts (str): The timestamp of the message.
        token (str): The Slack token.

    Returns:
        str: The text of the message.
    """
    url = "https://slack.com/api/conversations.history"
    headers = {'Authorization': f'Bearer {token}'}
    params = {"channel": channel_id, "latest": ts, "inclusive": True, "limit": 1}
    resp = requests.get(url, headers=headers, params=params).json()
    return resp["messages"][0]["text"] if "messages" in resp and resp["messages"] else ""

def dm_user(user_name, message, token):
    """
    Send a direct message to a Slack user by username.

    Args:
        user_name (str): The username of the recipient.
        message (str): The message text.
        token (str): The Slack token.
    """
    user_id = get_user_id(user_name, token)
    if not user_id:
        logger.error("User '%s' not found", user_name)
        return

    # Open a DM channel with the user
    open_resp = requests.post(
        "https://slack.com/api/conversations.open",
        headers={
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        },
        json={"users": user_id}
    ).json()

    if not open_resp.get("ok"):
        logger.error("Error opening DM with user '%s': %s", user_name, open_resp.get("error"))
        return

    channel_id = open_resp["channel"]["id"]

    # Send the message
    post_resp = requests.post(
        "https://slack.com/api/chat.postMessage",
        headers={
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        },
        json={"channel": channel_id, "text": message}
    ).json()

    if post_resp.get("ok"):
        logger.info("DM sent to %s (%s)", user_name, user_id)
    else:
        logger.error("Failed to send DM to %s: %s", user_name, post_resp.get("error"))

def lambda_handler(event, context):
    """
    AWS Lambda function entry point for handling Slack interactions.

    Args:
        event (dict): The event data passed to the Lambda function.
        context (object): The context in which the Lambda function is called.
    """
    logger.info("Received event: %s", json.dumps(event))

    token = get_slack_token()
    action = event.get("action")  # post, update, append, repost
    post_id = event.get("post_id")
    message = event.get("message")
    channel = event.get("channel") or "#general"

    channel_id = get_channel_id(channel, token)
    if not channel_id:
        logger.error("Channel not found: %s", channel)
        return

    if action == "post" or not post_id:
        ts = post_message(channel_id, message, token)
        if post_id and ts:
            put_post_ts(post_id, ts)

    elif action == "update":
        ts = get_post_ts(post_id)
        if ts:
            update_message(channel_id, ts, message, token)
        else:
            ts = post_message(channel_id, message, token)
            if ts:
                put_post_ts(post_id, ts)

    elif action == "append":
        ts = get_post_ts(post_id)
        if ts:
            existing_text = get_message_text(channel_id, ts, token)
            updated_text = f"{existing_text}\n{message}"
            update_message(channel_id, ts, updated_text, token)
        else:
            ts = post_message(channel_id, message, token)
            if ts:
                put_post_ts(post_id, ts)

    elif action == "repost":
        delete_post_id(post_id)
        # Fall back to update logic
        ts = post_message(channel_id, message, token)
        if ts:
            put_post_ts(post_id, ts)

    else:
        logger.error("Unsupported action: %s", action)
