# Margin Notes

![Screenshot of the Margin Notes UI](screenshots/margin-notes-screenshot.png)

Programmers working on large codebases frequently need to understand APIs for existing code. Manual documentation is helpful, but takes time to maintain and often doesn’t include enough examples.

Margin Notes automatically generates code documentation by recording example data from function calls as a program executes and displaying those examples in an interactive UI next to the code. This allows programmers to quickly view many examples from past executions as they read the code, helping them efficiently gain insight into the behavior of the program.

This repo contains the code for the Ruby example data recorder.

It uses the Ruby TracePoint API to record example function calls and
serialize the result to JSON. The JSON data can then be viewed in
the [interactive web viewer](https://github.com/geoffreylitt/margin-notes-ui).

[Read the full interactive essay](https://geoffreylitt.com/margin-notes/)

## Using the gem

Point another Ruby program at the local version of this gem. In the Gemfile:

```ruby
gem 'example_recorder', path: 'path/to/example_recorder'
```

Then to instrument your code:

```ruby
# It will only record code where the filename includes the given path;
# use this to exclude library/framework code
recorder = ExampleRecorder.new(path: "my-code/")

recorder.record do
  # your code goes here!
end

# Now you can print out the JSON for the examples, write out to file, etc
puts recorder.serialized_examples
```

## Development

Just edit the files in this gem directory;
if you've set up the gemfile for your Ruby code to point to this directory,
it will use the latest version of the files.
