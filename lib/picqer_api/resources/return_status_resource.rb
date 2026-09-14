# frozen_string_literal: true

module PicqerAPI
  class ReturnStatusResource < Resource
    PATH = "return_statuses"

    # The return-level vocabulary is defined by whoever owns the Picqer account —
    # for a fulfilment setup that is the provider, not the retailer — and is
    # editable at any time. Pull it at connect time and re-pull on refresh; never
    # hardcode ids or names.
    #
    # `default: true` is not stable: an account was observed with no status and no
    # reason carrying it. `completed` is the only dependable semantic marker.
    def all
      Objects::ReturnStatus.new(paginate(PATH))
    end

    def completed
      all.select { |status| status.completed }
    end
  end
end
