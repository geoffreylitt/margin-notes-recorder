require "example_recorder/version"
require 'json'
require 'set'

# EXAMPLE ANNOTATIONS

# Problem definition:

# We have places in our complex codebase where we
# document example input/output and it's much more useful than just type annotation
#
# But it's a pain to write and maintain...
# What if we could just have that automatically?

# Outline of the approach:

# when function is called, record input params in an in-progress zone
# when function returns, lookup corresponding input and record return vals
# serialize the examples to json (handle separately from recording for separation)
# make an editor that can visualize the examples inline with the code

# todos to consider:
# conserve space: if we've already recorded >N examples for given type signature,
#   don't save this one
# use abstract method defs rather than line numbers to make examples last longer

# Examples data structure looks like this:
#
# examples = [
#   {
#     class_name: "Object",
#     method_name: "double",
#     arguments: { x: { klass: "Integer", value: 2 } },
#     return: { klass: "Integer", value: 32 },
#     callstack: ["example.rb:17:in `block in <main>'", "example.rb:40:in `double'", "example.rb:48:in `<main>'"]
#   }
# ]

module ExampleRecorder
  class Recorder
    def initialize(path:)
      @examples = []
      # functions where we've done the call but haven't returned yet
      @in_progress_examples = {}

      @path = path

      @trace = trace

      # a Set to help keep track of which
      # method/input/output examples we've seen
      # to avoid duplicating the same example
      @seen_examples_set = Set.new
    end

    def record
      @trace.enable
      yield
      @trace.disable
    end

    def start!
      @trace.enable 
    end

    def stop!
      @trace.disable
    end

    def serialized_examples(limit: 100)
      array = @examples.first(limit).map { |example| serialize_example(example) }
      JSON.dump(array)
    end

    private

    attr_accessor :path

    def trace
      TracePoint.new(:call, :return) do |tp|
        begin
          next unless tp.path.include?(path)

          method_obj = tp.self.method(tp.method_id)
          params_with_values = method_obj.parameters.map do |(_, name)|
            [name, tp.binding.local_variable_get(name)]
          end.to_h

          # attrs_to_print = [params_with_values, tp.lineno, tp.defined_class, tp.method_id, tp.event, caller(0)]
          # attrs_to_print << tp.return_value if tp.event == :return

          key = [tp.defined_class, tp.method_id, caller(0).size]

          if tp.event == :call
            @in_progress_examples[key] = {
              klass: tp.defined_class,
              method: method_obj,
              parameters: method_obj.parameters,
              arguments: params_with_values,

              # Previously was including callstack here but too noisy.
              # maybe add back later
              # callstack: caller(0)
            }
          elsif tp.event == :return
            in_progress_example = @in_progress_examples[key]

            unless in_progress_example.nil?
              in_progress_example[:return_value] = {
                class_name: tp.return_value.class.name,
                value: tp.return_value
              }

              unique_example_key = in_progress_example.slice(:method, :arguments, :return_value)
              next if @seen_examples_set.include?(unique_example_key)

              @seen_examples_set << unique_example_key
              @examples << in_progress_example
              @in_progress_examples.delete(key)
            end
          end
        rescue NameError
        end
      end
    end

    # todo: dont mutate here, copy
    def serialize_example(example)
      example = example.
        merge(class_name: example[:klass].name).
        merge(method_name: example[:method].name).
        merge(method_location: example[:method].source_location)

      example[:arguments] = example[:arguments].map do |name, value|
        [
          name,
          {
            class_name: value.class.name,
            value: value
          }
        ]
      end.to_h

      example
    end
  end
end