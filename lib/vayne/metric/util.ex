defmodule Vayne.Metric.AWS.Util do

  @aws_region %{
    "use1"  => "us-east-1",
    "use2"  => "us-east-2",
    "usw1"  => "us-west-1",
    "usw2"  => "us-west-2",
    "cac1"  => "ca-central-1",
    "aps1"  => "ap-south-1",
    "apne2" => "ap-northeast-2",
    "apse1" => "ap-southeast-1",
    "apse2" => "ap-southeast-2",
    "apne1" => "ap-northeast-1",
    "euc1"  => "eu-central-1",
    "euw1"  => "eu-west-1",
    "euw2"  => "eu-west-2",
    "sae1"  => "sa-east-1"
  }

  def get_option(params, key) do
    case Map.fetch(params, key) do
      {:ok, _} = v -> v
      _ -> {:error, "#{key} is missing"}
    end
  end

  def get_secret(params) do

    env_secretId = Application.get_env(:vayne_metric_ksy, :secretId)
    env_secretKey = Application.get_env(:vayne_metric_ksy, :secretKey)

    cond do
      Enum.all?(~w(secretId secretKey), &(Map.has_key?(params, &1))) ->
        {:ok, {params["secretId"], params["secretKey"]}}
      Enum.all?([env_secretId, env_secretKey], &(not is_nil(&1))) ->
        {:ok, {env_secretId, env_secretKey}}
      true ->
        {:error, "secretId or secretKey is missing"}
    end
  end

  @before -4
  def request_metric(namespace, metrics, {instanceId, region, {secretId, secretKey}}, log_func, {metric_kB, metric_mB}, ignore_empty? \\ false) do

    region = Map.get(@aws_region, region, region)
    addr   = "monitoring.#{region}.amazonaws.com" |> String.to_charlist
    config = :erlcloud_mon.new(String.to_charlist(secretId), String.to_charlist(secretKey), addr)

    now        = Timex.now
    start_time = now |> Timex.shift(minutes: @before) |> Timex.to_erl
    end_time   = now |> Timex.to_erl

    Enum.reduce(metrics, %{}, fn ({metric, unit, sta}, acc) -> 

      ret = :erlcloud_mon.get_metric_statistics(
        namespace, metric, start_time, end_time,
        60, unit, [sta], 
        dimension(namespace, instanceId), config
      )
      case ret do
        [_, {'datapoints', array}] ->
          max = Enum.max_by(array, fn [{:timestamp, timestamp}, _, _] -> timestamp end, fn -> nil end)
          case max do
            [_, _, {_, count}] ->
              value = count |> :erlang.list_to_float |> Float.floor(3)
              value = if metric in metric_kB, do: value * 1024, else: value
              value = if metric in metric_mB, do: value * 1024 * 1024, else: value
              Map.put(acc, metric, value)
            _ ->
              unless ignore_empty?, do: log_func.("get #{metric} empty value")
              acc
          end

        other ->
          log_func.(other)
          acc
      end

    end)
  end

  def dimension('AWS/RDS', instanceId),         do: [{'DBInstanceIdentifier', instanceId}]
  def dimension('AWS/ELB', instanceId),         do: [{'LoadBalancerName', instanceId}]
  def dimension('AWS/ElastiCache', instanceId), do: [{'CacheClusterId', instanceId}]

  def dimension(namespace, _instanceId), do: raise "not support namespace: #{namespace}"

end
