#####
# Ejercicio para obtener de datos cuantificados con Kallisto:
# 1. una matriz de expresión normalizada
# 2. una matriz de expresión de cuentas sin normalizar
# 3. análisis de expresión diferencial 
#
# Pasos:
# 1. Instalar las herramientas que vamos a utilizar: BUStoolsR, tximport y DESeq2
# 2. usar tximport para integrar los archivos de cada muestra individual 
#    (a nivel de transcrito) en una sola matriz a nivel de gen.
#    tximport es una función que toma a) un archivo de referencia con los ids de 
#    los transcritos y el id del gene al que pertenecen, y b) los archivos de expresión
#    2.1. cargar nuestros datos de expresión
#    2.2. generar archivo de referencia a partir del siguiente archivo:
# https://drive.google.com/file/d/1CIRVrYvNxy0Odzyr7yrVs9My82nZ7E2J/view?usp=sharing
#    2.3. correr tximport con la referencia y nuestros datos de kallisto
####

### Paso 1: instalar las herramientas que vamos a utilizar

#install.packages("remotes")
#remotes::install_github("lambdamoses/BUStoolsR")
BiocManager::install("tximport")
BiocManager::install("BUSpaRse")
BiocManager::install("rhdf5")
#https://bioconductor.org/packages/release/bioc/html/tximport.html

library(BUSpaRse)
library(tximport)
library(DESeq2)


### Paso 2 
help("tximport")

### Paso 2.1: cargar nuestros datos de expresión

# cargamos el archivo con los nombres de las muestras y 
# las rutas a los archivos de expresión generados por Kallisto
# el archivo sample_sheet.tsv debe tener las columnas:
# Muestra, Condición y Archivo separado por tabs 
setwd("~/Dropbox/Projects/Cursos/IntroRNAseq")

samples <- read.table("sample_sheet.tsv",
                      sep="\t",
                      header=T)


# con este comando inspeccionamos los primeros renglones
#colnames(samples) <- c("Muestra","Condicion","Archivo")
head(samples)


# la funcion tximport espera un vector con las rutas de los archivo de 
# expresión con el atributo names que corresponda al nombre de la muestra
files <- as.vector(samples$Archivo)
names(files) <- samples$Muestra 
head(files)


### Paso 2.2: generar archivo de referencia

# Extraer IDs de transcritos y genes (sin versión)
myIDS <- tr2g_gtf("~/Dropbox/References/Homo_sapiens.GRCh38.104.chr22.gtf",
                  get_transcriptome = F)

# exploramos la tabla que acabamos de generar ...
head(myIDS)

# nuestro archivo de referencia solo necesita estas dos columnas:
tx2gene <- myIDS[,c("transcript","gene")]
head(tx2gene)


### Paso 2.3: ejecutar tximport
txi <- tximport(files, 
                type = "kallisto", 
                tx2gene = tx2gene)


str(txi)
head(txi$counts)
head(txi$abundance)

# Creamos matriz de expresión normalizada (TPM)
table.out <- txi$abundance
head(table.out)
dim(table.out)

# mejoramos la matriz de expresión incluyendo los nombres de los genes también
head(myIDS)
myIDS$gene_name <- ifelse(is.na(myIDS$gene_name), myIDS$gene, myIDS$gene_name)
myNewIds <- unique(myIDS[,2:3])
myNewIds <- unique(myIDS[,c(2,3)])
myNewIds <- unique(myIDS[,-1])
dim(myNewIds)
head(myNewIds)

table.out.names <- merge(myNewIds,
                         table.out,
                         by.x='gene',
                         by.y=0)
dim(table.out)
dim(table.out.names)
head(table.out.names,n=2)
write.table(table.out.names, 
            file="exprTable.tsv", sep="\t", 
            quote=F, 
            col.names=T,
            row.names=F)

### Paso 3: Expresión diferencial con DESeq2
coldata <- data.frame(condition = samples$Condicion)
coldata$condition <- factor(coldata$condition)
rownames(coldata) <- samples$Muestra
head(coldata)
dds <- DESeqDataSetFromTximport(txi, coldata, ~condition)
keep <- rowSums(counts(dds) >= 10) >= 3
dds <- dds[keep, ]
dds <- DESeq(dds)
resultsNames(dds)
res <- results(dds)
head(res,n=2)
plotMA(res)

### Ejercicio para ver como se calcula el log2foldchange
cts <- counts(dds, normalized=T)
head(cts)
cts['ENSG00000008735.14',]
x.HBR <-cts['ENSG00000008735.14',1:3]
x.HBR
mh <- mean(x.HBR)
mh 

x.UHR<-cts['ENSG00000008735.14',4:6]
x.UHR
mu <- mean(x.UHR)
mu

h <- log2(mh)
h
u <- log2(mu)
u

lfc_u_h <- u - h
lfc_u_h

log2(mu/mh)

## --- HEATMAP ---

degs<-subset(res, (!is.na(res$padj) & 
                     res$pvalue<0.05 & 
                     baseMean>=50 & res$padj < 0.05 & 
                     abs(res$log2FoldChange)>1))
dim(degs)
head(degs)
df <- as.data.frame(degs)
head(df)
degs.names <- merge(myNewIds,df,by.x='gene',by.y=0)
dim(degs.names)
head(degs.names,n=2)
write.table(degs.names,"degs.tsv",sep="\t",row.names = F)
write.table(degs.names$gene_name, "degs_symbols.tsv", sep = "\t", row.names = F, col.names = F)


library(pheatmap)
top <- degs[order(degs$padj),]
myTpm <- subset(table.out, 
                rownames(table.out) %in% rownames(top[1:10,]) )
dim(myTpm)
head(myTpm)
log2mat <- log2(myTpm)
my_hmap <- pheatmap(log2mat,
                    main="DEGs UHR vs HBR")


myTpm <- subset(table.out.names, table.out.names$gene %in% rownames(top[1:10,]))
dim(myTpm)
head(myTpm)
mat <- myTpm[,-c(1:2)]
rownames(mat) <- myTpm$gene_name
head(mat,n=3)
log2mat <- log2(mat)
my_hmap <- pheatmap(log2mat,
                    cluster_rows = F,
                    main="DEGs UHR vs HBR")


library(pheatmap)

# Selecciona los 50 genes más significativos
top_genes <- head(order(res$padj), 50)
mat <- assay(varianceStabilizingTransformation(dds))[top_genes, ]

pheatmap(mat,
         cluster_rows = TRUE,
         cluster_cols = TRUE,
         annotation_col = coldata,
         show_rownames = TRUE,
         fontsize = 10,
         color = colorRampPalette(c("navy", "white", "firebrick3"))(50))


## --- VOLCANO PLOT 1 ---

# Paquetes necesarios
library(ggplot2)
library(dplyr)

# Convertimos a data frame y preparamos datos
res_df <- as.data.frame(res) %>%
  mutate(
    gene = rownames(res),
    neg_log10_padj = -log10(padj),
    regulation = case_when(
      log2FoldChange >= 1 & padj < 0.05 ~ "Up",
      log2FoldChange <= -1 & padj < 0.05 ~ "Down",
      TRUE ~ "NS"
    )
  )

# Volcano plot
ggplot(res_df, aes(x = log2FoldChange, y = neg_log10_padj, color = regulation)) +
  geom_point(alpha = 0.7, size = 1.5) +
  scale_color_manual(values = c("Up" = "firebrick", "Down" = "steelblue", "NS" = "gray70")) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "black") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "black") +
  labs(
    title = "Volcano plot",
    x = "log2 Fold Change",
    y = "-log10 adjusted p-value",
    color = "Regulation"
  ) +
  theme_bw(base_size = 14)

## --- VOLCANO PLOT 2 ---

# Instala si no lo tienes
# BiocManager::install("EnhancedVolcano")

library(EnhancedVolcano)

EnhancedVolcano(res,
                lab = rownames(res),
                x = "log2FoldChange",
                y = "padj",
                title = "Volcano plot - DESeq2 results",
                subtitle = NULL,
                xlab = bquote(~Log[2]~ "fold change"),
                ylab = bquote(~-Log[10]~ "adjusted p-value"),
                pCutoff = 0.05,
                FCcutoff = 1.0,
                pointSize = 2.0,
                labSize = 3.0,
                col = c("gray70", "steelblue3", "firebrick3", "firebrick"),
                colAlpha = 0.8,
                legendPosition = "right",
                legendLabSize = 12,
                legendIconSize = 4.0,
                drawConnectors = TRUE,
                widthConnectors = 0.5,
                gridlines.major = FALSE,
                gridlines.minor = FALSE
)


