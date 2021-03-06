defmodule Tds.Parameter do
  alias Tds.Types
  #alias Tds.Parameter
  alias Tds.DateTime
  alias Tds.DateTime2

  @type t :: %__MODULE__{
    name:       String.t | nil,
    direction:  Atom | :input
  }
  defstruct [name: "", direction: :input, value: "", type: nil]

  def option_flags(%__MODULE__{direction: direction, value: value}) do
    fByRefValue =
      case direction do
        :output -> 1
        _ -> 0
      end

    fDefaultValue =
      case value do
        :default -> 1
        _ -> 0
      end

    <<0::size(6), fDefaultValue::size(1), fByRefValue::size(1)>>
  end

  def prepared_params(nil) do
    []
  end
  def prepared_params(params) do
    params
    |> name(0)
    |> Enum.map(&fix_data_type/1)
    |> Enum.map(&Types.encode_param_descriptor/1)
    |> Enum.join(", ")
  end

  def name(params, name) do
    do_name(params, name, [])
  end

  def do_name([param | tail], name, acc) do
    param =
    case param do
      %Tds.Parameter{} -> param
      raw_param -> fix_data_type(raw_param, name+1)
    end

    do_name(tail, name, [param | acc])
  end

  def do_name([], _, acc) do
    acc
  end

  def fix_data_type(%Tds.Parameter{type: _type, value: _value} = param) do
    param
  end
  def fix_data_type(%Tds.Parameter{value: value} = param)
  when value == true or value == false do
    %{param | type: :boolean}
  end
  def fix_data_type(%Tds.Parameter{value: value} = param)
  when is_binary(value) and value == "" do
    %{param | type: :string}
  end
  def fix_data_type(%Tds.Parameter{value: value} = param)
  when is_binary(value) do
    %{param | type: :binary}
  end
  def fix_data_type(%Tds.Parameter{value: value} = param)
  when is_integer(value) and value >= 0 do
    %{param | type: :integer}
  end
  def fix_data_type(%Tds.Parameter{value: value} = param)
  when is_float(value) do
    %{param | type: :float}
  end
  def fix_data_type(%Tds.Parameter{value: value} = param)
  when (is_integer(value) and value < 0) do
    %{param | value: Decimal.new(value), type: :decimal}
  end
  def fix_data_type(%Tds.Parameter{value: {{_,_,_}}} = param) do
    %{param | type: :date}
  end
  def fix_data_type(%Tds.Parameter{value: {{_,_,_,_}}} = param) do
    %{param | type: :time}
  end
  def fix_data_type(%Tds.Parameter{value: %Decimal{}} = param) do
    %{param | type: :decimal}
  end
  def fix_data_type(%Tds.Parameter{value: %DateTime{}} = param) do
    %{param | type: :datetime}
  end
  def fix_data_type(%Tds.Parameter{value: %DateTime2{}} = param) do
    %{param | type: :datetime2}
  end
  def fix_data_type(%Tds.Parameter{value: {{_,_,_},{_,_,_}}} = param) do
    %{param | type: :datetime}
  end
  def fix_data_type(%Tds.Parameter{value: {{_,_,_},{_,_,_,_}}} = param) do
    %{param | type: :datetime2}
  end
  def fix_data_type(%Tds.Parameter{value: {{_,_,_},{_,_,_,_},_}} = param) do
    %{param | type: :datetimeoffset}
  end
  def fix_data_type(%Tds.Parameter{value: {{_,_,_},{_,_,_,},_}} = param) do
    %{param | type: :datetimeoffset}
  end
  def fix_data_type(raw_param, acc) do
    param = %Tds.Parameter{name: "@#{acc}", value: raw_param}
    fix_data_type(param)
  end
end
