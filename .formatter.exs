[
  import_deps: [:ecto, :phoenix],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [Styler],
  subdirectories: ["priv/*/migrations"]
]
