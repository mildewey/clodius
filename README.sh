##########################################################################################
### HiC data
#########################################################################################


### Smaller test set

### Real data set

FILENAME=rao_et_al/HMEC/5kb_resolution_intrachromosomal/chr1/MAPQGE30/chr1_5kb.RAWobserved
FILENAME=rao_et_al/HMEC/5kb_resolution_intrachromosomal/chr1/MAPQGE30/chr1_5kb.RAWobserved
FILENAME=rao_et_al/HUVEC/5kb_resolution_intrachromosomal/chr1/MAPQGE30/chr1_5kb.RAWobserved

FILENAME=rao_et_al/IMR90/5kb_resolution_intrachromosomal/chr1/MAPQGE30/chr1_5kb.RAWobserved
FILENAME=rao_et_al/GM12878_primary/5kb_resolution_intrachromosomal/chr1/MAPQGE30/chr1_5kb.RAWobserved

DATASET_NAME=hg19/Dixon2015-H1hESC_ES-HindIII-allreps-filtered.1kb.genome.gz
FILENAME=coolers/${DATASET_NAME}
FILEPATH=~/data/${FILENAME}

zcat $FILEPATH > ${FILEPATH}.mirrored
zcat $FILEPATH | awk '{ print $2 "\t" $1 "\t" $3; }' >> ${FILEPATH}.mirrored

head -n 40000000 ${FILEPATH}.mirrored.shuffled > ${FILEPATH}.short

#SPARK_HOME_DIR=/Users/peter/Downloads/spark-1.6.1
#SPARK_HOME_DIR=/home/ubuntu/apps/spark-1.6.1-bin-hadoop2.6
SPARK_HOME_DIR=~/spark-home

/usr/bin/time ${SPARK_HOME_DIR}/bin/spark-submit scripts/make_tiles.py -v count -p pos1,pos2 -c pos1,pos2,count -i count -r 1000 -b 256 --max-zoom 20 --output-format dense --use-spark  ${FILEPATH}.short --elasticsearch-nodes localhost:9200  --elasticsearch-path test_shorter/tiles

# Run locally
# OUTPUT_DIR=${FILEPATH}.short.tiles; rsync -a --delete blank/ $OUTPUT_DIR; mkdir -p $OUTPUT_DIR; /usr/bin/time python scripts/make_tiles.py -o $OUTPUT_DIR -v count -p pos1,pos2 -c pos1,pos2,count -i count -r 1000 -b 256 --max-zoom 20 --output-format dense ${FILEPATH}.short

/usr/bin/time ${SPARK_HOME_DIR}/bin/spark-submit scripts/make_tiles.py -v count -p pos1,pos2 -c pos1,pos2,count -i count -r 1000 -b 256 --max-zoom 20 --output-format dense --use-spark --elasticsearch-nodes localhost:9200  --elasticsearch-path ${DATASET_NAME} ${FILEPATH}.mirrored.shuffled

#OUTPUT_DIR=${FILEPATH}.tiles; rsync -a --delete blank/ $OUTPUT_DIR; mkdir -p $OUTPUT_DIR; /usr/bin/time ${SPARK_HOME_DIR}/bin/spark-submit scripts/make_tiles.py -o $OUTPUT_DIR -v count -p pos1,pos2 -c pos1,pos2,count -i count -r 1000 -b 256 --max-zoom 20 --output-format dense --use-spark  ${FILEPATH}.mirrored

#find $OUTPUT_DIR -name "*.json" | xargs chmod a+r 

aws s3 sync --region us-west-2 ~/data/${FILENAME}.tiles s3://pkerp/data/${FILENAME}.tiles


##########################################################################################
### Gene annotations
#########################################################################################

INPUT_FILE=~/data/hg19/genbank-output/refgene-count-minus
DATASET_NAME=hg19/refgene-tiles-minus
OUTPUT_DIR=~/data/${DATASET_NAME}
/usr/bin/time python scripts/make_tiles.py --elasticsearch-nodes localhost:9200 --elasticsearch-path $DATASET_NAME -v count --position genomeTxStart --end-position genomeTxEnd  -c refseqid,chr,strand,txStart,txEnd,genomeTxStart,genomeTxEnd,cdsStart,cdsEnd,exonCount,exonStarts,exonEnds,geneName,count,uid --max-zoom 18 -i count --importance --reverse-importance --max-entries-per-tile 16 $INPUT_FILE 

    #rsync -a --delete blank/ $OUTPUT_DIR; mkdir -p $OUTPUT_DIR; /usr/bin/time python scripts/make_tiles.py -o $OUTPUT_DIR -v count --position genomeTxStart --end-position genomeTxEnd  -c refseqid,chr,strand,txStart,txEnd,genomeTxStart,genomeTxEnd,cdsStart,cdsEnd,exonCount,exonStarts,exonEnds,geneName,count,uid --max-zoom 5 -i count --importance --reverse-importance --max-entries-per-tile 16 $INPUT_FILE 
    #rsync -avzP $OUTPUT_DIR/ ~/projects/goomba/.tmp/jsons/${DATASET_NAME}

INPUT_FILE=~/data/hg19/genbank-output/refgene-count-plus
DATASET_NAME=hg19/refgene-tiles-plus
OUTPUT_DIR=~/data/${DATASET_NAME}

/usr/bin/time python scripts/make_tiles.py --elasticsearch-nodes localhost:9200 --elasticsearch-path $DATASET_NAME -v count --position genomeTxStart --end-position genomeTxEnd  -c refseqid,chr,strand,txStart,txEnd,genomeTxStart,genomeTxEnd,cdsStart,cdsEnd,exonCount,exonStarts,exonEnds,geneName,count,uid --max-zoom 18 -i count --importance --reverse-importance --max-entries-per-tile 16 $INPUT_FILE 

    #rsync -a --delete blank/ $OUTPUT_DIR; mkdir -p $OUTPUT_DIR; /usr/bin/time python scripts/make_tiles.py -o $OUTPUT_DIR -v count --position genomeTxStart --end-position genomeTxEnd  -c refseqid,chr,strand,txStart,txEnd,genomeTxStart,genomeTxEnd,cdsStart,cdsEnd,exonCount,exonStarts,exonEnds,geneName,count,uid --max-zoom 5 -i count --importance --reverse-importance --max-entries-per-tile 16 $INPUT_FILE 
    #rsync -avzP $OUTPUT_DIR/ ~/projects/goomba/.tmp/jsons/${DATASET_NAME}

    #aws s3 sync $OUTPUT_DIR s3://pkerp/$OUTPUT_PART
    #aws s3 sync $OUTPUT_DIR s3://pkerp/$OUTPUT_PART

##########################################################################################
## Wiggle Tracks from
## BEDGraph files
##########################################################################################

DATASET_NAME=hg19/E116-DNase.fc.signal.bigwig
FILENAME=ENCODE/${DATASET_NAME}
FILEPATH=~/data/${FILENAME}

#bigWigToBedGraph ${FILEPATH} ${FILEPATH}.bedGraph     # 60 seconds
#cat ${FILEPATH}.bedGraph | awk '{print $1,$2,$1,$3,$4}' | chr_pos_to_genome_pos.py -e 4 > ${FILEPATH}.bedGraph.genome
head -n 1000000 ${FILEPATH}.bedGraph.genome > ${FILEPATH}.short

SPARK_HOME_DIR=~/spark-home

OUTPUT_DIR=${FILEPATH}.short.tiles; rsync -a --delete blank/ $OUTPUT_DIR; mkdir -p $OUTPUT_DIR; /usr/bin/time ${SPARK_HOME_DIR}/bin/spark-submit scripts/make_tiles.py -v value -c pos1,pos2,value --position pos1 --range pos1,pos2 --range-except-0 value -i value --resolution 1 --bins-per-dimension 64 --max-zoom 20 --use-spark  ${FILEPATH}.short -o $OUTPUT_DIR

aws s3 sync $OUTPUT_DIR s3://pkerp/data/served/$DATASET_NAME

#OUTPUT_DIR=${FILEPATH}.short.tiles; rsync -a --delete blank/ $OUTPUT_DIR; mkdir -p $OUTPUT_DIR; /usr/bin/time ${SPARK_HOME_DIR}/bin/spark-submit scripts/make_tiles.py -v value -c chrom,pos1,pos2,value --position pos1 --range pos1,pos2 -i value --resolution 1 --bins-per-dimension 64 --max-zoom 20 --use-spark  ${FILEPATH}.short --elasticsearch-nodes localhost:9200  --elasticsearch-path test_short/bed

            SPARK_HOME_DIR=~/spark-home
            DATASET_NAME=sample_data/E116-DNase.fc.signal.bigwig.bedGraph.genome.100000
            FILEPATH=test/${DATASET_NAME}
            OUTPUT_DIR=${FILEPATH}.tiles; rsync -a --delete blank/ $OUTPUT_DIR; mkdir -p $OUTPUT_DIR; /usr/bin/time ${SPARK_HOME_DIR}/bin/spark-submit scripts/make_tiles.py -v value -c pos1,pos2,value --position pos1 --range pos1,pos2 --range-except-0 value -i value --resolution 1 --bins-per-dimension 64 --max-zoom 5 --use-spark  ${FILEPATH} -o $OUTPUT_DIR

            rsync -avzP $OUTPUT_DIR/ ~/projects/goomba/.tmp/jsons/${DATASET_NAME}

            #aws s3 sync $OUTPUT_DIR s3://pkerp/data/served/${DATASET_NAME}.tiles

## Small file

OUTPUT_DIR=output
rsync -a --delete blank/ $OUTPUT_DIR; mkdir -p $OUTPUT_DIR;
python scripts/make_tiles.py -o $OUTPUT_DIR -v value -c chrom,pos1,pos2,value --range pos1,pos2 -i value test/data/smallBedGraph.tsv --delimiter ' ' --position pos1 --resolution 1 --max-zoom 14 --output-format dense --bins-per-dimension 128

### Real file

OUTPUT_DIR=~/data/ENCODE/2016-05-16-GM12878-RNASeq/tiles

/usr/bin/time spark-submit --driver-memory 8G scripts/make_tiles.py -o $OUTPUT_DIR -v value -c chrom,pos1,pos2,value --range pos1,pos2 -i value --position pos1 --resolution 1 --max-zoom 14 --output-format dense --bins-per-dimension 128 ~/data/ENCODE/2016-05-16-GM12878-RNASeq/ENCFF000FAA_chr1.bedGraph --use-spark
aws s3 sync --region us-west-2 $OUTPUT_DIR s3://pkerp/data/ENCODE/2016-05-16-GM12878-RNASeq/tiles

## BAM files

samtools view -h  data/bam/GM12878_SRR1658581_10pc_3_R1_hg19.bwt2glob.bam | head -n 65536 | samtools view -Sb > data/bam/65536.bam

#### 

Turn off logging in log4j.properties. Place the log4j.properties file in ~/.spark-conf and point spark to that directory:

export SPARK_CONF_DIR=~/.spark-conf

#### Create ElasticSearch mapping

curl -XGET "http://127.0.0.1:9200/test_short/_optimize"
curl -XGET "http://127.0.0.1:9200/test_short/_mapping"
curl -XGET "http://127.0.0.1:9200/test_short/_stats"

curl -XDELETE "http://search-es4dn-z7rzz4kevtoyh5pfjkmjg5jsga.us-east-1.es.amazonaws.com/hg19/Dixon2015-H1hESC_ES-HindIII-allreps-filtered.1kb.genome.gz.mirrored.shuffled/"
curl -XGET "http://search-es4dn-z7rzz4kevtoyh5pfjkmjg5jsga.us-east-1.es.amazonaws.com/hg19/Dixon2015-H1hESC_ES-HindIII-allreps-filtered.1kb.genome.gz.mirrored.shuffled/14.21.12077"

curl -XGET "search-es4dn-z7rzz4kevtoyh5pfjkmjg5jsga.us-east-1.es.amazonaws.com/hg19/Dixon2015-H1hESC_ES-HindIII-allreps-filtered.1kb.genome.gz.mirrored.shuffled/_search" -d '
{
    "query" : {
        "match_all" : {}
    }
}'

curl -XDELETE "http://127.0.0.1:9200/hg19"
curl -XPUT "localhost:9200/hg19" -d '
curl -XDELETE "search-es4dn-z7rzz4kevtoyh5pfjkmjg5jsga.us-east-1.es.amazonaws.com/hg19"
curl -XPUT "search-es4dn-z7rzz4kevtoyh5pfjkmjg5jsga.us-east-1.es.amazonaws.com/hg19" -d '
{
  "mappings": {
    "_default_": {
        "dynamic_templates": [
            { "notanalyzed": {
                  "match":              "*", 
                  "mapping": {
                      "index":       "no"
                  }
               }
            }
          ]
       }
   }
}'


#########################################################################################
#### Preparing test data
###########################################################################################

head -n 20212 ~/data/ENCODE/hg19/E116-DNase.fc.signal.bigwig.bedGraph.genome > test/sample_data/E116-DNase.fc.signal.bigwig.bedGraph.genome.20212
head -n 100000 ~/data/ENCODE/hg19/E116-DNase.fc.signal.bigwig.bedGraph.genome > test/sample_data/E116-DNase.fc.signal.bigwig.bedGraph.genome.100000
