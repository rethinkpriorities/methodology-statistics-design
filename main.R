# 'main.R': this single file should (ideally) source and build all data, build codebooks, run all analysis, and build bookdown and other output

#### Setup ####

try_download <- function(url, path) {
  new_path <- gsub("[.]", "X.", path)
  tryCatch({
    download.file(url = url,
                  destfile = new_path)
  }, error = function(e) {
    print("You are not online, so we can't download")
  })
  tryCatch(
    file.rename(new_path, path)
  )
}

library(here)
library(pacman)
here <- here::here()
rename_all <- dplyr::rename_all
rename <- dplyr::rename




#... Import setup for this project using template from dr-rstuff  ####

dir.create(here("code"))

try_download(
  "https://raw.githubusercontent.com/daaronr/dr-rstuff/master/functions/project_setup.R",
  here::here("code", "project_setup.R")
)

try_download(
  "https://raw.githubusercontent.com/daaronr/dr-rstuff/master/functions/download_formatting.R",
  here::here("code", "download_formatting.R")
)

# Note: I used to do the 'install a set of packages thing here' ... but with renv we can just have renv search for and install these (in Rstudio it reminds you; otherwise use call `renv::dependencies()` or `renv::hydrate` I think. )

if (!require("devtools")) install.packages("devtools")
devtools::install_github("peterhurford/surveytools2") #installing this here bc renv doesn't detect it

## You MUST run this for anything else to work ####
source(here::here("code", "project_setup.R"))

##NOTE: these sourced files seem to need some packages to be installed.
#Todo -- 'embed' that somehow? (I just used Renv to add these for now)

source(here::here("code", "download_formatting.R"))

print("project_setup creates 'support' folder and downloads tufte_plus.css, header.html into it")
print("project_setup creates 'code' folder and downloads baseoptions.R, and functions.R into it, and sources these")

### Source model-building tools/functions
#source(here::here("code","modeling_functions.R"))

#Pulling in key files from other repos; don't edit them here
#Just 'pull these in' from the ea-data repo for now; we may re-home them here later

dir.create(here("remote"))

#THIS fails, probably because its a private repo: try_download("https://raw.githubusercontent.com/rethinkpriorities/ea-data/master/Rmd/methods_interaction_sharing.Rmd?token=AB6ZCMD4HRHLJCFNLBKYO5LBRWHLY", here::here("remote", "methods_interaction_sharing_remote.Rmd"))


p_load("bettertrace") #better tracking after bugs

#### BUILD the bookdown ####
#The line below should 'build the bookdown' in the order specified in `_bookdown.yml`

#p_load(bookdown)

{
  options(knitr.duplicate.label = "allow")
  rmarkdown::render_site(output_format = 'bookdown::gitbook', encoding = 'UTF-8')
}



