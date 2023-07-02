# frozen_string_literal: true

module YARP
  # This represents a source of Ruby code that has been parsed. It is used in
  # conjunction with locations to allow them to resolve line numbers and source
  # ranges.
  class Source
    attr_reader :source, :offsets

    def initialize(source, offsets)
      @source = source
      @offsets = offsets
    end

    def slice(offset, length)
      source.byteslice(offset, length)
    end

    def line(value)
      offsets.bsearch_index { |offset| offset > value } || offsets.length
    end

    def column(value)
      value - offsets[line(value) - 1]
    end
  end

  # This represents a location in the source.
  class Location
    # A Source object that is used to determine more information from the given
    # offset and length.
    private attr_reader :source

    # The byte offset from the beginning of the source where this location
    # starts.
    attr_reader :start_offset

    # The length of this location in bytes.
    attr_reader :length

    def initialize(source, start_offset, length)
      @source = source
      @start_offset = start_offset
      @length = length
    end

    # The source code that this location represents.
    def slice
      source.slice(start_offset, length)
    end

    # The byte offset from the beginning of the source where this location ends.
    def end_offset
      start_offset + length
    end

    # The line number where this location starts.
    def start_line
      source.line(start_offset)
    end

    # The line number where this location ends.
    def end_line
      source.line(end_offset - 1)
    end

    # The column number in bytes where this location starts from the start of
    # the line.
    def start_column
      source.column(start_offset)
    end

    # The column number in bytes where this location ends from the start of the
    # line.
    def end_column
      source.column(end_offset - 1)
    end

    def deconstruct_keys(keys)
      { start_offset: start_offset, end_offset: end_offset }
    end

    def pretty_print(q)
      q.text("(#{start_offset}...#{end_offset})")
    end

    def ==(other)
      other in Location[start_offset: ^(start_offset), end_offset: ^(end_offset)]
    end

    def self.null
      new(0, 0)
    end
  end

  # This represents a comment that was encountered during parsing.
  class Comment
    attr_reader :type, :location

    def initialize(type, location)
      @type = type
      @location = location
    end

    def deconstruct_keys(keys)
      { type: type, location: location }
    end
  end

  # This represents an error that was encountered during parsing.
  class ParseError
    attr_reader :message, :location

    def initialize(message, location)
      @message = message
      @location = location
    end

    def deconstruct_keys(keys)
      { message: message, location: location }
    end
  end

  # This represents a warning that was encountered during parsing.
  class ParseWarning
    attr_reader :message, :location

    def initialize(message, location)
      @message = message
      @location = location
    end

    def deconstruct_keys(keys)
      { message: message, location: location }
    end
  end

  # This represents the result of a call to ::parse or ::parse_file. It contains
  # the AST, any comments that were encounters, and any errors that were
  # encountered.
  class ParseResult
    attr_reader :value, :comments, :errors, :warnings

    def initialize(value, comments, errors, warnings)
      @value = value
      @comments = comments
      @errors = errors
      @warnings = warnings
    end

    def deconstruct_keys(keys)
      { value: value, comments: comments, errors: errors, warnings: warnings }
    end

    def success?
      errors.empty?
    end

    def failure?
      !success?
    end
  end

  # This represents a token from the Ruby source.
  class Token
    attr_reader :type, :value, :location

    def initialize(type, value, location)
      @type = type
      @value = value
      @location = location
    end

    def deconstruct_keys(keys)
      { type: type, value: value, location: location }
    end

    def pretty_print(q)
      q.group do
        q.text(type.to_s)
        self.location.pretty_print(q)
        q.text("(")
        q.nest(2) do
          q.breakable("")
          q.pp(value)
        end
        q.breakable("")
        q.text(")")
      end
    end

    def ==(other)
      other in Token[type: ^(type), value: ^(value)]
    end
  end

  # This represents a node in the tree.
  class Node
    attr_reader :location

    def pretty_print(q)
      q.group do
        q.text(self.class.name.split("::").last)
        location.pretty_print(q)
        q.text("(")
        q.nest(2) do
          deconstructed = deconstruct_keys([])
          deconstructed.delete(:location)

          q.breakable("")
          q.seplist(deconstructed, lambda { q.comma_breakable }, :each_value) { |value| q.pp(value) }
        end
        q.breakable("")
        q.text(")")
      end
    end
  end

  # Load the serialized AST using the source as a reference into a tree.
  def self.load(source, serialized)
    Serialize.load(source, serialized)
  end
end

require_relative "yarp/lex_compat"
require_relative "yarp/node"
require_relative "yarp/ripper_compat"
require_relative "yarp/serialize"
require_relative "yarp/pack"

if RUBY_ENGINE == 'ruby' and false # TODO
  require "yarp.so"
else
  require "yarp.so" # TODO HACK until all methods implemented

  require "fiddle"
  require "fiddle/import"

  module YARP
    module LibRubyParser
      extend Fiddle::Importer

      POINTER_SIZE = sizeof("void*")

      Buffer = struct ['char *value', 'size_t length', 'size_t capacity']

      dlload File.expand_path("../build/librubyparser.so", __dir__)

      typealias 'bool', 'char' # OK? https://github.com/ruby/fiddle/issues/130

      typealias 'yp_unescape_type_t', 'int'
      YP_UNESCAPE_NONE = 0
      YP_UNESCAPE_MINIMAL = 1
      YP_UNESCAPE_ALL = 2

      def self.load_expored_functions_from(header, excludes = [])
        File.readlines(File.expand_path("../include/#{header}", __dir__)).each do |line|
          if line.start_with?('YP_EXPORTED_FUNCTION ')
            line = line.delete_prefix('YP_EXPORTED_FUNCTION ')
            unless excludes.any? { |exclude| exclude =~ line }
              extern line
            end
          end
        end
      end

      load_expored_functions_from("yarp.h", [/callback/, /yp_token_type_to_str/])
      load_expored_functions_from("yarp/util/yp_buffer.h")
      load_expored_functions_from("yarp/unescape.h")

      # extern "const char* yp_version(void)"
      # extern "void yp_parser_init(yp_parser_t *parser, const char *source, size_t size, const char *filepath)"
      # extern "void yp_parse_serialize(const char *source, size_t size, yp_buffer_t *buffer)"

      # extern "bool yp_buffer_init(yp_buffer_t *buffer)"
      # extern "void yp_buffer_free(yp_buffer_t *buffer)"

    end


    VERSION = LibRubyParser.yp_version.to_s

    def self.dump(code, filepath = nil)
      buffer = LibRubyParser::Buffer.malloc
      raise unless LibRubyParser.yp_buffer_init(buffer) == 1
      LibRubyParser.yp_parse_serialize(code, code.bytesize, buffer)
      buffer.value.to_s(buffer.length)
    end

    def self.dump_file(filepath)
      code = File.binread(filepath)
      dump(code, filepath)
    end

    def self.parse(code, filepath = nil)
      serialized = dump(code, filepath)
      node = load(code, serialized)
      ParseResult.new(node, [], [], [])
    end

    # def self.unescape(source, type)
    #
    # end
    # private_class_method :unescape
    #
    # def self.unescape_none(source)
    #   unescape(source, LibRubyParser::YP_UNESCAPE_MINIMAL)
    # end
  end
end
