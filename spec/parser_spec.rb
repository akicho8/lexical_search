# -*- coding: utf-8 -*-
require "spec_helper"

describe LexicalSearch::Parser do
  # 正規化
  #
  # ・スペース区切り
  # ・フレーズは保護
  # ・省略されたANDを補完
  #
  it "parser" do
    _parser %[1 2], %[1 AND 2]
    _parser %[(1 2)], %[(1 AND 2)]
    _parser %['1 2'], %['1 2']
    _parser %['1  2'], %['1  2']
    _parser %[(1 2 '3  4')], %[(1 AND 2 AND '3  4')]
    _parser %['1 2' '3 4'], %['1 2' AND '3 4']
    _parser '"1 2" "3 4"', %["1 2" AND "3 4"]
    _parser %[1 2 3], %[1 AND 2 AND 3]
    _parser %[1(2)3], %[1 AND (2) AND 3]
    _parser %[(1((2))3)], %[(1 AND ((2)) AND 3)]
    _parser %[(1(2)3)], %[(1 AND (2) AND 3)]
    _parser %[(1 AND (2) AND 3)], %[(1 AND (2) AND 3)]
  end

  def _parser(actual, expected)
    LexicalSearch::Parser.new(actual).run.to_s.should == expected
  end
end
