## Download extract and load data into R

  # check if complete unziped data is pressent allready if not download and unzip
  if (!file.exists("./input/summarySCC_PM25.rds") |
      !file.exists("./input/Source_Classification_Code.rds")) {
    # creat directory for data
    if (!dir.exists("./input")) {
      dir.create("./input")
    }
    # download zip file from url if not pressent in directory
    if (!file.exists("./input/proj2Data.zip")) {
      download.file(
        "https://d396qusza40orc.cloudfront.net/exdata%2Fdata%2FNEI_data.zip",
        "./input/proj2Data.zip"
      )
    }
    # unzip file.
    if (file.exists("./input/proj2Data.zip")) {
      cat("extracting file")
      unzip("./input/proj2Data.zip",exdir = "./input")
    }else{
      stop("file proj2Data.zip not found cannot extract")
    }
    # check to make sure everything worked ok
    if (!file.exists("./input/summarySCC_PM25.rds")) {
      stop("file summarySCC_PM25.rds not found possible unzip error")
    }
    if (!file.exists("./input/Source_Classification_Code.rds")) {
      stop("file Source_Classification_Code.rds not found possible unzip error")
    }
  }
  # load data into R
  nei <- readRDS("./input/summarySCC_PM25.rds")
  scc <- readRDS("./input/Source_Classification_Code.rds")