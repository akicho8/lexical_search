require "spec_helper"

describe LexicalSearch::Adapter do
  it { LexicalSearch::Adapter::MySQL.escaped_query("%").should == "\\%" }
  it { LexicalSearch::Adapter::Sqlite3.escaped_query("%").should == "%" }
end
