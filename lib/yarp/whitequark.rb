# frozen_string_literal: true

module YARP
  class Whitequark < Visitor
    attr_reader :buffer

    def initialize(buffer)
      @buffer = buffer
    end

    def visit_alias_node(node)
      s(:alias, [visit(node.new_name), visit(node.old_name)])
    end

    def visit_and_node(node)
      s(:and, [visit(node.left), visit(node.right)])
    end

    def visit_float_node(node)
      s(:float, [range(node.location).to_f])
    end

    def visit_if_node(node)
      s(:if, [visit(node.predicate), visit(node.statements), visit(node.consequent)])
    end

    def visit_integer_node(node)
      s(:int, [range(node.location).to_i])
    end

    def visit_post_execution_node(node)
      s(:postexe, [visit(node.statements)])
    end

    def visit_pre_execution_node(node)
      s(:preexe, [visit(node.statements)])
    end

    def visit_program_node(node)
      visit(node.statements)
    end

    def visit_redo_node(node)
      s(:redo, [])
    end

    def visit_retry_node(node)
      s(:retry, [])
    end

    def visit_source_encoding_node(node)
      s(:const, [s(:const, [nil, :Encoding], nil), :UTF_8])
    end

    def visit_source_file_node(node)
      s(:str, [buffer.name])
    end

    def visit_statements_node(node)
      case node.body.length
      when 0
        # nothing
      when 1
        visit(node.body.first)
      else
        s(:begin, visit_all(node.body))
      end
    end

    def visit_unless_node(node)
      s(:if, [visit(node.predicate), visit(node.consequent), visit(node.statements)])
    end

    private

    def range(location)
      buffer.source[location.start_offset...location.end_offset]
    end

    def s(type, children, location = nil)
      ::Parser::AST::Node.new(type, children, location: location)
    end
  end
end
