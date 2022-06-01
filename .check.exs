[
  tools: [
    {:compiler, "mix compile --force"},
    {:credo, "mix credo --strict"},
    {:sobelow, false},
    {:ex_unit, "mix coveralls.html --trace",
     detect: [{:file, "test"}], retry: "mix test --trace --failed"},
    {:npm_test, false}
  ]
]
