# -*- coding: utf-8 -*-

require_relative "errors"
require_relative "adapter"
require_relative "arel_node"

require "active_record"
require "active_support/core_ext/class/attribute_accessors"
require "active_support/core_ext/string/filters"

module LexicalSearch
  # Facade
  class ArelBuilder
    cattr_accessor :adapter
    self.adapter = Adapter::MySQL

    cattr_accessor :ignore_column_names
    self.ignore_column_names = [:delete_status, :hide_status, :deleted_at]

    def initialize(scoped, query, options = {})
      @scoped = scoped
      @query = query
      @options = {
        :secure => false, # trueなら指定したカラム以外にアクセスできない(不特定の人が使う場合はtrueにする)
      }.merge(options)
    end

    def run
      return if @query.blank?
      elements = Parser.parse(@query)
      if @options[:expand_filter]
        elements = expand_filter(elements)
      end
      ArelNode.build(elements, {
          :scoped => @scoped,
          :target_columns => target_columns,
          :secure => @options[:secure],
          :adapter => adapter,
        }).to_where_scoped
    rescue SyntaxError => error
      if defined?(Rails) && Rails.logger
        Rails.logger.info("#{error.class.name}: #{error.message} @query=#{@query}")
      end
      raise error
    end

    private

    def target_columns
      if only = @options[:only]
        Array.wrap(only)
      elsif except = @options[:except]
        default_columns - Array.wrap(except)
      else
        default_columns
      end
    end

    def default_columns
      @scoped.columns.find_all{|column|column.text?}.collect(&:name).collect(&:to_sym) - ignore_column_names
    end

    # ショートカットの指定に沿って入力文字列を置換する
    #
    # @example
    #   @options[:expand_filter] = {
    #     /^c:/  => "category==", # OK
    #     /^&$/  => "AND",        # これはパース後なのでダメ
    #   }
    #
    #   "c:ゲーム" => "category==ゲーム"
    #
    def expand_filter(elements)
      elements.collect{|str|
        if found = @options[:expand_filter].find{|key, value|str.match(key)}
          str = str.gsub(*found)
        end
        str
      }
    end
  end
end
