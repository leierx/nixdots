return {
  filetypes = { "yaml", "yaml.ansible", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
  settings = {
    yaml = {
      format = { enable = false },
      schemaStore = { enable = false, url = "" },
      schemas = require("schemastore").yaml.schemas(),
    },
  },
}
