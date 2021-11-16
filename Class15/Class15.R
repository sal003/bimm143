##Data download
counts <- read.csv("airway_scaledcounts.csv", row.names=1)
metadata <-  read.csv("airway_metadata.csv")
head(counts)
head(metadata)

##Q1. How many genes are in this dataset?
  nrow(counts)
  #38694 genes
  
##Q2. How many 'control' cell lines do we have?
    View(metadata)
    #4 control cell lines
    
##Toy differential gene expression
  #mean count per genes across samples
    control <- metadata[metadata[,"dex"]=="control",]
    control.counts <- counts[ ,control$id]
    control.mean <- rowSums( control.counts )/4 
    head(control.mean)
  #alternative way
    library(dplyr)
    control <- metadata %>% filter(dex=="control")
    control.counts <- counts %>% select(control$id) 
    control.mean <- rowSums(control.counts)/4
    head(control.mean)
  
##Q3. How would you make the above code in either approach more robust?
      
      
##Q4. Follow the same procedure for the treated samples (i.e. calculate the mean per gene across drug treated samples and assign to a labeled vector called treated.mean)
    treated <- metadata[metadata[,"dex"]=="treated",]
    treated.mean <- rowSums( counts[ ,treated$id] )/4 
    names(treated.mean) <- counts$ensgene
    
#combine metacount data
    meancounts <- data.frame(control.mean, treated.mean)
    colSums(meancounts)
##Q5. Create a scatter plot showing the mean of the treated samples against the mean of the control samples. Your plot should look something like the following.
    plot(meancounts[,1],meancounts[,2], xlab="Control", ylab="Treated")
   
##Q6. Try plotting both axes on a log scale. What is the argument to plot() that allows you to do this?
    plot(meancounts[,1],meancounts[,2], xlab="Control", ylab="Treated", log = "xy")
    
#Calculate log2foldchange
    meancounts$log2fc <- log2(meancounts[,"treated.mean"]/meancounts[,"control.mean"])
    head(meancounts)
    #filter data for anomaly
    zero.vals <- which(meancounts[,1:2]==0, arr.ind=TRUE)
    
    to.rm <- unique(zero.vals[,1])
    mycounts <- meancounts[-to.rm,]
    head(mycounts)
    
##Q7. What is the purpose of the arr.ind argument in the which() function call above? Why would we then take the first column of the output and need to call the unique() function?
    #arr.ind = TRUE gives us both the columns and rows that have zero counts
    #the unique() prevents rows contains more than one zeroes from being counted twice
    
#Up or down-regulated?
    up.ind <- mycounts$log2fc > 2
    down.ind <- mycounts$log2fc < (-2)
##Q8. Using the up.ind vector above can you determine how many up regulated genes we have at the greater than 2 fc level? 
    table(up.ind)["TRUE"]
    #250 up-regulated genes
    
##Q9. Using the down.ind vector above can you determine how many down regulated genes we have at the greater than 2 fc level? 
    table(down.ind)["TRUE"]
    #367 down-regulated genes
    
##Q10. Do you trust these results? Why or why not?
    #No, because I have no information about the p-values
    
    
    
##DESeq2 analysis
    library(DESeq2)
    citation("DESeq2")
    #Import data
    dds <- DESeqDataSetFromMatrix(countData=counts, 
                                  colData=metadata, 
                                  design=~dex)
    dds
    #result?
      #results(dds)
    #use DESeq() function instead
    dds <- DESeq(dds)
    #getting results
    res <- results(dds)
    res
    #convert to data frame
    data.frame <- as.data.frame(res)
    View(data.frame)
    #Summarize data
    summary(res)
    #reset p-value to 0.05
    res05 <- results(dds, alpha=0.05)
    summary(res05)
    
    
##Adding annotation data
    BiocManager::install("AnnotationDbi")
    library("AnnotationDbi")
    BiocManager::install("org.Hs.eg.db")
    library("org.Hs.eg.db")
    #key types?
    columns(org.Hs.eg.db)
    #add individual columns to result table using mapIds()
    res$symbol <- mapIds(org.Hs.eg.db,
                         keys=row.names(res), # Our genenames
                         keytype="ENSEMBL",        # The format of our genenames
                         column="SYMBOL",          # The new format we want to add
                         multiVals="first")
    head(res)
##Q11. Run the mapIds() function two more times to add the Entrez ID and UniProt accession and GENENAME as new columns called res$entrez, res$uniprot and res$genename.
    res$entrez <- mapIds(org.Hs.eg.db,
                         keys=row.names(res),
                         column="ENTREZID",
                         keytype="ENSEMBL",
                         multiVals="first")
    
    res$uniprot <- mapIds(org.Hs.eg.db,
                          keys=row.names(res),
                          column="UNIPROT",
                          keytype="ENSEMBL",
                          multiVals="first")
    
    res$genename <- mapIds(org.Hs.eg.db,
                           keys=row.names(res),
                           column="GENENAME",
                           keytype="ENSEMBL",
                           multiVals="first")
    
    head(res)
    #arrange results by the adjusted p-value
    ord <- order( res$padj )
    #View(res[ord,])
    head(res[ord,])
    #export results to .csv
    write.csv(res[ord,], "deseq_results.csv")
##Data visualization
    #volcano plot
    plot( res$log2FoldChange,  -log(res$padj), 
          xlab="Log2(FoldChange)",
          ylab="-Log(P-value)")
      # Add some cut-off lines
    plot( res$log2FoldChange,  -log(res$padj), 
          ylab="-Log(P-value)", xlab="Log2(FoldChange)")
          abline(v=c(-2,2), col="darkgray", lty=2)
          abline(h=-log(0.05), col="darkgray", lty=2)
      # Setup our custom point color vector 
          mycols <- rep("gray", nrow(res))
          mycols[ abs(res$log2FoldChange) > 2 ]  <- "red" 
          
          inds <- (res$padj < 0.01) & (abs(res$log2FoldChange) > 2 )
          mycols[ inds ] <- "blue"
          
          # Volcano plot with custom colors 
          plot( res$log2FoldChange,  -log(res$padj), 
                col=mycols, ylab="-Log(P-value)", xlab="Log2(FoldChange)" )
          
          # Cut-off lines
          abline(v=c(-2,2), col="gray", lty=2)
          abline(h=-log(0.1), col="gray", lty=2)
          
#Enhanced volcano
    #BiocManager::install("EnhancedVolcano")
    library(EnhancedVolcano)
          x <- as.data.frame(res)
          
          EnhancedVolcano(x,
                          lab = x$symbol,
                          x = 'log2FoldChange',
                          y = 'pvalue')
          
          
##Pathway analysis
    # Run in your R console (i.e. not your Rmarkdown doc!)
      #BiocManager::install( c("pathview", "gage", "gageData") )
    #set up KEGG dataset
          library(pathview)
          library(gage)
          library(gageData)
          
          data(kegg.sets.hs)
          
          # Examine the first 2 pathways in this kegg set for humans
          head(kegg.sets.hs, 2)
          
    #prep before using gage() function
          foldchanges = res$log2FoldChange
          names(foldchanges) = res$entrez
          head(foldchanges)
    #get the results
          keggres = gage(foldchanges, gsets=kegg.sets.hs)
          attributes(keggres)          
    # Look at the first three down (less) pathways
      head(keggres$less, 3)
#use pathview() function to make a pathway plot
  pathview(gene.data=foldchanges, pathway.id="hsa05310")
# A different PDF based output of the same data
  pathview(gene.data=foldchanges, pathway.id="hsa05310", kegg.native=FALSE)
          
          
##Q12. Can you do the same procedure as above to plot the pathview figures for the top 2 down-reguled pathways?
  head(keggres$less, 3)
  #Graft-versus-host disease
    pathview(gene.data=foldchanges, pathway.id="hsa05332")
    pathview(gene.data=foldchanges, pathway.id="hsa05332", kegg.native=FALSE)
  #Type I diabetes mellitus
    pathview(gene.data=foldchanges, pathway.id="hsa04940")
    pathview(gene.data=foldchanges, pathway.id="hsa04940", kegg.native=FALSE) 
   
 
##Plotting counts for genes of interest
    i <- grep("CRISPLD2", res$symbol)
    res[i,]
    rownames(res[i,])
    plotCounts(dds, gene="ENSG00000103196", intgroup="dex")
    # Return the data
    d <- plotCounts(dds, gene="ENSG00000103196", intgroup="dex", returnData=TRUE)
    head(d)
    boxplot(count ~ dex , data=d)
    #Or do it all on ggplot2
      library(ggplot2)
        ggplot(d, aes(dex, count, fill=dex)) + 
       geom_boxplot() + 
       scale_y_log10() + 
       ggtitle("CRISPLD2")
    
       
#Session info check
    sessionInfo()
          
          
          
          
          