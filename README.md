# Viz

Vizualise your Elixir codebase.

## Usage

```
$ mix viz
```

This will create an out.dot file which can then be converted into an image via GraphViz, e.g.

```
$ dot out.dot -Tsvg -o out.svg
```

## Installation

```elixir
def deps do
  [
    {:viz, "~> 0.1.0"}
  ]
end
```
