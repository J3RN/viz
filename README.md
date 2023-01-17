# Viz

Vizualise your Elixir codebase (kinda).

## Usage

```
$ mix viz
```

This will create an out.csv file containing a call-graph of your application for analysis or importing into another tool.  It has two columns—`source` and `target`—and each row in the CSV represents a call from the `source` function to the `target` function.

You may specify a different filename with the `--filename` flag, e.g.

```
$ mix viz --filename myapp.csv
```

Formats other than the CSV format are available.  They are:
- `dot`
- `dot_functions`
- `dot_modules`
- `json`

Alternative formats are specified with the `--format` flag, e.g.

```
$ mix viz --exporter dot
```

The first three use the [GraphViz DOT language](https://graphviz.org/doc/info/lang.html) to illustrate your call-graph.  Once you have created a `.dot` file, you can use a GraphViz tool, e.g. `dot` to visualize the call-graph:

```
$ dot out.dot -Tsvg -o out.svg
```

This command creates an `out.svg` file which you can view in your browser.

`dot` tries to create a heirarchy of nodes.  If this view is unhelpful to you, try `fdp` which uses force-directed placement to lay out nodes in a cluster.

## Installation

```elixir
def deps do
  [
    {:viz, git: "git@github.com:J3RN/viz.git", only: [:dev, :test], runtime: false}
  ]
end
```

I hope to one day make this an escript so you don't have to add it to your project, but I've yet to figure that out.
