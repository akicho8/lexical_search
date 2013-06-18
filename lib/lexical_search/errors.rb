# -*- coding: utf-8 -*-

module LexicalSearch
  class LexicalSearchError < StandardError; end
  class SyntaxError < LexicalSearchError; end
  class ForbiddenAccess < LexicalSearchError; end
  class JoinTableNotFound < LexicalSearchError; end
end
