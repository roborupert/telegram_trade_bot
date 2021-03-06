module Actions
  class ShowPayment < Trailblazer::Operation
    include DefaultMessage
    success :translation_options
    success :responce_message
    success :update_user
    success :setup_price!
    success :setup_keyboard!
    success :setup_allowed_messages!
    success :send_responce

    def translation_options(options, product:, location:, treasure:, **)
      options['translation_options'] = {
        product_title: product.title,
        pay_price: TreasurePrice.call(product, treasure),
        treasure_id: treasure.id,
        location: I18n.t('pay_location', location: I18n.t(location)[1..-1])
      }
    end

    def setup_price!(options, product:, treasure:, **)
      options['price'] = TreasurePrice.call(product, treasure)
    end

    def responce_message(options, translation_options:, **)
      options['responce_message'] = I18n.t('show_payment', translation_options)
    end

    def update_user(_options, current_user:, treasure:, **)
      current_user.update(choosen_treasure_id: treasure.id, approval_date: Time.current) # TODO: add cron
    end

    def setup_keyboard!(options, current_user:, price:, **)
      options['key_board'] = KeyboardMarkups::RevertPayment.new(pay_from_balance: can_pay_from_balance?(current_user, price))
    end

    def can_pay_from_balance?(current_user, price)
      current_user.balance >= price
    end

    def setup_allowed_messages!(_options, current_user:, key_board:, **)
      current_user.update(allowed_messages: (key_board.buttons.flatten << MainListener::PAYMENT_CODE))
    end

    def send_responce(_options, bot:, message:, responce_message:, key_board:, current_user:, price:, **)
      msg = I18n.t(responce_msg(current_user.balance, price))
      bot.api.sendMessage(default_message(message, responce_message))
      bot.api.sendMessage(default_message(message, msg, key_board.perform))
      # bot.api.sendMessage(default_message(message, I18n.t('confirmation_code'), key_board.perform))
    end

    def responce_msg(balance, price)
      balance >= price ? 'click_pay_from_balance' : 'small_balance'
    end
  end
end
