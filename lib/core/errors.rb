module Core
  module Errors
    class Base < StandardError; end
    class ValidationError < Base; end
    class NotFoundError < Base; end
  end
end
