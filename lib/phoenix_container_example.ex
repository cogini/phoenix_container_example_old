defmodule PhoenixContainerExample do
  @moduledoc """
  PhoenixContainerExample keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require OpenTelemetry.Tracer, as: Tracer

  def hello_otel do
    Tracer.with_span "operation" do
      Tracer.add_event("Nice operation!", [{"bogons", 100}])
      Tracer.set_attributes([{:another_key, "yes"}])

      Tracer.with_span "Sub operation..." do
        Tracer.set_attributes([{:lemons_key, "five"}])
        Tracer.add_event("Sub span event!", [])
      end
    end
  end
end
