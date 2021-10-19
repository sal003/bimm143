#' ---
#' title: "Class 05 Data Visualization"
#' author: "Sangbum Lee (A15485151)"
#' date: "October 12th, 2021"
#' ---

# Class 05 Data Visualization

# Let's start with a scatterplot
#Before we can use it, we need to load ggplot2 from library
library(ggplot2)

# Every ggplot has a data + aes + geoms layers
# cars --> speed vs distance to stop
ggplot(data=cars) +
  aes(x=speed,y=dist)+
  geom_point() +
  geom_smooth()
  
#Change to a linear model
p <-ggplot(data=cars) +
  aes(x=speed,y=dist)+
  geom_point() +
  geom_smooth(method="lm",se=FALSE)

#Add labels
p + labs(title= "Speed and Stopping Distances of Cars",
       x="Speed(MPH)",y= "Stopping Distance(ft)",
       subtitle = "Emergency break performance of cars",
       caption = "Dataset: 'cars'")

#Base graphics is shorter
plot(cars)

#Gene Differential Expression Data ()
url <- "https://bioboot.github.io/bimm143_S20/class-material/up_down_expression.txt"
genes <- read.delim(url)
head(genes)

#Number of rows?
nrow(genes)

#Column names?
colnames(genes)

#Number of columns?
ncol(genes)

#Use table function on "State" of genes data.frame
table(genes["State"])
#Or
table(genes$State)

#Percent of total genes up or down regulated(signif = 2)
round(table(genes$State)/nrow(genes)*100,2)

#Plot genes
ggplot(genes)+
  aes(Condition1,Condition2)+
  geom_point()

#Add color to State
z <- ggplot(genes)+
  aes(Condition1,Condition2,col=State)+
  geom_point()

#Specify color scale
z+scale_color_manual(values=c("red","gray","blue"))

#Add labels
z+scale_color_manual(values=c("red","gray","blue"))+
  labs(title = "Changes in Gene Expression with Drug Treatment",
            x="Control(no drug)",y="Drug treatment")

#Install and load "gapminder" (economic&demographic dataset)
install.packages("gapminder")
library(gapminder)

#Install and load "dplyr"
install.packages("dplyr")
library(dplyr)
