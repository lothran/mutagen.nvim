return require('telescope').register_extension {
  exports = { mutagen_list_syncs = require("mutagen").telescope_list_syncs },
}
