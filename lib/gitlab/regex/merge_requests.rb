# frozen_string_literal: true

module Gitlab
  module Regex
    module MergeRequests
      def merge_request
        @merge_request ||= /(?<merge_request>\d+)(?<format>\+s{,1})?/
      end

      def merge_request_draft
        /\A(?i)(\[draft\]|\(draft\)|draft:)/
      end
    end
  end
end
