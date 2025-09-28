local list = require("telescope._extensions.mutagen.list")



return require('telescope').register_extension {

  exports = { mutagen_list_syncs = list },
}
