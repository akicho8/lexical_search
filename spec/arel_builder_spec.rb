# -*- coding: utf-8 -*-
require "spec_helper"

require "active_record"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Schema.define do
  suppress_messages do
    create_table :articles do |t|
      t.string :name
      t.string :password
    end
  end
end

class Article < ActiveRecord::Base
  scope :quick_search, proc{|query|where(LexicalSearch::ArelBuilder.new(self, query, :only => :name).run)}
end

describe LexicalSearch::ArelBuilder  do
  after do
    Article.destroy_all
    LexicalSearch::ArelBuilder.adapter = LexicalSearch::Adapter::MySQL
  end

  it "クラスメソッドでのAND検索 - scope_and" do
    Article.quick_search("a b").to_sql.squish.should == %[SELECT "articles".* FROM "articles" WHERE ((("articles"."name" LIKE '%a%') AND ("articles"."name" LIKE '%b%')))].squish
  end

  it "クラスメソッドでの否定を含むAND検索 - scope_not" do
    Article.quick_search("a b -c -d").to_sql.squish.should == %[SELECT "articles".* FROM "articles" WHERE ((("articles"."name" LIKE '%a%') AND (("articles"."name" LIKE '%b%') AND ((("articles"."name" NOT LIKE '%c%' OR "articles"."name" IS NULL)) AND (("articles"."name" NOT LIKE '%d%' OR "articles"."name" IS NULL))))))]
  end

  it "DBに値を入れてみて実際正しくマッチするか？ - real_find" do
    Article.create!(:name => "abc  def")
    Article.quick_search("").should be_present
    Article.quick_search("x").should be_blank
    Article.quick_search("a").should be_present
    Article.quick_search("a x").should be_blank
    Article.quick_search("a OR x").should be_present
    Article.quick_search("a d").should be_present
    Article.quick_search("'c d'").should be_blank
    Article.quick_search("'c  d'").should be_present
  end

  it "エスケープにマッチするか？(Sqlite3) - escape_match" do
    Article.create!(:name => "%")
    LexicalSearch::ArelBuilder.adapter = LexicalSearch::Adapter::Sqlite3
    Article.quick_search("%").should be_present
  end

  it "TODO: Sqlite3の場合、% 自体にマッチさせるにはどうする？ escape_check" do
    Article.create!(:name => "x")
    LexicalSearch::ArelBuilder.adapter = LexicalSearch::Adapter::Sqlite3
    # % 自体にマッチしたいのに x にマッチしてしまっている
    Article.quick_search("%").should be_present
  end

  it "フレーズの場合、囲みを外しているか？ - wildify" do
    object = LexicalSearch::ArelNode.new("")
    object.wildify(%['a b']).should == "%a b%"
  end

  it "構文がおかしいと LexicalSearch::SyntaxError が来る - syntax_error" do
    proc{Article.quick_search("(")}.should raise_error(LexicalSearch::SyntaxError)
  end

  it "blank:構文で秘密のカラムにアクセスされたら例外が来る - forbidden_access" do
    proc{LexicalSearch::ArelBuilder.new(Article, "blank:password", :only => :name, :secure => true).run}.should raise_error(LexicalSearch::ForbiddenAccess)
  end

  it "デフォルトは秘密のカラムにアクセスし放題 - allow_all" do
    # TODO: minitest の assert_nothing_raised{} 相当は？
    LexicalSearch::ArelBuilder.new(Article, "blank:password", :only => :name).run.should be_present
  end

  it "入力要素の展開 - expand_filter" do
    LexicalSearch::ArelBuilder.new(Article, "c:x", :only => :name, :expand_filter => {/^c:/ => "name=="}).run.to_sql.should == %["articles"."name" = 'x']
  end
end
