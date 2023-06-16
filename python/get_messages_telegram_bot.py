import telebot

token = 'xxx'
bot = telebot.TeleBot(token)

########################## Обработчик текстовых сообщений ##########################
@bot.message_handler(content_types=['text'])
def take_messages(message):
  print(message)

bot.polling(none_stop=True)
