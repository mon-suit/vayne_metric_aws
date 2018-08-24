defmodule Vayne.Metric.AWS.ElastiCache do

  @behaviour Vayne.Task.Metric

  alias Vayne.Metric.AWS.Util

  @metric_redis [
    {"BytesUsedForCache",    "Bytes",   'Maximum'},
    {"CacheHits",            "Count",   'Maximum'},
    {"CacheMisses",          "Count",   'Maximum'},
    {"EngineCPUUtilization", "Percent", 'Maximum'},
    {"HyperLogLogBasedCmds", "Count",   'Maximum'},
    {"Reclaimed",            "Count",   'Maximum'},
    {"ReplicationBytes",     "Bytes",   'Maximum'},
    {"ReplicationLag",       "Seconds", 'Maximum'},
    {"SaveInProgress",       "Count",   'Maximum'},
  ]

  @metric_memcache [
    {"CasHits",         "Count",   'Maximum'},
    {"CasMisses",       "Count",   'Maximum'},
  ]

  @metric [
    {"CPUUtilization",  "Percent", 'Maximum'},
    {"SwapUsage",       "Bytes",   'Maximum'},
    {"FreeableMemory",  "Bytes",   'Maximum'},
    {"NetworkBytesIn",  "Bytes",   'Maximum'},
    {"NetworkBytesOut", "Bytes",   'Maximum'},
    {"CurrItems",       "Count",   'Maximum'},
    {"CurrConnections", "Count",   'Maximum'},
    {"Evictions",       "Count",   'Maximum'},
    {"NewConnections",  "Count",   'Maximum'},
  ]

  @doc """
  * `instanceId`: elasticache instanceId. Required.
  * `region`: db instance region. Required.
  * `type`: "redis" or "memcache". Not required. Default "redis".
  * `secretId`: secretId for monitoring. Not required.
  * `secretKey`: secretKey for monitoring. Not required.
  """
  def init(params) do
    with {:ok, instanceId} <- Util.get_option(params, "instanceId"),
      {:ok, region}  <- Util.get_option(params, "region"),
      {:ok, secret}  <- Util.get_secret(params),
      type           <- Map.get(params, "type", "redis")
    do
      {:ok, {{instanceId, region, secret}, type}}
    else
      {:error, _} = e -> e
      error -> {:error, error}
    end
  end

  def run({stat, type}, log_func) do

    default_metrics = case type do
      "redis" ->
        @metric ++ @metric_redis
      "memcache" ->
        @metric ++ @metric_memcache
      _ ->
        @metric
    end

    metrics = Application.get_env(:vayne_metric_aws, :elasticache_metric)

    metrics = if metrics do
      Enum.filter(default_metrics, fn {m, _, _} -> m in metrics end)
    else
      default_metrics
    end

    ret = Util.request_metric('AWS/ElastiCache', metrics, stat, log_func, {[], []})
    {:ok, ret}
  end

  def clean(_), do: :ok
end
