defmodule PhoenixContainerExampleWeb.HealthController do
  @moduledoc """
  Return app status for health checks.

  It implements checks for Kubernetes.

  * https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
  * https://shyr.io/blog/kubernetes-health-probes-elixir

  Following is an example Kubernetes deployment yaml configuration:

  ```yaml
    startupProbe:
      httpGet:
        path: /healthz/startup
        port: http
      periodSeconds: 3
      failureThreshold: 5

    livenessProbe:
      httpGet:
        path: /healthz/liveness
        port: http
      periodSeconds: 10
      failureThreshold: 6

    readinessProbe:
      httpGet:
        path: /healthz/readiness
        port: http
      periodSeconds: 10
      failureThreshold: 1
    ```
  """
  use PhoenixContainerExampleWeb, :controller

  alias PhoenixContainerExample.Health

  require Logger

  @doc """
  Basic health check.
  """
  def index(conn, _params) do
    case Health.liveness() do
      :ok ->
        send_resp(conn, 200, "OK")

      {:error, reason} ->
        Logger.error("#{inspect(reason)}")
        send_resp(conn, 503, inspect(reason))
    end
  end

  @doc """
  Return status for Kubernetes startupProbe.
  """
  def startup(conn, _params) do
    case Health.startup() do
      :ok ->
        send_resp(conn, 200, "OK")

      # {:error, {status_code, reason}} when is_integer(status_code) ->
      #   Logger.error("#{inspect(reason)}")
      #   send_resp(conn, status_code, inspect(reason))

      {:error, reason} ->
        Logger.error("#{inspect(reason)}")
        send_resp(conn, 503, inspect(reason))
    end
  end

  @doc """
  Return status for Kubernetes livenessProbe.
  """
  def liveness(conn, _params) do
    case Health.liveness() do
      :ok ->
        send_resp(conn, 200, "OK")

      # {:error, {status_code, reason}} when is_integer(status_code) ->
      #   Logger.error("#{inspect(reason)}")
      #   send_resp(conn, status_code, inspect(reason))

      {:error, reason} ->
        Logger.error("#{inspect(reason)}")
        send_resp(conn, 503, inspect(reason))
    end
  end

  @doc """
  Return status for Kubernetes readinessProbe.
  """
  def readiness(conn, _params) do
    case Health.readiness() do
      :ok ->
        send_resp(conn, 200, "OK")

      # {:error, {status_code, reason}} when is_integer(status_code) ->
      #   Logger.error("#{inspect(reason)}")
      #   send_resp(conn, status_code, inspect(reason))

      {:error, reason} ->
        Logger.error("#{inspect(reason)}")
        send_resp(conn, 503, inspect(reason))
    end
  end
end
