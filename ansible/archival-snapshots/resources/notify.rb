# frozen_string_literal: true

require 'slack-ruby-client'

CHANNEL = '#forest-dump'
SLACK_TOKEN = ENV.fetch('ARCHIVAL_SLACK_TOKEN')
STATUS = ARGV[0]

client = Slack::Web::Client.new(token: SLACK_TOKEN)

message = if STATUS == 'success'
            '✅ Lite and Diff snapshots updated. 🌲🌳🌲🌳🌲'
          else
            '❌ Failed to update Lite and Diff snapshots. 🔥🌲🔥'
          end

client.chat_postMessage(channel: CHANNEL, text: message, as_user: true)
