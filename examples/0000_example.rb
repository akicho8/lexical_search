# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "lexical_search"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name
  end
end

class User < ActiveRecord::Base
  scope :search, proc{|q|where(LexicalSearch::ArelBuilder.new(self, q).run)}
end

User.create!([{:name => "alice"}, {:name => "bob"}, {:name => "carol"}])
User.search("a").collect(&:name)    # => ["alice", "carol"]
User.search("a -o").collect(&:name) # => ["alice"]
