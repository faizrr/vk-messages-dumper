require 'rubygems'
require 'vkontakte_api'
require 'ruby-progressbar'
require 'logger'
require 'hashie'

logger = Logger.new(STDOUT)
logger.level = Logger::ERROR
Hashie.logger = logger
VkontakteApi.configure do |config|
  config.logger = logger
end

token = ARGV[0]
vk = VkontakteApi::Client.new(token)

dialogs_length = vk.messages.get_dialogs[0]
users_ids = []
dialogs_progressbar = ProgressBar.create(title: 'Dialogs', total: dialogs_length, format: '<%B> %c/%C %t')
(0..dialogs_length).step(200) do |offset|
  dialogs = vk.messages.get_dialogs(offset: offset, count: 200)[1..-1]
  dialogs.each do |dialog|
    next if dialog['chat_id']
    users_ids << dialog['uid']
  end
  dialogs_progressbar.progress = offset
  sleep 0.4
end
dialogs_progressbar.finish
puts 'Dialogs list was downloaded!'

File.write('result.txt', '')
users_progressbar = ProgressBar.create(title: 'Chats with users', total: users_ids.length, format: '<%B> %c/%C %t')
users_ids.each do |user_id|
  chat_length = vk.messages.get_history(user_id: user_id, count: 200)[0]
  messages_with_current_user = []
  (0..chat_length).step(200) do |offset|
    messages_portion = vk.messages.get_history(offset: offset, user_id: user_id, count: 200)[1..-1]
    messages_with_current_user += messages_portion
    sleep 0.4
  end
  File.open('result.txt', 'a') do |f|
    messages_with_current_user.each { |m| f << JSON.generate(m) + "\n" }
  end

  users_progressbar.increment
end
puts 'Chats were downloaded!'
