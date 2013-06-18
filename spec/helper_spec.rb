require "spec_helper"

describe LexicalSearch::Helper do
  it {LexicalSearch::Helper.expr_type?("(").should == :t_open}
  it {LexicalSearch::Helper.squish("( 1 AND 2 )").should == "(1 AND 2)"}
end
