module Constraints
  class Mobile
    def self.matches?(request)
      p request.format
      request.subdomain.present? && request.subdomain == "m"
    end
  end
end
