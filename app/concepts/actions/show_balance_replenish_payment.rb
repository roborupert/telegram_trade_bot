class Actions::ShowBalanceReplenishPayment < Trailblazer::Operation
  include DefaultMessage
  step :setup_keyboard!
  step :setup_allowed_messages!
  step :send_responce!

  def setup_keyboard!(options, **)
    options['key_board'] = KeyboardMarkups::RevertPayment.new
  end

  def setup_allowed_messages!(_options, current_user:, key_board:, **)
    current_user.update(allowed_messages: (key_board.buttons.flatten << MainListener::PAYMENT_CODE))
  end

  def send_responce!(_options, bot:, message:, key_board:, **)
    bot.api.sendMessage(default_message(message, I18n.t('replenish_balance_info',
                                                        wallet: Rails.application.secrets[:easy_pay_wallet],
                                                        pay_method: 'EasyPay'), key_board.perform))
  end
end
