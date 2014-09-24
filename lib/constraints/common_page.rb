module Constraints
  class CommonPage
    def self.matches?(request)
      Page.commons.find(request.params[:id]) rescue false
    end
  end
end
