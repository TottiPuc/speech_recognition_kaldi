#!/bin/bash

. ./cmd.sh 

################  llamada de datos  ##########################
wsj0=$1
tipo=1
wavscp=data/test_eval92_5k
camino=/home/totti/Documentos/aurora/ESTIMADOS/auroraINMMASKSNR
#camino=/home/totti/Documentos/aurora/auroraCorrupted8kHz/Test

#ruido=auroraComplete8kHz/Test

for RUIDO in 'airport' 'babble' 'car' 'street' 'train' 'restaurant'; do
	echo "processing noise_"$RUIDO
	for VAR in 0 5 10 15; do

	ruido=${RUIDO}/${VAR}dB
	echo "processing noise in db_"$ruido

#############################################################

## FIRST TEST TO TEST SYSTEM
	mfccdir=/home/totti/kaldi/egs/wsj/s5/data/kaldi_wsj_mfcc
	rm $mfccdir/raw_mfcc_test_eval92_5k* $mfccdir/cmvn_test_eval92_5k* $wavscp/wav.scp
	./make_list.sh $camino/$ruido $wavscp   # escogemos la pasta que queresmos testar /home/totti/Documentos/aurora/airport/0dB

#############################################################

	steps/make_mfcc.sh  data/test_eval92_5k exp/make_mfcc/test_eval92_5k $mfccdir || exit 1;
	steps/compute_cmvn_stats.sh data/test_eval92_5k exp/make_mfcc/test_eval92_5k $mfccdir


	if [ $tipo -le 0 ]; then
	utils/mkgraph.sh data/lang_nosp_test_tgpr exp/tri4a exp/tri4a/graph_nosp_tgpr || exit 1;
	steps/decode_fmllr.sh --nj 4 --cmd "$decode_cmd" \
	  exp/tri4a/graph_nosp_tgpr data/test_eval92_5k \
	  exp/tri4a/decode_nosp_tgpr_eval92_5k || exit 1;
	fi
	echo '=============================' 
	echo "processing noise in dB_"$ruido
	echo '============================='
	if [ $tipo -le 1 ]; then
	./dnn_test.sh
	fi
	mkdir -p resultados/$ruido
	mv exp/dnn5b_pretrain-dbn_dnn_smbr/decode_nosp_tgpr_eval92_5k_it* resultados/$ruido
	done

done
