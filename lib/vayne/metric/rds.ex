defmodule Vayne.Metric.AWS.Rds do

  @behaviour Vayne.Task.Metric

  alias Vayne.Metric.AWS.Util
  
  @metric_rds_mysql [
    {"BinLogDiskUsage", "Bytes", 'Maximum'}
  ]

  @metric_rds_postgre [
    {"OldestReplicationSlotLag",  "Megabytes",        'Maximum'},
    {"ReplicationSlotDiskUsage",  "Megabytes",        'Maximum'},
    {"TransactionLogsDiskUsage",  "Megabytes",        'Maximum'},
    {"TransactionLogsGeneration", "Megabytes/second", 'Maximum'},
  ]
  
  @metric_rds [
    {"BurstBalance",              "Percent",      'Maximum'},
    {"CPUUtilization",            "Percent",      'Maximum'},
    {"CPUCreditUsage",            "Credits",      'Maximum'},
    {"CPUCreditBalance",          "Credits",      'Maximum'},
    {"DatabaseConnections",       "Count",        'Maximum'},
    {"DiskQueueDepth",            "Count",        'Maximum'},
    {"FreeableMemory",            "Bytes",        'Maximum'},
    {"FreeStorageSpace",          "Bytes",        'Maximum'},
    {"MaximumUsedTransactionIDs", "Bytes",        'Maximum'},
    {"NetworkReceiveThroughput",  "Bytes/Second", 'Maximum'},
    {"NetworkTransmitThroughput", "Bytes/Second", 'Maximum'},
    {"ReadIOPS",                  "Count/Second", 'Maximum'},
    {"ReadLatency",               "Seconds",      'Maximum'},
    {"ReadThroughput",            "Bytes/Second", 'Maximum'},
    {"ReplicaLag",                "Seconds",      'Maximum'},
    {"SwapUsage",                 "Bytes",        'Maximum'},
    {"WriteIOPS",                 "Count/Second", 'Maximum'},
    {"WriteLatency",              "Seconds",      'Maximum'},
    {"WriteThroughput",           "Bytes/Second", 'Maximum'}
  ]

  @metric_aurora_mysql [
    {"ActiveTransactions",                 "Count/Second", 'Maximum'},
    {"AuroraBinlogReplicaLag",             "Seconds",      'Maximum'},
    {"BinLogDiskUsage",                    "Bytes",        'Maximum'},
    {"BacktrackChangeRecordsCreationRate", "Count/Second", 'Maximum'},
    {"BacktrackChangeRecordsStored",       "Count",        'Maximum'},
    {"BacktrackWindowActual",              "Count",        'Maximum'},
    {"BacktrackWindowAlert",               "Count",        'Maximum'},
    {"BlockedTransactions",                "Count/Second", 'Maximum'},
    {"CPUCreditBalance",                   "None",         'Maximum'},
    {"CPUCreditUsage",                     "None",         'Maximum'},
    {"DDLLatency",                         "Milliseconds", 'Maximum'},
    {"DDLThroughput",                      "Count/Second", 'Maximum'},
    {"DeleteLatency",                      "Milliseconds", 'Maximum'},
    {"DeleteThroughput",                   "Count/Second", 'Maximum'},
    {"DMLLatency",                         "Milliseconds", 'Maximum'},
    {"DMLThroughput",                      "Count/Second", 'Maximum'},
    {"InsertLatency",                      "Milliseconds", 'Maximum'},
    {"InsertThroughput",                   "Count/Second", 'Maximum'},
    {"LoginFailures",                      "Count/Second", 'Maximum'},
    {"Queries",                            "Count/Second", 'Maximum'},
    {"ResultSetCacheHitRatio",             "Percent",      'Maximum'},
    {"SelectLatency",                      "Milliseconds", 'Maximum'},
    {"SelectThroughput",                   "Count/Second", 'Maximum'},
    {"UpdateLatency",                      "Milliseconds", 'Maximum'},
    {"UpdateThroughput",                   "Count/Second", 'Maximum'},
  ]

  @metric_aurora_postgre [
    {"DiskQueueDepth",                  "Count",        'Maximum'},
    {"MaximumUsedTransactionIDs",       "Count",        'Maximum'},
    {"RDSToAuroraPostgreSQLReplicaLag", "Seconds",      'Maximum'},
    {"ReadIOPS",                        "Count/Second", 'Maximum'},
    {"ReadLatency",                     "Seconds",      'Maximum'},
    {"ReadThroughput",                  "Bytes/Second", 'Maximum'},
    {"SwapUsage",                       "Bytes",        'Maximum'},
    {"TransactionLogsDiskUsage",        "Megabytes",    'Maximum'},
    {"WriteIOPS",                       "Count/Second", 'Maximum'},
    {"WriteLatency",                    "Seconds",      'Maximum'},
    {"WriteThroughput",                 "Bytes/Second", 'Maximum'},
  ]

  @metric_aurora [
    {"AuroraReplicaLag",          "Milliseconds", 'Maximum'},
    {"AuroraReplicaLagMaximum",   "Milliseconds", 'Maximum'},
    {"AuroraReplicaLagMinimum",   "Milliseconds", 'Maximum'},
    {"BufferCacheHitRatio",       "Percent",      'Maximum'},
    {"CommitLatency",             "Milliseconds", 'Maximum'},
    {"CommitThroughput",          "Count/Second", 'Maximum'},
    {"CPUUtilization",            "Percent",      'Maximum'},
    {"DatabaseConnections",       "Count",        'Maximum'},
    {"Deadlocks",                 "Count/Second", 'Maximum'},
    {"EngineUptime",              "Seconds",      'Maximum'},
    {"FreeableMemory",            "Bytes",        'Maximum'},
    {"FreeLocalStorage",          "Bytes",        'Maximum'},
    {"NetworkReceiveThroughput",  "Bytes/Second", 'Maximum'},
    {"NetworkThroughput",         "Bytes/Second", 'Maximum'},
    {"NetworkTransmitThroughput", "Bytes/Second", 'Maximum'},
    {"VolumeBytesUsed",           "Bytes",        'Maximum'},
    {"VolumeReadIOPs",            "Count/Second", 'Maximum'},
    {"VolumeWriteIOPs",           "Count/Second", 'Maximum'},
  ]

  @metric_MB [
    "OldestReplicationSlotLag",
    "ReplicationSlotDiskUsage",
    "TransactionLogsDiskUsage",
    "TransactionLogsGeneration"
  ]


  
  @doc """
  * `instanceId`: rds instanceId. Required.
  * `region`: rds instance region. Required.
  * `db_type`: "mysql" or "postgre". Not required. Default "mysql".
  * `allocated_storage`: AllocatedStorage. Not required.
  * `secretId`: secretId for monitoring. Not required.
  * `secretKey`: secretKey for monitoring. Not required.
  """
  def init(params) do
    with {:ok, instanceId} <- Util.get_option(params, "instanceId"),
      {:ok, region}     <- Util.get_option(params, "region"),
      {:ok, secret}     <- Util.get_secret(params),
      db_type           <- Map.get(params, "db_type", "mysql"),
      allocated_storage <- Map.get(params, "allocated_storage")
    do
      {:ok, {{instanceId, region, secret}, db_type, allocated_storage}}
    else
      {:error, _} = e -> e
      error -> {:error, error}
    end
  end

  def run({stat, db_type, allocated_storage}, log_func) do

    default_metrics = case db_type do
      "mysql" ->
        @metric_rds ++ @metric_rds_mysql
      "postgre" ->
        @metric_rds ++ @metric_rds_postgre
      "aurora" ->
        @metric_aurora
      "aurora-mysql" ->
        @metric_aurora ++ @metric_aurora_mysql
      "aurora-postgre" ->
        @metric_aurora ++ @metric_aurora_postgre
      _ ->
        @metric_rds
    end

    metrics = Application.get_env(:vayne_metric_aws, :rds_metric)

    metrics = if metrics do
      Enum.filter(default_metrics, fn {m, _, _} -> m in metrics end)
    else
      default_metrics
    end

    ret = Util.request_metric('AWS/RDS', metrics, stat, log_func, {[], @metric_MB})

    ret = cond do
      is_nil(allocated_storage) or allocated_storage == 0 ->
        ret
      is_nil(ret["FreeStorageSpace"]) ->
        ret
      true ->
        percent = 100 * ret["FreeStorageSpace"] / allocated_storage
        ret
        |> Map.put("AllocatedStorage", allocated_storage)
        |> Map.put("FreeStorageSpacePercent", Float.floor(percent, 3))
    end

    ret = cond do
      is_nil(ret["ReadIOPS"])  -> ret
      is_nil(ret["WriteIOPS"]) -> ret
      true ->
        all_iops = ret["ReadIOPS"] + ret["WriteIOPS"]
        Map.put(ret, "AllIOPS", Float.floor(all_iops, 3))
    end

    {:ok, ret}
  end

  def clean(_), do: :ok
end
