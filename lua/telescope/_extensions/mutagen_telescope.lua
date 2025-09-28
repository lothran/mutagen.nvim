local list = require("telescope._extensions.mutagen.list")



return require('telescope').register_extension {
  setup = function(ext_config, config)
    -- access extension config and user config
  end,
  exports = { mutagen_list_syncs = list.telescope_list_syncs },
}
