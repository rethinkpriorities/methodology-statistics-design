# Get EA survey data (only for those with access), used in examples in this methods book #####


print("NOTE: You need to follow steps at https://stackoverflow.com/questions/62336550/source-data-r-from-private-repository for this import to work, and you need access")


eas_all <- read_file_from_repo(
  repo = "ea-data",
  path = "data/edited_data/eas_all.Rdata",
  user = "rethinkpriorities",
  token_key = "github-API",
  private = TRUE
)

eas_20 <- read_file_from_repo("ea-data",  "data/edited_data/eas_20.Rdata", "github-API", private = TRUE )


# cheesy workaround in case the above fails or you are not online

#eas_all <- readRDS("../ea-data/data/edited_data/eas_all.Rdata")
#eas_20 <- readRDS("../ea-data/data/edited_data/eas_20.Rdata")


