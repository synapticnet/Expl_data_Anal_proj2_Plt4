library(dplyr)
library(ggplot2)
library(maps)
library(RColorBrewer)

# only load data if data frames nei or scc do not exist
if(!"nei" %in% ls() | !"scc" %in% ls()){source("loadData.R")}

# load fipsCodes from us census bureau
fipsCodes <-read.csv("http://www2.census.gov/geo/docs/reference/codes/files/national_county.txt",
                     header = FALSE,
                     colClasses = ("character"))


# find any combination of coal and combustion within the same record by looking
# for "coal" and "comb" in every column and returning anything that has both.
# This will add synthetic fuel from coal and charcoal grilling; however with
# a different data set it may pull in unexpected sources, works for this one though.
indexes <- NULL
for(i in 1:ncol(scc)) {
  indexes <- c(indexes,grep("coal",scc[,i],ignore.case = TRUE))
}
allCoalSources <- scc[unique(indexes),]

indexes <- NULL
for(i in 1:ncol(allCoalSources)){
  indexes <- c(indexes,grep("comb",allCoalSources[,i],ignore.case = TRUE))
}
allCoalComb <- allCoalSources[unique(indexes),]

coalNEI <- filter(nei,SCC %in% allCoalComb$SCC)
rm(allCoalSources,allCoalComb,indexes)


# sum emissions by state and year
coalNEI <- mutate(coalNEI,StateFP = substr(fips,1,2)) # pull out state code from fips number
byStateYr <- group_by(coalNEI,StateFP,year) 
totalByState <-  summarise(byStateYr,total_emissions = sum(Emissions))
rm(coalNEI,byStateYr)


# create delta emissions feature
totalByState <- mutate(totalByState,Delta = (total_emissions - lag(total_emissions, order_by = StateFP)))
totalByState$change <- ifelse(totalByState$Delta < 0,"decrease","increase")


# replace state codes with state names formated to match ddplyr's map_data
names(fipsCodes) <- c("State","StateFP","CountyFP","CountyName","ClassFP")
totalByState$State <-  fipsCodes[match(totalByState$StateFP,fipsCodes$StateFP),"State"]
totalByState$region <- state.name[match(totalByState$State,state.abb)]
totalByState$region <- tolower(totalByState$region)
totalByState$region[totalByState$State == "DC"] <- "district of columbia"


# use library(map)'s hidden function centroid.polygon to find center point for states
state_poly <- map("state",plot = FALSE,fill = TRUE)
state_centroids <- maps:::apply.polygon(state_poly,maps:::centroid.polygon)
centroid_df <- Reduce(rbind,state_centroids)
dimnames(centroid_df) <- list(names(state_centroids),c("centerlong","centerlat"))
centroid_df <- as.data.frame(centroid_df)
centroid_df$region <- row.names(centroid_df) 
keepidx <- !(grepl(":",centroid_df$region)) | grepl(":main",centroid_df$region)
centroid_df <- centroid_df[keepidx,]
centroid_df$region <- gsub(":main","",centroid_df$region)


# set up df for plotting map in ggplot
states <- map_data("state")
states <- merge(states,centroid_df,sort = FALSE, by ="region")
states <- merge(states,totalByState,sort = FALSE, by = "region")
states  <- states[order(states$order),]


# Plot total emissions as state color. 
# Plot change from last measuerment as dot size and dot color.
options(scipen=10)
gradientScale <- c(1000,max(totalByState$total_emissions,na.rm = TRUE))
gradientScale <- gradientScale/1
plot4 <- qplot(long, lat, data = states, group = group,fill = total_emissions,geom = "polygon")
plot4 <- plot4 + facet_wrap( ~ year,ncol = 2)
plot4 <- plot4 + scale_fill_gradient(limits= gradientScale,low = "grey",high = "orange")
plot4 <- plot4 + geom_point(data =states, aes(x = centerlong,y = centerlat,size = abs(Delta), col = change))
plot4 <- plot4 + scale_size_area("Magnitude of Change",max_size = 16)
plot4 <- plot4 + scale_color_manual(values = c("green","red"))
plot4 <- plot4 + geom_polygon(data=subset(map_data("state"), region %in% states$region), 
                              aes(x=long, y=lat, group=group), color="black", fill=NA)

plot4 <- plot4 + ggtitle("Coal Combustion Sources Change by Year")
plot4 <- plot4 + theme(axis.ticks.y = element_blank(),axis.title.y = element_blank(), axis.text.y = element_blank(),
                       axis.ticks.x = element_blank(),axis.title.x = element_blank(), axis.text.x = element_blank())


# looks WAY better with no dpi set and width = 15.4,height = 8.75
# however had to make it fit in the assignment window.
print(plot4)
ggsave("plot4.png",width = 15.4,height = 8.75)