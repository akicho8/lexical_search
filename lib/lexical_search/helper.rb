# -*- coding: utf-8 -*-

module LexicalSearch
  module Helper
    module_function

    #
    # タイプを返す
    #
    def expr_type?(str)
      case str
      when "("
        :t_open
      when ")"
        :t_close
      when /\A(and|or)\z/i
        :t_op
      else
        :t_value
      end
    end

    # 値？
    #
    # @example
    #   value?("1")   #=> true
    #   value?("and") #=> false
    #
    def value?(str)
      expr_type?(str) == :t_value
    end

    # 予約語？
    #
    # @example
    #   reserve_word?("1")   #=> false
    #   reserve_word?("and") #=> true
    #
    def reserve_word?(str)
      !value?(str)
    end

    # 無駄なカッコの内側のスペースを取って押し潰す
    #
    # @example
    #   "( 1 AND 2 )" => "(1 AND 2)"
    #
    def squish(str)
      if str.kind_of? Array
        str = str.join(" ")
      end
      str.gsub(/(\()\s+|\s+(\))/, "\\1\\2")
    end
  end
end
