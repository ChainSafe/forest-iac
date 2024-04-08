# frozen_string_literal: true

require 'slack-ruby-client'

CHANNEL = '#forest-notifications'
SLACK_TOKEN = ENV.fetch('ARCHIVAL_SLACK_TOKEN')
EPOCH = ARGV[0]
STATUS = ARGV[1]

client = Slack::Web::Client.new(token: SLACK_TOKEN)

message = if STATUS == 'success'
            "✅ Lite and Diff snapshots updated till #{EPOCH}. 🌲🌳🌲🌳🌲"
          else
            '❌ Failed to update Lite and Diff snapshots. 🔥🌲🔥'
          end

client.chat_postMessage(channel: CHANNEL, text: message, as_user: true)
