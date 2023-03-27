defmodule PasswordGenerator do
  @moduledoc """
  Generates random password depending on paramaters. Module main function is `generate(options)`.
  That functon takes the options map.
  Options example:
      options = %{
        "length" => "5",
        "numbers" => "false",
        "uppercase" => "false",
        "symbols" => "false"
      }
  The options are only 4, `length`, `numbers`, `uppercase`, `symbols`.
  When the function is invoked the first thing is:
  Defines a length variable that checks the map passed keys for the length.
  Then calls the private validate function passing in the previously defined length and the options.
  When false an error will be returned.
  When true checks if the string value of the `length` key contains an integer.
  Then calls the private function `validate_length_is_integer(length, options)`.
  When false an error is returned.
  When true:
  Defines a `length` variables that is trimmed and converted to integer.
  Defines an `options_without_length` variable to remove the length from map.
  Defines `options_value` that gets all the values from the previously defined `options_without_length`.
  Defines `value` variable which iterates over the values and converts them to atoms and check if boolean.
  If not all the values are booleans false is returned, true otherwise.
  Then the private function `validate_options_values_are_boolean(value, length, options_without_length)` is invoked.
  When false an error is returned.
  When true:
  Defines an options variable which calls the private function
  included_options(options) passing in the options
  that returns a list of atoms with the options that are truthy
  :lowercase_letter is prepended to that list as a default option.
  Then `included` is defined to get a list of the letters that are going to be included.
  For example if numbers and uppercase are true it returns the list ["a", "1", "B"].
  That is done by calling the private function `include` passing in the previously
  defined options iterating over those options and calling the private function
  `get` that gets the corresponding letter.
  If the options is invalid false will be returned and included in the list.
  Then length is defined to substract the length from the length of the previously defined included list.
  Then `random_strings` is defined to generate a list of random letters depending on the
  options, the length will be the previously defined length so that the string that we are going to return
  is going to be exact at the one passed when called.
  This is done by calling the private function `generate_strings(length, options).
  Then the 2 lists are concatenated, `included` and `random_strings` defined in the `strings` variable.
  Then `invalid_option?` is defined that iterate over the `strings` variable.
  When false is found true will be returned, false otherwise.
  Then the private function `validate_options(invalid_option?, strings)` is invoked.
  When true and error will be returned.
  When false the `strings` list will be shuffled and converted to string and `{:ok, string}` returned.
  """
  @symbols "!#$%&()*+,-./:;<=>?@[]^_{|}~"

  @doc """
  Generates password for given options.
  ## Examples
      options = %{
        "length" => "5",
        "numbers" => "false",
        "uppercase" => "false",
        "symbols" => "false"
      }
      iex> PasswordGenerator.generate(options)
      {:ok, "abcdf"}
      options = %{
        "length" => "5",
        "numbers" => "true",
        "uppercase" => "false",
        "symbols" => "false"
      }
      iex> PasswordGenerator.generate(options)
      {:ok, "ab1d3"}
  """
  @spec generate(options :: map()) :: {:ok, binary()} | {:error, binary()}
  def generate(options) do
    validate_length(options)
    |> validate_length_is_integer()
    |> validate_options_values_are_boolean()
    |> validate_options()
  end

  # Checks if the length options is included, returns the options or {:error, error}
  @spec validate_length(options :: map()) :: map() | {:error, binary()}
  defp validate_length(options) do
    has_length? = Map.has_key?(options, "length")
    error = "Please provide a length"

    get_error(has_length?, options, error)
  end

  # Validates that the lenght value is a number, returns the options or {:error, error}
  @spec validate_length_is_integer(options :: map() | {:error, binary()}) ::
          {:error, binary()} | map()
  defp validate_length_is_integer({:error, error}), do: {:error, error}

  defp validate_length_is_integer(options) do
    numbers = Enum.map(0..9, &Integer.to_string(&1))
    is_length_int? = String.contains?(options["length"], numbers)
    error = "Please provide a length"

    get_error(is_length_int?, options, error)
  end

  # Validates that the values of the options without the length
  # are booleans, returns the options or {:error, error}
  @spec validate_options_values_are_boolean(options :: map() | {:error, binary()}) ::
          map() | {:error, binary()}
  defp validate_options_values_are_boolean({:error, error}), do: {:error, error}

  defp validate_options_values_are_boolean(options) do
    options_without_length = Map.delete(options, "length")
    options_values = Map.values(options_without_length)
    # Iterate over the values and converts them to atoms and check if boolean
    # If not all the values are booleans false is returned, true otherwise.
    value = Enum.all?(options_values, &(&1 |> String.to_atom() |> is_boolean()))

    error = "Only booleans allowed for options values"

    get_error(value, options, error)
  end

  # Returns error when false
  @spec get_error(boolean(), map(), binary()) :: map() | {:error, binary()}
  defp get_error(true, options, _error), do: options

  defp get_error(false, _options, error), do: {:error, error}

  # Validates that all options are valid, returns error when an invalid option is found.
  @spec validate_options({:error, binary()} | map()) :: {:ok, binary()} | {:error, binary()}
  defp validate_options({:error, error}), do: {:error, error}

  defp validate_options(options) do
    length_to_integer = options["length"] |> String.trim() |> String.to_integer()
    options_without_length = Map.delete(options, "length")
    options = ["lowercase_letter" | included_options(options_without_length)]
    included = Enum.map(options, &get/1)
    length = length_to_integer - length(included)
    random_strings = generate_strings(length, options)
    strings = included ++ random_strings
    invalid_option? = false in strings

    case invalid_option? do
      true ->
        {:error, "Only options allowed numbers, uppercase, symbols."}

      false ->
        string =
          strings
          |> Enum.shuffle()
          |> to_string()

        {:ok, string}
    end
  end

  @spec generate_strings(length :: integer(), options :: list()) :: list()
  defp generate_strings(length, options) do
    Enum.map(1..length, fn _ -> options |> Enum.random() |> get() end)
  end

  # Letters can be represented by the binary value
  # example ?a = 97 and <<?a>> = "a"
  # Enum.random takes a range of integers
  # passing binary values you get all the letters of the alphabet
  # Returns a letter string for the given option, false when not a valid option
  @spec get(binary()) :: binary() | false
  defp get("lowercase_letter"), do: <<Enum.random(?a..?z)>>

  defp get("numbers"), do: Integer.to_string(Enum.random(0..9))

  defp get("uppercase"), do: <<Enum.random(?A..?Z)>>

  defp get("symbols"), do: @symbols |> String.split("", trim: true) |> Enum.random()

  defp get(_option), do: false

  # Returns a list of strings of included options
  @spec included_options(options :: map()) :: list()
  defp included_options(options) do
    # Returns a list of key value pairs when value is true
    # example %{"numbers" => "true, "uppercase" => "true"}]
    # then keys get mapped and converted to atoms
    # example [:numbers, :uppercase]
    Enum.reduce(options, [], fn {k, v}, acc ->
      if v |> String.trim() |> String.to_existing_atom(), do: [k | acc], else: acc
    end)
  end
end
