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
    create_table :other_articles do |t|
    end
    create_table :users do |t|
    end
  end
end

class Article < ActiveRecord::Base
end

class OtherArticle < ActiveRecord::Base
end

describe LexicalSearch::ArelNode do
  it "main" do
    assert_sql %[("articles"."name" LIKE '%a%')], "a"
  end

  # % はエスケープされている
  it "sql_escape" do
    assert_sql %[("articles"."name" LIKE '%\\%%')], "%"
  end

  # NOT LIKE の場合、NULL のカラムは NOT NULL の対象にならないため、驚きをなくすには IS NULL のチェックも必要
  it "sql_not_like" do
    assert_sql %[("articles"."name" NOT LIKE '%1%' OR "articles"."name" IS NULL)], "-1"
  end

  # いろいろ正しい
  it "sql_general" do
    assert_sql %[("articles"."name" LIKE '%1%')], "1"
    assert_sql %[("articles"."name" LIKE '%1  2%')], "'1  2'"
    assert_sql %[(("articles"."name" LIKE '%1%') AND ("articles"."name" LIKE '%2%'))], "1 2"
    assert_sql %[(("articles"."name" LIKE '%1%') OR ("articles"."name" LIKE '%2%'))], "1 OR 2"
    assert_sql %[((("articles"."name" LIKE '%1%') AND ("articles"."name" LIKE '%2%')) OR (("articles"."name" LIKE '%3%') AND ("articles"."name" LIKE '%4%')))], "1 2 OR 3 4"
    assert_sql %[(("articles"."name" LIKE '%1%') AND ((("articles"."name" LIKE '%2%') OR ("articles"."name" LIKE '%3%')) AND ("articles"."name" LIKE '%4%')))], "1 (2 OR 3) 4"

    assert_sql %[(("articles"."name" LIKE '%攻略%') AND ((("articles"."name" LIKE '%モンハン%') OR ("articles"."name" LIKE '%MHP%')) AND (("articles"."name" LIKE '%Wiki%') AND ("articles"."name" NOT LIKE '%ブログ%' OR "articles"."name" IS NULL))))], "攻略 (モンハン OR MHP) Wiki -ブログ"
  end

  # 「指定のカラムが空」の指定ができる
  it "column_blank" do
    assert_sql %[("articles"."name" = '' OR "articles"."name" IS NULL)], "blank:name"
    assert_sql %[(("articles"."name" = '' OR "articles"."name" IS NULL) AND ("articles"."name" LIKE '%a%'))], "blank:name a"
  end

  # 「指定のカラムに値が存在する」の指定ができる
  it "column_present" do
    assert_sql %[("articles"."name" != '' AND "articles"."name" IS NOT NULL)], "present:name"
  end

  it "operator" do
    assert_sql %["articles"."name" = 'a'], "name==a"
    assert_sql %["articles"."name" != 'a' AND "articles"."name" IS NOT NULL], "name!=a"
    assert_sql %["articles"."name" LIKE '%a%'], "name=@a"
    assert_sql %["articles"."name" NOT LIKE '%a%' AND "articles"."name" IS NOT NULL], "name!@a"
    assert_sql %["articles"."name" > 'a'], "name>a"
    assert_sql %["articles"."name" >= 'a'], "name>=a"
    assert_sql %["articles"."name" < 'a'], "name<a"
    assert_sql %["articles"."name" <= 'a'], "name<=a"
  end

  context "joins対応" do
    it "他のテーブルを指定できるのであらかじめjoinsしておけば他のテーブルを参照できる" do
      assert_sql %["other_articles"."name" = 'a'], "other_articles.name==a"
      assert_sql %[("other_articles"."name" != '' AND "other_articles"."name" IS NOT NULL)], "present:other_articles.name"
    end

    it "ただし他のテーブルがない場合はエラーになるので注意" do
      proc {
        assert_sql %["foo"."name" = 'a'], "foos.name==a"
      }.should raise_error(LexicalSearch::JoinTableNotFound)
    end
  end

  private

  def assert_sql(expected_sql, query, options = {})
    object = LexicalSearch::ArelNode.build(LexicalSearch::Parser.parse(query), options.merge(:scoped => Article, :target_columns => [:name], :secure => false, :adapter => LexicalSearch::Adapter::MySQL))
    expected_sql = expected_sql.gsub(/\s*\n\s*/m, " ")
    object.to_where_scoped.to_sql.should == expected_sql
  end
end
