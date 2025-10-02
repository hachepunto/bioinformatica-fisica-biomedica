# Preprocesamiento de datos de secuenciación

### Análisis con fastqc

```
wget https://zenodo.org/records/3736457/files/1_control_18S_2019_minq7.fastq
```

```
mkdir fastqc
fastqc -o fastqc/ 1_control_18S_2019_minq7.fastq
```

## Recorte de adaptadores y lecturas de mala calidad

```
mkdir trimming
fastp --in1 sub_SRR10212258_R1.fastq.gz --in2 sub_SRR10212258_R2.fastq.gz --out1 trimming/sub_SRR10212258_R1.trimmed.fq.gz --out2 trimming/sub_SRR10212258_R2.trimmed.fq.gz -g 10 -q 20 -l 50 --html trimming/SRR10212258_fastp.html --json trimming/SRR10212258_fastp.json
```

## Kallisto

Es un programa para la cuantificación de datos de bulk o single-cell RNA-seq

Liga: https://pachterlab.github.io/kallisto/

Primero revisa la sección <b>Getting started</b>

Para poder cuantificar Kallisto necesita un índice del transcriptoma de referencia. Kallisto nos proporciona unos ya generados o podemos generar el nuestro

Liga índices: https://github.com/pachterlab/kallisto-transcriptome-indices/releases

Información de los datos que vamos a usar:

Liga: https://rnabio.org/module-01-inputs/0001/05/01/RNAseq_Data/

Deacargen las carpetas "data_kallisto" y "refs_kallisto" de:

https://drive.google.com/drive/folders/1MakE3A3VHXSmpw3fz66LveVMYWHxhBjW?usp=sharing

Colocar en la carpeta creada "mi_carpeta"

### Ejercicio:

Ahora si probemos kallisto en una muestra.
Para este ejercicio vamos a utlilizar datos de la liga de arriba que ya están descargados en data_kallisto y un índice que ya tenemos preparado en refs_kallisto.

En un archivo que se llame kallisto.sh copia los siguientes comandos:
```
# Definiendo variables
idx="mi_carpeta/refs_kallisto/chr22.idx"
reads="data_kallisto/HBR_Rep1_ERCC-Mix2_Build37-ErccTranscripts-chr22.read1.fastq.gz"
mates="data_kallisto/HBR_Rep1_ERCC-Mix2_Build37-ErccTranscripts-chr22.read2.fastq.gz"

# comando para cuantificar usando kallisto
kallisto quant -i ${idx} -o salida_kallisto --rf-stranded $reads $mates
```
Guarda tu archivo y cópialo a la carpeta mi_carpeta. 
```
# en la terminal, dentro de la carpeta mi_carpeta, ejecuta el siguiente comando:
bash kallisto.sh
```
Inspeccionamos lo que salió
```
ls salida_kallisto
```

El archivo que nos interesa en este momento es abundance.tsv que lo podemos ahora ver con los comandos more o less.
```
more salida_kallisto/abundance.tsv
```

Para hacer lo mismo ahora varias muestras podemos poner el comando de un bucle o loop. Copia el siguiente código a un archivo de texto que se llame hbr_kallisto.sh dentro de la carpeta mi_carpeta. 

```
idx="mi_carpeta/refs_kallisto/chr22.idx"

for id in HBR_Rep1 HBR_Rep2 HBR_Rep3
do
  reads="data_kallisto/${id}_ERCC-Mix2_Build37-ErccTranscripts-chr22.read1.fastq.gz"
  mates="data_kallisto/${id}_ERCC-Mix2_Build37-ErccTranscripts-chr22.read2.fastq.gz"
  
  kallisto quant -i ${idx} -o ~/datos.taller/salida_kallisto_${id} --rf-stranded $reads $mates
done
```

Ya que tenenos el archivo en mi_carpeta ejecutamos el siguiente comando:
```
bash hbr_kallisto.sh
```
Esto nos creo 3 carpetas con la cuanticación de las muestras que empiezan con HBR. 

Ejercicio: ahora intenta haces un archivo uhr_kallisto.sh que haga lo mismo en las muestras que empiezan con UHR.

