# frozen_string_literal: true

require_relative "picqer_api/version"

module PicqerAPI
  autoload :Client, "picqer_api/client"
  autoload :Base, "picqer_api/object"
  autoload :RateLimit, "picqer_api/rate_limit"
  autoload :Resource, "picqer_api/resource"
  autoload :Text, "picqer_api/text"
  autoload :Webhook, "picqer_api/webhook"

  autoload :Error, "picqer_api/errors"
  autoload :APIError, "picqer_api/errors"
  autoload :AuthenticationError, "picqer_api/errors"
  autoload :ValidationError, "picqer_api/errors"
  autoload :NotFoundError, "picqer_api/errors"
  autoload :NotAccessibleError, "picqer_api/errors"
  autoload :PaginationError, "picqer_api/errors"
  autoload :RateLimitError, "picqer_api/errors"
  autoload :ServerError, "picqer_api/errors"

  autoload :HookResource, "picqer_api/resources/hook_resource"
  autoload :OrderResource, "picqer_api/resources/order_resource"
  autoload :ProductResource, "picqer_api/resources/product_resource"
  autoload :ReturnReasonResource, "picqer_api/resources/return_reason_resource"
  autoload :ReturnResource, "picqer_api/resources/return_resource"
  autoload :ReturnStatusResource, "picqer_api/resources/return_status_resource"
  autoload :WarehouseResource, "picqer_api/resources/warehouse_resource"

  module Objects
    autoload :Hook, "picqer_api/objects/hook"
    autoload :Order, "picqer_api/objects/order"
    autoload :Product, "picqer_api/objects/product"
    autoload :Return, "picqer_api/objects/return"
    autoload :ReturnLog, "picqer_api/objects/return_log"
    autoload :ReturnReason, "picqer_api/objects/return_reason"
    autoload :ReturnStatus, "picqer_api/objects/return_status"
    autoload :Warehouse, "picqer_api/objects/warehouse"
    autoload :WebhookEvent, "picqer_api/objects/webhook_event"
  end
end
