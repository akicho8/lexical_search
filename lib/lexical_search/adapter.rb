module LexicalSearch
  module Adapter
    module MySQL
      def self.escaped_query(str)
        str.gsub("%", "\\%")
      end
    end

    module Sqlite3
      def self.escaped_query(str)
        str
      end
    end
  end
end
