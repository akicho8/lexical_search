# -*- coding: utf-8 -*-

require_relative "node"
require_relative "errors"

module LexicalSearch
  class ArelNode < Node
    OperatorTable = {
      "==" => {:arel_method => :eq,             :wildify => false, :with_not_null => false},
      "!=" => {:arel_method => :not_eq,         :wildify => false, :with_not_null => true},
      "=@" => {:arel_method => :matches,        :wildify => true,  :with_not_null => false},
      "!@" => {:arel_method => :does_not_match, :wildify => true,  :with_not_null => true},
      ">"  => {:arel_method => :gt,             :wildify => false, :with_not_null => false},
      ">=" => {:arel_method => :gteq,           :wildify => false, :with_not_null => false},
      "<"  => {:arel_method => :lt,             :wildify => false, :with_not_null => false},
      "<=" => {:arel_method => :lteq,           :wildify => false, :with_not_null => false},
    }

    #
    # 中置記法の要領で、Arelでの条件を作っていく
    #
    def to_where_scoped
      if @left && @right
        case @expr.downcase
        when "and"
          Arel::Nodes::Grouping.new(Arel::Nodes::And.new([@left.send(__method__), @right.send(__method__)]))
        when "or"
          Arel::Nodes::Grouping.new(Arel::Nodes::Or.new(@left.send(__method__), @right.send(__method__)))
        else
          raise SyntaxError, @expr
        end
      else
        union_regexp = Regexp.union(*OperatorTable.keys.sort_by{|key|-key.size}.collect{|str|Regexp.escape(str)})
        case
        when md = @expr.match(/\A(blank|present):(?:(\w+)\.)?(\w+)/)
          method, table, column_name = md.captures
          assert_valid_access(column_name)
          send("_process_#{method}", table, column_name)
        when md = @expr.match(/\A(?:(\w+)\.)?(\w+)(#{union_regexp})(.*)/)
          table, column_name, operator, value = md.captures
          assert_valid_access(column_name)
          info = OperatorTable[operator]
          value = phrase_content(value)
          wheres = nil
          if info[:wildify]
            value = wildify(value)
          end
          wheres = column_at(table, column_name).send(info[:arel_method], value)
          if info[:with_not_null]
            wheres = wheres.and(column_at(table, column_name).not_eq(nil))
          end
          wheres
        when md = @expr.match(/\A-(.*)/)
          does_not_match_all(md.captures.first)
        else
          matches_any
        end
      end
    end

    #
    # 特定のカラムにアクセスしようとしているときダメなら例外
    #
    def assert_valid_access(column_name)
      if @options[:secure] && !@options[:target_columns].include?(column_name.to_sym)
        raise ForbiddenAccess, @expr
      end
    end

    #
    # 「カラムのどれかに含まれていればよい」のでOR条件の連結
    #
    def matches_any
      Arel::Nodes::Grouping.new @options[:target_columns].inject(nil){|memo, target_key|
        match = column_at(nil, target_key).matches(wildify(@expr))
        next match unless memo
        memo.or(match)
      }
    end

    #
    # 「カラムのすべてに含まれてない」のでAND条件の連結
    #
    def does_not_match_all(match_str)
      Arel::Nodes::Grouping.new @options[:target_columns].inject(nil){|memo, target_key|
        match = column_at(nil, target_key).does_not_match(wildify(match_str)).or(column_at(nil, target_key).eq(nil))
        next match unless memo
        memo.and(match)
      }
    end

    #
    # "" または NULL
    #
    def _process_blank(table, column_name)
      # ORの場合は安全のためか、最後に全体が囲まれるので自分で囲まなくていい
      column_at(table, column_name).eq("").or(column_at(table, column_name).eq(nil))
    end

    #
    # "" でも NULL でもない
    #
    def _process_present(table, column_name)
      # ANDの場合自分で囲まないと他とまざってしまう
      Arel::Nodes::Grouping.new column_at(table, column_name).not_eq("").and(column_at(table, column_name).not_eq(nil))
    end

    # マッチする文字列がフレーズなら囲みを外して部分一致用の文字列を返す
    #
    # @example
    #   wildify("a")     #=> "%a%"
    #   wildify("'a b'") #=> "%a b%"
    #
    def wildify(str)
      str = phrase_content(str)
      if @options[:adapter]
        str = @options[:adapter].escaped_query(str)
      end
      "%#{str}%"
    end

    # フレーズの中身を返す
    #
    # @example
    #   phrase_content("a")     #=> "a"
    #   phrase_content("'a b'") #=> "a b"
    #
    def phrase_content(str)
      if md = str.match(/\A(["'])(.*)\1\z/)
        _, str = *md.captures
      end
      str
    end

    # 指定のカラムの構造体を返す
    #
    #   column_at(table, :name) #=> #<struct Arel::Attributes::String relation=#<Arel::Table:0x1035194e8 @columns=[...]
    #
    def column_at(table, name)
      if table
        begin
          klass = table.classify.constantize
        rescue => error
          raise JoinTableNotFound, "#{table}"
        end
        klass.arel_table[name.to_sym]
      else
        @options[:scoped].arel_table[name.to_sym]
      end
    end
  end
end
