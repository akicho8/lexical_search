# -*- coding: utf-8 -*-

require_relative "helper"

module LexicalSearch
  # 構文の正規化
  #
  # ・文字列のスペースを区切りとして配列化
  # ・'"のどちらかで囲まれたフレーズは保護
  # ・値の羅列の間に省略されたANDを補完
  #
  # @example
  #
  #   Parser.parse("(a b)")        #=> ["(", "a", "AND", "b", ")"]
  #   Parser.new("(a b)").run      #=> ["(", "a", "AND", "b", ")"]
  #   Parser.new("(a b)").run.to_s #=> "(a AND b)"
  #
  class Parser
    include Helper

    attr_reader :elements

    # 簡単に配列化
    def self.parse(string)
      new(string).run.elements
    end

    def initialize(string)
      @string = string
      @elements = nil
    end

    def run
      return if @elements
      str = braket_space_around(@string)          # "(1 2 '3  4')" => " ( 1 2 '3  4' ) "
      elems = str.scan(/-?'[^']+'|-?"[^"]+"|\S+/) # "( 1 2 '3  4' )" => ["(", "1", "2", "'3  4'", ")"]
      @elements = insert_and_operator(elems)      # ["(", "1", "2", "'3  4'", ")"] => ["(", "1", "AND", "2", "AND", "'3  4'", ")"]
      self
    end

    # "(" ")" の左右には必ずスペースを入れる
    # エスケープしている場合は除く
    def braket_space_around(str)
      str.gsub(/(.)?([()])/){
        prefix, target = Regexp.last_match.captures
        if prefix == "\\"
          [prefix, target].join
        else
          [prefix, " ", target, " "].join
        end
      }
    end

    # 値と値の並びには AND が省略されているので入れる
    def insert_and_operator(elems)
      store = []
      elems.each_with_index{|elem, index|
        store << elem
        if next_elem = elems[index.next]
          if [
              [:t_value, :t_value], # a a
              [:t_value, :t_open],  # a (
              [:t_close, :t_value], # ) a
              [:t_close, :t_open],  # ) (
            ].include?([expr_type?(elem), expr_type?(next_elem)])
            store << "AND"
          end
        end
        }
      store
    end

    def to_s
      squish(@elements)
    end
  end
end
