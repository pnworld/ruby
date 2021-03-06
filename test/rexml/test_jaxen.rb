# frozen_string_literal: false
require_relative 'rexml_test_utils'

require "rexml/document"
require "rexml/xpath"

# Harness to test REXML's capabilities against the test suite from Jaxen
# ryan.a.cox@gmail.com

module REXMLTests
  class JaxenTester < Test::Unit::TestCase
    include REXMLTestUtils
    include REXML

    def test_axis ; process_test_case("axis") ; end
    def _test_basic ; process_test_case("basic") ; end
    def _test_basicupdate ; process_test_case("basicupdate") ; end
    def _test_contents ; process_test_case("contents") ; end
    def _test_defaultNamespace ; process_test_case("defaultNamespace") ; end
    def _test_fibo ; process_test_case("fibo") ; end
    def _test_id ; process_test_case("id") ; end
    def _test_jaxen24 ; process_test_case("jaxen24") ; end
    def _test_lang ; process_test_case("lang") ; end
    def _test_message ; process_test_case("message") ; end
    def _test_moreover ; process_test_case("moreover") ; end
    def _test_much_ado ; process_test_case("much_ado") ; end
    def _test_namespaces ; process_test_case("namespaces") ; end
    def _test_nitf ; process_test_case("nitf") ; end
    def _test_numbers ; process_test_case("numbers") ; end
    def _test_pi ; process_test_case("pi") ; end
    def _test_pi2 ; process_test_case("pi2") ; end
    def _test_simple ; process_test_case("simple") ; end
    def _test_testNamespaces ; process_test_case("testNamespaces") ; end
    def _test_text ; process_test_case("text") ; end
    def _test_underscore ; process_test_case("underscore") ; end
    def _test_web ; process_test_case("web") ; end
    def _test_web2 ; process_test_case("web2") ; end

    private
    def process_test_case(name)
      xml_path = "#{name}.xml"
      doc = File.open(fixture_path(xml_path)) do |file|
        Document.new(file)
      end
      test_doc = File.open(fixture_path("test/tests.xml")) do |file|
        Document.new(file)
      end
      XPath.each(test_doc,
                 "/tests/document[@url='xml/#{xml_path}']/context") do |context|
        process_context(doc, context)
      end
    end

    # processes a tests/document/context node
    def process_context(doc, context)
      test_context = XPath.match(doc, context.attributes["select"])
      namespaces = context.namespaces
      variables = {}
      var_namespace = "http://jaxen.org/test-harness/var"
      XPath.each(context,
                 "@*[namespace-uri() = '#{var_namespace}']") do |attribute|
        variables[attribute.name] = attribute.value
      end
      XPath.each(context, "valueOf") do |value|
        process_value_of(test_context, variables, namespaces, value)
      end
      XPath.each(context,
                 "test[not(@exception) or (@exception != 'true')]") do |test|
        process_nominal_test(test_context, variables, namespaces, test)
      end
      XPath.each(context,
                 "test[@exception = 'true']") do |test|
        process_exceptional_test(test_context, variables, namespaces, test)
      end
    end

    # processes a tests/document/context/valueOf or tests/document/context/test/valueOf node
    def process_value_of(context, variables, namespaces, value_of)
      expected = value_of.text
      matched = XPath.first(context,
                            value_of.attributes["select"],
                            namespaces,
                            variables)
      if expected.nil?
        assert_nil(matched)
      else
        case matched
        when Element
          assert_equal(expected, matched.name)
        when Attribute, Text, Comment, TrueClass, FalseClass
          assert_equal(expected, matched.to_s)
        when Instruction
          assert_equal(expected, matched.content)
        when Integer
          assert_equal(exected.to_f, matched)
        when String
          assert_equal(expected, matched)
        else
          flunk("Unexpected match value: <#{matched.inspect}>")
        end
      end
    end

    # processes a tests/document/context/test node ( where @exception is false or doesn't exist )
    def process_nominal_test(context, variables, namespaces, test)
      select = test.attributes["select"]
      matched = XPath.match(context, select, namespaces, variables)
      # might be a test with no count attribute, but nested valueOf elements
      expected = test.attributes["count"]
      if expected
        assert_equal(Integer(expected, 10),
                     matched.size)
      end

      XPath.each(test, "valueOf") do |value_of|
        process_value_of(mathched, variables, namespaces, value_of)
      end
    end

    # processes a tests/document/context/test node ( where @exception is true )
    def process_exceptional_test(context, variables, namespaces, test)
      select = test.attributes["select"]
      assert_raise do
        XPath.match(context, select, namespaces, variables)
      end
    end
  end
end
