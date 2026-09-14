# frozen_string_literal: true

module PicqerAPI
  class ReturnReasonResource < Resource
    PATH = "return_reasons"

    # `idreturn_reason` is required on every return line and only an id from this
    # list is accepted — free text is rejected with a 400. An unmapped PostCo
    # reason therefore blocks the return entirely, so the caller needs an
    # explicitly configured fallback reason rather than one derived from
    # `default: true`, which may be absent from the account.
    def all
      Objects::ReturnReason.new(paginate(PATH))
    end
  end
end
