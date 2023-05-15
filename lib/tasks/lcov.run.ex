defmodule Mix.Tasks.Lcov.Run do
  @moduledoc "Generates lcov test coverage files for the application"
  @shortdoc "Generates lcov files"
  @recursive true
  @preferred_cli_env :test

  # Ignore modules compiled by dependencies
  @ignored_paths ["deps/"]

  use Mix.Task
  require Logger

  @doc """
  Generates the `lcov.info` file.
  """
  @impl Mix.Task
  def run(args) do
    {opts, _files} =
      OptionParser.parse!(args,
        strict: [
          quiet: :boolean,
          keep: :boolean,
          output: :string,
          exit: :boolean,
          cwd: :string
        ]
      )

    if opts[:quiet], do: Mix.shell(Mix.Shell.Quiet)

    # lcov.info file setup
    output = opts[:output] || "cover"
    file_path = "#{output}/lcov.info"
    File.mkdir_p!(output)
    File.rm(file_path)

    # Update config for current project on runtime
    original_config = Mix.Project.config()
    ignore_modules = if is_nil(original_config[:test_coverage]) do [] else original_config[:test_coverage][:ignore_modules] end
    config = [
      test_coverage: [
        tool: LcovEx,
        output: output,
        ignore_modules: ignore_modules,
        ignore_paths: @ignored_paths,
        cwd: opts[:cwd],
        keep: opts[:keep]
      ]
    ]

    mix_path = Mix.Project.project_file()
    new_config = original_config |> Keyword.merge(config)
    project = Mix.Project.get()
    Mix.ProjectStack.pop()
    Mix.ProjectStack.push(project, new_config, mix_path)

    # Run tests with updated :test_coverage configuration
    Mix.Task.run("test", ["--cover", "--color"])
  end
end
