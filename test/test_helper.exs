ExUnit.configure formatters: [JUnitFormatter, ExUnit.CLIFormatter]
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(PhoenixContainerExample.Repo, :manual)
