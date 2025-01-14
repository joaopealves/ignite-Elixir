defmodule GenReport do
  alias GenReport.{Parser, GetHours}

  @names [
    "daniele",
    "mayk",
    "giuliano",
    "cleiton",
    "jakeliny",
    "joseph",
    "diego",
    "rafael",
    "vinicius",
    "danilo"
  ]

  @months [
    "janeiro",
    "fevereiro",
    "março",
    "abril",
    "maio",
    "junho",
    "julho",
    "agosto",
    "setembro",
    "outubro",
    "novembro",
    "dezembro"
  ]

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(hours_acc(), fn row, acc ->
      GetHours.call(row, acc)
    end)
  end

  def build_from_many(filename) when not is_list(filename),
    do: {:error, "Insira o nome do arquivo dentro de uma lista"}

  def build_from_many(filename) do
    filename
    |> Task.async_stream(&build/1)
    |> Enum.reduce(hours_acc(), fn {:ok, result}, report ->
      sum_reports(report, result)
    end)
  end

  defp sum_reports(
         %{
           "all_hours" => all_hours1,
           "hours_per_month" => hours_per_month1,
           "hours_per_year" => hours_per_year1
         },
         %{
           "all_hours" => all_hours2,
           "hours_per_month" => hours_per_month2,
           "hours_per_year" => hours_per_year2
         }
       ) do
    all_hours = Map.merge(all_hours1, all_hours2, &sum_values/3)

    hours_per_month = merge_maps(hours_per_month1, hours_per_month2)

    hours_per_year = merge_maps(hours_per_year1, hours_per_year2)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, inner_map1, inner_map2 ->
      Map.merge(inner_map1, inner_map2, &sum_values/3 )
    end)
  end

  defp sum_values(_key, value1, value2), do: value1 + value2

  defp hours_acc do
    month_list = Enum.into(@months, %{}, &{&1, 0})
    year_list = Enum.into(2016..2020, %{}, &{&1, 0})

    %{"all_hours" => %{}, "hours_per_month" => %{}, "hours_per_year" => %{}}
    |> Map.put("all_hours", acc_id_map_gen(0))
    |> Map.put("hours_per_month", acc_id_map_gen(month_list))
    |> Map.put("hours_per_year", acc_id_map_gen(year_list))
  end

  defp acc_id_map_gen(value), do: Enum.into(@names, %{}, &{&1, value})

  defp build_report(all_hours, hours_per_month, hours_per_year) do
     %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end
end
