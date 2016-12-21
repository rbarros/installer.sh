#!/bin/sh
#
# Identificação dos arquivos
IDENTIFICA=backup

# Numero de dias do ciclo de backup
DIAS=-5

# Onde os arquivos de backup e logs ficarão armazenados
DIR_DESTINO=/backup

# Formato da data
DATA=$(date +%d-%m-%Y-%H-%a)

# Origem do backup
ORIGEM=/publica

DESTINO=$DIR_DESTINO/$IDENTIFICA-$DATA

echo "Iniciado backup $DESTINO ..."
df -h > $DESTINO.log
find $ORIGEM -mtime $DIAS -type f -exec tar -rvf $DESTINO.tar "{}" \; && sudo gzip -f $DESTINO.tar
df -h >> $DESTINO.log
echo "Finalizado backup $DESTINO ..."

