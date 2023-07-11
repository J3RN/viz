defmodule Viz.Analyzer.Beams do
  @behaviour Viz.Analyzer

  @spec analyze() :: Viz.calls()
  def analyze() do
    if Mix.Project.umbrella?(),
      do: Mix.raise("I'm really sorry, but umbrellas aren't supported just yet")

    Mix.Task.run("compile")

    Mix.Project.get!().project()
    |> Keyword.fetch!(:app)
    |> Application.spec(:modules)
    |> Enum.map(&:code.which/1)
    |> Enum.flat_map(&calls_in_file/1)
  end

  # Most of this file handle forms of the Erlang Abstract Format[1], and is
  # divided into sections based on the layout of the documentation.
  #
  # [1]: https://www.erlang.org/doc/apps/erts/absform.html

  # 8.1: Module Declarations and Forms

  @spec calls_in_file(charlist()) :: Viz.calls()
  def calls_in_file(beam_file) do
    {:ok, {module, [abstract_code: {:raw_abstract_v1, abstract_code}]}} =
      :beam_lib.chunks(beam_file, [:abstract_code])

    abstract_code
    |> Enum.flat_map(fn
      {:function, _anno, fun_name, arity, clauses} ->
        caller = {module, fun_name, arity}
        Enum.flat_map(clauses, &calls_in_ast(caller, &1))

      # We're ignoring attributes.  _Technically_ record definitions (a kind of
      # attribute) can contain function references, but we don't have a way to
      # represent this.
      {:attribute, _anno, _, _} ->
        []
    end)
    |> Enum.map(fn {{mod1, fun1, arity1}, {mod2, fun2, arity2}} ->
      {{clean_name(mod1), fun1, arity1}, {clean_name(mod2), fun2, arity2}}
    end)
  end

  defp clean_name(module) when is_atom(module) do
    module
    |> to_string()
    |> String.trim_leading("Elixir.")
  end

  # Per above, record fields will never be recurred on, and so are not included.

  @spec calls_in_ast(mfa(), term()) :: [{mfa(), mfa()}]

  # 8.2: Atomic Literals

  defp calls_in_ast(_caller, {:atom, _anno, _atom}), do: []
  defp calls_in_ast(_caller, {:char, _anno, _char}), do: []
  defp calls_in_ast(_caller, {:float, _anno, _float}), do: []
  defp calls_in_ast(_caller, {:integer, _anno, _val}), do: []
  defp calls_in_ast(_caller, {:string, _anno, _str}), do: []

  # 8.3: Patterns
  # Patterns can't have function calls in them, so they're ignored

  # 8.4: Expressions

  defp calls_in_ast(caller, {:bc, _anno, _product, qualifiers}) do
    Enum.flat_map(qualifiers, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(caller, {:bin, _anno, els}) do
    Enum.flat_map(els, fn {:bin_element, _anno, el, _size, _type_specifier_list} ->
      calls_in_ast(caller, el)
    end)
  end

  defp calls_in_ast(caller, {:block, _anno, expr}) do
    calls_in_ast(caller, expr)
  end

  defp calls_in_ast(caller, {:case, _anno, of, clauses}) do
    calls_in_ast(caller, of) ++ Enum.flat_map(clauses, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(caller, {:catch, _anno, expr}) do
    calls_in_ast(caller, expr)
  end

  defp calls_in_ast(caller, {:cons, _anno, head, tail}) do
    calls_in_ast(caller, head) ++ calls_in_ast(caller, tail)
  end

  defp calls_in_ast({module, _, _} = caller, {:fun, _anno, {:function, name, arity}}) do
    [{caller, {module, name, arity}}]
  end

  defp calls_in_ast(
         caller,
         {:fun, _anno,
          {:function, {:atom, _anno2, module}, {:atom, _anno3, name}, {:integer, _anno4, arity}}}
       ) do
    [{caller, {module, name, arity}}]
  end

  defp calls_in_ast(caller, {:fun, _anno, {:clauses, clauses}}) do
    Enum.flat_map(clauses, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(caller, {:named_fun, _anno, _name, clauses}) do
    Enum.flat_map(clauses, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(caller, {:call, _anno, callee, args}) do
    arg_calls = Enum.flat_map(args, &calls_in_ast(caller, &1))

    case normalize_callee(caller, callee, length(args)) do
      {:ok, callee} -> [{caller, callee} | arg_calls]
      :error -> calls_in_ast(caller, callee) ++ arg_calls
    end
  end

  defp calls_in_ast(caller, {:if, _anno, clauses}) do
    Enum.flat_map(clauses, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(caller, {:lc, _anno, _product, qualifiers}) do
    Enum.flat_map(qualifiers, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(caller, {:mc, _anno, _product, qualifiers}) do
    Enum.flat_map(qualifiers, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(caller, {:map, _anno, pairs}) do
    Enum.flat_map(pairs, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(caller, {:map, _anno, map, pairs}) do
    calls_in_ast(caller, map) ++ Enum.flat_map(pairs, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(caller, {:match, _anno, _pattern, expr}) do
    calls_in_ast(caller, expr)
  end

  defp calls_in_ast(caller, {:maybe_match, _anno, _pattern, expr}) do
    calls_in_ast(caller, expr)
  end

  defp calls_in_ast(caller, {:maybe, _anno, body}) do
    calls_in_ast(caller, body)
  end

  defp calls_in_ast(caller, {:maybe, _anno, body, {:else, _anno2, clauses}}) do
    calls_in_ast(caller, body) ++ Enum.map(clauses, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(_caller, {nil, _anno}), do: []

  defp calls_in_ast(caller, {:op, _anno, _op, left, right}) do
    calls_in_ast(caller, left) ++ calls_in_ast(caller, right)
  end

  defp calls_in_ast(caller, {:op, _anno, _op, body}) do
    calls_in_ast(caller, body)
  end

  defp calls_in_ast(caller, {:receive, _anno, clauses}) do
    Enum.flat_map(clauses, &calls_in_ast(caller, &1))
  end

  defp calls_in_ast(caller, {:receive, _anno, clauses, timeout, body}) do
    Enum.flat_map(clauses, &calls_in_ast(caller, &1)) ++
      calls_in_ast(caller, timeout) ++
      calls_in_ast(caller, body)
  end

  defp calls_in_ast(caller, {:record, _anno, _name, fields}) do
    Enum.flat_map(fields, fn {:record_field, _anno, _field_name, field_value} ->
      calls_in_ast(caller, field_value)
    end)
  end

  defp calls_in_ast(caller, {:record_field, _anno, record, _record_name, _field}) do
    calls_in_ast(caller, record)
  end

  defp calls_in_ast(_caller, {:record_index, _anno, _record_name, _field}), do: []

  defp calls_in_ast(caller, {:record, _anno, record, _record_name, fields}) do
    calls_in_ast(caller, record) ++
      Enum.flat_map(fields, fn {:record_field, _anno, _field_name, field_value} ->
        calls_in_ast(caller, field_value)
      end)
  end

  defp calls_in_ast(caller, {:tuple, _anno, els}) do
    Enum.flat_map(els, &calls_in_ast(caller, &1))
  end

  # Try occupies six bullet points in the docs, but I think it's form is
  # designed to be handled by a single function.
  defp calls_in_ast(caller, {:try, _anno, exprs, ofs, catch_clauses, after_}) do
    Enum.flat_map(exprs, &calls_in_ast(caller, &1)) ++
      Enum.flat_map(ofs, &calls_in_ast(caller, &1)) ++
      Enum.flat_map(catch_clauses, &calls_in_ast(caller, &1)) ++
      calls_in_ast(caller, after_)
  end

  defp calls_in_ast(_caller, {:var, _anno, _name}), do: []

  ## Qualifiers

  defp calls_in_ast(caller, {:generate, _anno, _pattern, expr}) do
    calls_in_ast(caller, expr)
  end

  defp calls_in_ast(caller, {:b_generate, _anno, _pattern, expr}) do
    calls_in_ast(caller, expr)
  end

  defp calls_in_ast(caller, {:m_generate, _anno, _pattern, expr}) do
    calls_in_ast(caller, expr)
  end

  ## Bitstring Element Type Specifiers
  # These don't contain function calls or references, so they're omitted

  ## Associations
  defp calls_in_ast(caller, {:map_field_assoc, _anno, _key, value}) do
    calls_in_ast(caller, value)
  end

  defp calls_in_ast(caller, {:map_field_exact, _anno, _key, value}) do
    calls_in_ast(caller, value)
  end

  # 8.5: Clauses

  defp calls_in_ast(caller, {:clause, _anno, _pattern, guard_sequences, body}) do
    guard_calls =
      for guard_sequence <- guard_sequences, guard <- guard_sequence do
        calls_in_ast(caller, guard)
      end
      |> List.flatten()

    body_calls = Enum.flat_map(body, &calls_in_ast(caller, &1))

    guard_calls ++ body_calls
  end

  # 8.6: Guards
  # Interestingly, I think all guards are handled by the above clauses.

  # 8.7: Types
  # Types cannot contain function references, and furthermore are never recurred
  # on, so do not need to be handled.

  # Catch-all.  Theoretically all the above clauses should catch everything that
  # the BEAM can include _today_, but this clause provides future-proofing.
  defp calls_in_ast(_caller, _unknown_ast), do: []

  @spec normalize_callee(
          caller :: mfa,
          callee :: tuple(),
          arity :: non_neg_integer()
        ) :: {:ok, mfa} | :error
  defp normalize_callee(
         {module, _, _},
         {:atom, _anno, fun_name},
         arity
       )
       when is_atom(module) and is_atom(fun_name) and is_integer(arity) do
    {:ok, {module, fun_name, arity}}
  end

  defp normalize_callee(
         _caller,
         {:remote, _anno, {:atom, _anno2, module}, {:atom, _anno3, fun_name}},
         arity
       )
       when is_atom(module) and is_atom(fun_name) and is_integer(arity) do
    {:ok, {module, fun_name, arity}}
  end

  defp normalize_callee(
         caller,
         {:var, _anno, _var_name},
         _arity
       ) do
    IO.puts("Unable to derive calls from variable invoked as function in #{debug_caller(caller)}")

    :error
  end

  defp normalize_callee(
         _caller,
         _callee,
         _arity
       ) do
    :error
  end

  defp debug_caller({mod, fun, arity}) when is_atom(mod) and is_atom(fun) and is_integer(arity) do
    Viz.Exporter.Utils.hash({clean_name(mod), fun, arity})
  end

  defp debug_caller(caller) do
    inspect(caller)
  end
end
