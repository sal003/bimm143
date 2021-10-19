rescale02 <- function(x,na.rm=TRUE){
  rng <- range(x,na.rm= na.rm)
  (x-rng[1])/(rng[2]-rng[1])
}