defmodule Vayne.Metric.AWS.Elb do

  @behaviour Vayne.Task.Metric

  alias Vayne.Metric.AWS.Util
  
  @metric [
    {"UnHealthyHostCount",   'Count', 'Average'},
    {"Latency",              'Count', 'Average'},
    {"RequestCount",         'Count', 'Sum'},
    {"HTTPCode_ELB_4XX",     'Count', 'Sum'},
    {"HTTPCode_ELB_5XX",     'Count', 'Sum'},
    {"HTTPCode_Backend_2XX", 'Count', 'Sum'},
    {"HTTPCode_Backend_3XX", 'Count', 'Sum'},
    {"HTTPCode_Backend_4XX", 'Count', 'Sum'},
    {"HTTPCode_Backend_5XX", 'Count', 'Sum'},
  ]
  
  @doc """
  * `instanceId`: elb instanceId. Required.
  * `region`: instance region. Required.
  * `secretId`: secretId for monitoring. Not required.
  * `secretKey`: secretKey for monitoring. Not required.
  """
  def init(params) do
    with {:ok, instanceId} <- Util.get_option(params, "instanceId"),
      {:ok, region}     <- Util.get_option(params, "region"),
      {:ok, secret}     <- Util.get_secret(params)
    do
      {:ok, {instanceId, region, secret}}
    else
      {:error, _} = e -> e
      error -> {:error, error}
    end
  end

  def run(stat, log_func) do

    metrics = Application.get_env(:vayne_metric_aws, :elb_metric)

    metrics = if metrics do
      Enum.filter(@metric, fn {m, _, _} -> m in metrics end)
    else
      @metric
    end

    ret = Util.request_metric('AWS/ELB', metrics, stat, log_func, {[], []}, true)

    {:ok, ret}
  end

  def clean(_), do: :ok
end
