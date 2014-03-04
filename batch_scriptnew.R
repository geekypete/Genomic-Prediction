require(rPlant)
user.name <- "pl8210"
user.pwd <- "2_Geek_3"
Validate(user.name, user.pwd)

ListDir(user.name, token, "data/Syngenta/PEDMAP", shared.user.name="kamichels")

### BATCH START ###
file.list <- ListDir(user.name, token, "data/Syngenta/PEDMAP", shared.user.name="kamichels")
files <- file.list[1:3600]
assoc.list <- list("--assoc", "--assoc --qt-means", "--fisher", "--model", "--model --fisher", "--bd", "--homog", "--T2", "--linear", "--logistic")
job.list <- vector("list",length(files)*length(assoc.list))

m <- 1
n <- 1
failed.list <- list()
for (i in 1:length(files)){
  
  k <- 1
# for (k in 1:length(assoc.list)){
    job.list[[m]] <- tryCatch(RunPLINK(user.name, token, DE.file.list=list(files[i], files[i+1]), DE.file.path="data/Syngenta/PEDMAP", association.method=assoc.list[[k]], shared.user.name="kamichels"), error=function(x){x <- NA; return(x)})
    if (is.na(job.list[[m]][1])){
      failed.list[[n]] <- files[i]
      n <- n+1
    } else {
      m <- m+1
    }
# }
  i <- i+2
  RenewToken(user.name, user.pwd, token, "iplant")
}






begin.time <- proc.time()
failed.list <- list()
for (i in 400:425){
  out <- MoveFile(paste(job.list[[i]][[2]],".qassoc.adjusted",sep=""), paste("analyses/", job.list[[i]][[2]], sep=""), "SyngentaPLINK/Standard/")

  test <- tryCatch(out$success, error=function(x){x <- NA; return(x)})

  if (is.na(test)){
    failed.list <- append(failed.list, list(c(job.list[[i]][[1]], job.list[[i]][[2]])))
  }
}
end.time <- proc.time()







RenewToken(user.name, user.pwd, token, "iplant")

for (i in 1:(length(job.list)/2)){
  print(CheckJobStatus(user.name, token, job.list[[i]][1], verbose=F))
}

### Move Files to appropriate folder
 for (i in 425:435){ MoveFile(paste(job.list[[i]][[2]],".qassoc.adjusted",sep=""), paste("analyses/", job.list[[i]][[2]], sep=""), "SyngentaPLINK/Standard/")}


### Retrieving Appropriate files ###
### WARNING!!!  Not all of the results are on .assoc.adjusted, I would  ###
### run the above double loop with i=1 and see what files the different ###
job### results will be in, and make an appropriate loop.                   ###

for (i in 1:20){
  RetrieveJob(user.name, token, job.list[[i]][[1]], paste(job.list[[i]][[2]],".qassoc.adjusted",sep=""), zip=FALSE)
}

### Below is a way to save the workspace so all of your job.list numbers and job.list names will not be lost, because without them we can't recieve anything. ###
save.image("stdplink.RData")


notdone <- c()
failed <- c()
finished <- c()
for (i in 1:length(job.list)){
  status <- CheckJobStatus(user.name, token, job.list[[i]][[1]], verbose=F)
  if (status == "FAILED") {
    failed <- c(failed,i)
  } else if (status == "ARCHIVING_FINISHED") {
    finished <- c(finished,i)
  } else {
    notdone <- c(notdone,i)
  }
}

# job.names <- c()
# GJH <- ListDir(user.name, token, "analyses")
# for (i in 2:41){
#     job.names <- c(job.names,GJH[[i]])
#   }
# }

# job.name.list <- vector("list",length(job.names))
# i <- 1
# j <- 1
# flag <- 0
# for (i in 1:600){
#   for (j in 1:length(job.names)){
#     if (job.list[[i]][2] == job.names[j]){
#       job.name.list[[j]] <- c(job.list[[i]][1],job.list[[i]][2])
#     }
#   }
# }

### A potential way to retrieve jobs, this won't work with PLINK, but replace MoveFile with RetrieveJob ###
finish.final <- job.list
count <- 0
tally <- 0
for (i in 1:length(job.list)){
  count <- count + 1
  out <- tryCatch(MoveFile(user.name, token, DE.file.name=paste(job.list[[i]][[2]],".ped",sep=""), DE.file.path=paste("analyses/",job.list[[i]][[2]],sep=""), DE.end.path="data/Syngenta"), error=function(x){x <- NA; return(x)})
  if (is.na(out)){
    failed <- c(failed,i)
  } else {
    MoveFile(user.name, token, DE.file.name=paste(job.list[[i]][[2]],".map",sep=""), DE.file.path=paste("analyses/",job.list[[i]][[2]],sep=""), DE.end.path="data/Syngenta")
    DeleteDir(user.name, token, DE.dir.name=paste(job.list[[i]][[2]],sep=""), DE.dir.path="analyses", print.curl=FALSE)
    DeleteJob(user.name, token, job.list[[i]][[1]])
  }
}

# job.names <- ListDir(user.name, token, "analyses")
# job.names <- test
# failed.names <- c()
# j <- 1
# count <- 0
# tally <- 0
# for (i in 1:length(test)){
#   for (j in 1:length(failed.names)){
#    if ((i == 1 ) && (test[i] == failed.names[[j]])) {
#       job.names <- job.names[2:length(job.names)]
#       tally <- tally + 1
#     } else if ((i == length(test) ) && (test[i] == failed.names[[j]])) {
#       job.names <- job.names[1:(length(job.names)-1)]
#       tally <- tally + 1    
#     } else if (test[i] == failed.names[[j]]){
#       job.names <- job.names[c(1:(i-1-tally),(i+1-tally):length(job.names))]
#       tally <- tally + 1
#     }
#   }
# }
