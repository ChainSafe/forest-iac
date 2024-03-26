# frozen_string_literal: true

require 'slack-ruby-client'

CHANNEL = ENV.fetch('SLACK_CHANNEL')
SLACK_TOKEN = ENV.fetch('SLACK_TOKEN')
EPOCH = ARGV[0]

client = Slack::Web::Client.new(token: SLACK_TOKEN)

message = "✅ Lite and Diff snapshots updated till #{EPOCH}. 🌲🌳🌲🌳🌲"

client.chat_postMessage(channel: CHANNEL, text: message, as_user: true)
