# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [
    config: 3,
    config: 4,
    config!: 3,
    config!: 4,
    config_from: 3,
    config_from: 4,
    config_from!: 3,
    config_from!: 4
  ],
  export: [
    locals_without_parens: [
      config: 3,
      config: 4,
      config!: 3,
      config!: 4,
      config_from: 3,
      config_from: 4,
      config_from!: 3,
      config_from!: 4
    ]
  ]
]
