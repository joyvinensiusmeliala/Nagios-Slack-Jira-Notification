#!/bin/bash

# Nagios parameters
NOTIFICATIONTYPE="$1"
HOSTNAME="$2"
HOSTADDRESS="$3"
HOSTSTATE="$4"
HOSTOUTPUT="$5"
SERVICEDESC="$6"
SERVICESTATE="$7"
SERVICEOUTPUT="$8"

# Slack webhook URL
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"

# Jira parameters
JIRA_USERNAME="jvinensius@gmail.com"
JIRA_API_TOKEN="ATATT3xFfGF0bMfJ-x4w79le_Y1d79t8yN7nUNwOJoNGy5cZgALGuisshAzRzfZ5k7s5tHGr49ue0X3UCO5hCX-iv9Vl4GU6y05XYXnj8FewMpikohR5QaXN71ZqmyAzXwfnsBwf9R13Th281oC3XYni6zM4dmc_PAJJ4WMbHiu6GfZ_PRTLtBs=5EC5F872"
JIRA_INSTANCE="https://staging-nagios.atlassian.net"
PROJECT_KEY="ITPROJECT"

# Variable to store unique information for each notification
NOTIFICATION_INFO="$HOSTNAME-$HOSTSTATE"

# Function to check if a Jira issue is open
function is_issue_open() {
  local issue_key="$1"
  local status=$(curl -s -u $JIRA_USERNAME:$JIRA_API_TOKEN -X GET -H "Content-Type: application/json" $JIRA_INSTANCE/rest/api/2/issue/$issue_key | jq -r '.fields.status.name')
  [[ "$status" == "Open" ]]
}

# Function to create a Jira issue
function create_jira_issue() {
  local summary="$1"
  local description="$2"
  curl -D- -u $JIRA_USERNAME:$JIRA_API_TOKEN -X POST -H "Content-Type: application/json" \
       -d "{\"fields\": {\"project\": {\"key\": \"$PROJECT_KEY\"},\"summary\": \"$summary\", \"description\": \"$description\",\"issuetype\": {\"name\": \"Task\"}}}" \
       $JIRA_INSTANCE/rest/api/2/issue/
}

# Function to close a Jira issue
function close_jira_issue() {
  local issue_key="$1"
  curl -u $JIRA_USERNAME:$JIRA_API_TOKEN -X POST -H "Content-Type: application/json" \
       -d '{"update": {"comment": [{"add": {"body": "Resolved automatically by Nagios"}}]}, "transition": {"id": "2"}}' \
       $JIRA_INSTANCE/rest/api/2/issue/$issue_key/transitions
}

# Check if this notification has been sent before
if [ -f "sent_notifications.txt" ]; then
  grep -q "$NOTIFICATION_INFO" sent_notifications.txt
  notification_exists=$?
else
  notification_exists=1
fi

# If the notification has not been sent before, proceed
if [ $notification_exists -ne 0 ]; then
  # Format message for Slack
  SLACK_MESSAGE="*Nagios Alert - $NOTIFICATIONTYPE Notification*\n\n"
  SLACK_MESSAGE+="*Host Information:*\nHost: $HOSTNAME\nIP: $HOSTADDRESS\nState: $HOSTSTATE\n\n"
  SLACK_MESSAGE+="*Additional Info:*\n$HOSTOUTPUT"

  # Send message to Slack
  curl -X POST -H "Content-type: application/json" --data \
      "{\"text\":\"$SLACK_MESSAGE\",\"username\":\"Nagios\"}" \
      $SLACK_WEBHOOK_URL

  # Save the notification info to the file
  echo "$NOTIFICATION_INFO" >> sent_notifications.txt

  # Wait for a moment to give Slack time to send the notification
  sleep 5

  # Check if there's an existing issue with the same summary
  SUMMARY="Termonitor $HOSTNAME state $HOSTSTATE"
  does_issue_exist "$SUMMARY"

  # Capture the return value of the function
  result=$?

  # Display the result
  if [ $result -eq 0 ]; then
    if [ "$HOSTSTATE" == "UP" ]; then
      # Close the existing issue if host is UP
      close_jira_issue "$result"
    else
      # Do nothing if host is DOWN and the issue is open
      echo "Tiket dengan summary yang sama sudah ada dan masih terbuka."
    fi
  else
    # Create a new issue only if host is DOWN
    if [ "$HOSTSTATE" == "DOWN" ]; then
      # Check if the existing issue is closed, then create a new issue
      if [ $(is_issue_open "$result") == false ]; then
        DESCRIPTION="*HOST $NOTIFICATIONTYPE Notification*\n\n"
        DESCRIPTION+="*Host Information:*\nHost: $HOSTNAME\nIP: $HOSTADDRESS\nState: $HOSTSTATE\n\n"
        DESCRIPTION+="*Additional Info:*\n$HOSTOUTPUT"

        create_jira_issue "$SUMMARY" "$DESCRIPTION"
      else
        echo "Tiket dengan summary yang sama sudah ada dan telah ditutup."
      fi
    fi
  fi
else
  echo "Notifikasi untuk $NOTIFICATION_INFO sudah dikirim sebelumnya. Tidak mengirim ulang."
fi
