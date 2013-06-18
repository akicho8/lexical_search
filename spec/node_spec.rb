# -*- coding: utf-8 -*-
require "spec_helper"

describe LexicalSearch::Node do
  it "中置記法に戻したとき正しい構文になっているか？" do
    assert_expr "1", "1"
    assert_expr "1", "(1)"
    assert_expr "1", "((1))"
    assert_expr "(1 AND 2)", "( 1 ) ( 2 )"
    assert_expr "(1 AND 2)", "1 2"
    assert_expr "(1 AND 2)", "(1 2)"
    assert_expr "(1 AND (2 AND 3))", "1 2 3"
    assert_expr "((1 AND 2) OR (3 AND 4))", "1 2 OR 3 4"
    assert_expr "(2 OR 4)", "(2 OR 4)"
    assert_expr "(2 AND 4)", "(2) 4"
    assert_expr "(1 AND ((2 OR 3) AND 4))", "1 (2 OR 3) 4"
    assert_expr "(1 AND 2)", "( 1 2 )"
    assert_expr "((1 AND 2) AND 3)", "( 1 2 ) 3"
    assert_expr "((1 AND 2) OR 3)", "( 1 AND 2 ) OR 3"
    assert_expr "((1 AND 2) OR (3 AND 4))", "( 1 AND 2 ) OR ( 3 AND 4 )"
  end

  def assert_expr(expected, string, order = :in)
    LexicalSearch::Node.translate(string, :braket => true, :order => order).should == expected
  end
end
