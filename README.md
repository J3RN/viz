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

You can also export the call-graph for only a "slice" of your program.  For instance, if you only want data on calls made in the course of the computation of `MyApp.foo/2`, you would write:

```
$ mix viz --source MyApp.foo/2
```

Multiple sources are supported and are "or"ed together.  That is, if you want data on calls made in the course of the computation of `MyApp.foo/2` and `MyApp.bar/1`, you would write:

```
$ mix viz --source MyApp.foo/2 --source MyApp.bar/1
```

Additionally, specifying "sinks" is also supported.  Specifying a sink is a way to determine what functions depend on another;  e.g. if you want data on functions that reference `MyApp.foo/2` and functions that references those functions, you would write:

```
$ mix viz --sink MyApp.foo/2
```

Multiple sinks are supported and can be combined with sources to find paths from one (or more) function to another (or several).

Export formats other than the CSV format are available.  They are:
- `dot`
- `dot_functions`
- `dot_modules`
- `json`

Alternative formats are specified with the `--format` flag, e.g.

```
$ mix viz --exporter dot
```

The first three use the [GraphViz DOT language](https://graphviz.org/doc/info/lang.html) to illustrate your call-graph.  Once you have created a `.dot` file, you can use a GraphViz tool (e.g. `dot`) to visualize the call-graph:

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
