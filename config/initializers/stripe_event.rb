StripeEvent.configure do |events|
  logger = Rails.logger
  
  events.subscribe 'charge.failed' do |event|
    stripe_id = event.data.object['customer']
      
    subscription = ::Subscription.find_by_stripe_id(stripe_id)
    if subscription
      logger.info "charge.failed webhook received for subscription #{subscription.id}"
      subscription.charge_failed
    else
      logger.error "charge.failed webhook received for unknown subscription with Stripe ID #{stripe_id}"
    end
  end
  
  events.subscribe 'invoice.payment_succeeded' do |event|
    stripe_id = event.data.object['customer']
    amount = event.data.object['total'].to_f / 100.0
    subscription = ::Subscription.find_by_stripe_id(stripe_id)
    if subscription
      logger.info "invoice.payment_succeeded webhook received for subscription #{subscription.id}"
      subscription.payment_succeeded(amount)
    else
      logger.error "invoice.payment_succeeded webhook received for unknown subscription with Stripe ID #{stripe_id}"
    end
  end
  
  events.subscribe 'charge.dispute.created' do |event|
    stripe_id = event.data.object['customer']
    subscription = ::Subscription.find_by_stripe_id(stripe_id)
    if subscription
      logger.info "charge.dispute.created webhook received for subscription #{subscription.id}"
      subscription.charge_disputed
    else
      logger.error "charge.dispute.created webhook received for unknown subscription with Stripe ID #{stripe_id}"
    end
  end
  
  events.subscribe 'customer.subscription.deleted' do |event|
    stripe_id = event.data.object['customer']
    subscription = ::Subscription.find_by_stripe_id(stripe_id)
    if subscription
      logger.info "customer.subscription.deleted webhook received for subscription #{subscription.id}"
      subscription.subscription_owner.try(:cancel)
    else
      # This is probably fine, if the event was triggered by deleting the subscription locally
      logger.info "customer.subscription.deleted webhook received for subscription #{stripe_id} which looks like it has already been deleted"
    end
  end
end
