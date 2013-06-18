# -*- coding: utf-8 -*-

require_relative "helper"
require_relative "parser"

module LexicalSearch
  class Node
    include Helper

    def self.translate(string, options = {})
      options = {
        :order => :post,
        :squish => true,
      }.merge(options)
      object = build(Parser.parse(string), options.except(:braket))
      str = object.send("traverse_tree_#{options[:order]}order")
      if options[:squish]
        str = Helper.squish(str)
      end
      str
    end

    def self.build(expr, options = {})
      new(expr, options).tap{|object|object.build}
    end

    def initialize(source_expr, options = {})
      @source_expr = source_expr
      @options = {
        :braket => true,
      }.merge(options)
      @expr = @left = @right = nil
    end

    def braket_last_position
      last_position = nil
      stack = []
      @source_expr.each.with_index{|item, index|
        case item
        when "("
          stack.push(index) # スタックの必要はなかった
        when ")"
          stack.pop
          if stack.empty?
            last_position = index
            break
          end
        end
      }
      unless last_position
        raise SyntaxError, "#{@source_expr}"
      end
      last_position
    end

    # 全体がカッコで囲まれているか？
    def has_unnecessary_brakect?
      if @source_expr.first == "(" && @source_expr.last == ")"
        braket_last_position == (@source_expr.size - 1)
      end
    end

    def build
      # 最初と最後の括弧が対応している場合は繰り返し括弧を外す。
      # "( 1 AND 2 ) OR ( 3 AND 4 )" の場合などは対応してないので外してはいけない。
      while has_unnecessary_brakect?
        @source_expr = @source_expr[1..-2]
      end

      if @source_expr.size == 1
        if value?(@source_expr.first)
          @expr = @source_expr.first
          return
        else
          raise SyntaxError, "#{@source_expr}"
        end
      end

      @operations_order = ["OR", "AND"] # 優先度の低い順 + *。+ - のように同じ優先順位の場合ここに並べるのは間違い
      nest = 0
      found_index = nil
      most_low_priority = @operations_order.size
      @source_expr.each_with_index{|ch, index|
        case ch
        when "(" then nest += 1
        when ")" then nest -= 1
        end
        if nest >= 1
          next
        end
        if prio = @operations_order.index(ch.upcase)
          if prio < most_low_priority # <= だと後ろにあるものほど優先される
            most_low_priority = prio
            found_index = index
          end
        end
      }
      unless found_index
        raise SyntaxError, "#{@source_expr}"
      end
      build_chidren(@source_expr[found_index], @source_expr.take(found_index), @source_expr.drop(found_index.next))
    end

    def build_chidren(new_expr, left_expr, right_expr)
      @expr = new_expr
      @left = self.class.build(left_expr, @options)
      @right = self.class.build(right_expr, @options)
    end

    # 後行順序訪問 / 帰りがけ順 (postorder traversal)
    def traverse_tree_postorder
      list = []
      list << braket("(")
      if @left
        list += @left.send(__method__)
      end
      if @right
        list += @right.send(__method__)
      end
      list << @expr
      list << braket(")")
      list.compact
    end

    # 中間順序訪問 / 通りがけ順 (inorder traversal)
    def traverse_tree_inorder
      list = []
      list << braket("(")
      if @left
        list += @left.send(__method__)
      end
      list << @expr
      if @right
        list += @right.send(__method__)
      end
      list << braket(")")
      list.compact
    end

    # 先行順序訪問 / 行きがけ順 (preorder traversal)
    def traverse_tree_preorder
      list = []
      list << braket("(")
      list << @expr
      if @left
        list += @left.send(__method__)
      end
      if @right
        list += @right.send(__method__)
      end
      list << braket(")")
      list.compact
    end

    private

    def braket(str)
      if @left && @right && @options[:braket]
        str
      end
    end
  end
end
