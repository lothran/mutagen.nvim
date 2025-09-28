local mut = require("mutagen")




return require('telescope').register_extension {
    exports = { mutagen_list_syncs = mut.telescope_list_syncs },
}
