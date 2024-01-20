# Nagios to Slack and Jira Integration

This script facilitates the integration of Nagios notifications with Slack and Jira, allowing for streamlined communication and ticket creation.

## Usage

1. **Nagios Parameters:**
   - `NOTIFICATIONTYPE`, `HOSTNAME`, `HOSTSTATE`, and other Nagios parameters are captured.

2. **Slack Webhook and Jira Parameters:**
   - Slack webhook URL and Jira parameters (username, API token, URL instance, and project key) are set.

3. **Functions:**
   - `does_issue_exist()`: Checks if a Jira issue with the same summary exists and is open.
   - `create_jira_issue()`: Creates a new Jira issue with specified summary and description.
   - `close_jira_issue()`: Closes an existing Jira issue.

4. **Format Message for Slack:**
   - Message content for Slack is formatted using Nagios parameters.

5. **Check If Notification Has Been Sent Before:**
   - Checks if the notification with the same host and status has been sent before, using `sent_notifications.txt`.

6. **If Notification Has Not Been Sent Before:**
   - Sends a notification to Slack and checks if a Jira issue with the same summary exists.
   - Takes appropriate actions based on conditions, such as closing the issue if the host is UP or creating a new issue if the host is DOWN.

7. **If Notification Has Been Sent Before:**
   - Displays a message indicating that the notification will not be resent.

## Requirements

- Bash environment.
- Appropriate permissions to read and write `sent_notifications.txt`.
- Access to Nagios parameters and Jira/Slack configurations.

## Setup

1. Clone the repository.
2. Set up the required parameters in the script.
3. Ensure the script has permission to read and write `sent_notifications.txt`.
4. Integrate the script into your Nagios environment.

## Notes

- This script relies on `sent_notifications.txt` to track previously sent notifications.
- Ensure the script has necessary permissions for file operations.

Feel free to modify and adapt the script to fit your specific requirements.
