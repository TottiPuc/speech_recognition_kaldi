#!/bin/bash

. ./cmd.sh

wsj0=/home/totti/Documentos/Aurora/LDC93S6B

local/wsj_data_prep.sh $wsj0/??-{?,??}.?  || exit 1;

local/wsj_prepare_dict.sh --dict-suffix "_nosp" || exit 1;

utils/prepare_lang.sh data/local/dict_nosp \
  "<SPOKEN_NOISE>" data/local/lang_tmp_nosp data/lang_nosp || exit 1;

local/wsj_format_data.sh --lang-suffix "_nosp" || exit 1;

#<============================================================================#
# Now make MFCC features.
# mfccdir should be some place with a largish disk where you
# want to store MFCC features.

#============================================================================#
mfccdir=/home/totti/kaldi/egs/wsj/s5/data/kaldi_wsj_mfcc
mkdir $mfccdir

steps/make_mfcc.sh  data/train_si84 exp/make_mfcc/train_si84 $mfccdir  || exit 1;
steps/compute_cmvn_stats.sh data/train_si84 exp/make_mfcc/train_si84 $mfccdir || exit 1;

# Now make subset with the shortest 2k utterances from si-84.
utils/subset_data_dir.sh --shortest data/train_si84 2000 data/train_si84_2kshort || exit 1;

# Now make subset with half of the data from si-84.
utils/subset_data_dir.sh data/train_si84 3500 data/train_si84_half || exit 1;

#=============================================================================#

# Note: the --boost-silence option should probably be omitted by default
# for normal setups.  It doesn't always help. [it's to discourage non-silence
# models from modeling silence.]

# TRAIN MONOPHONES
steps/train_mono.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
  data/train_si84_2kshort data/lang_nosp exp/mono0a || exit 1;

# ALIGN MONOPHONES
steps/align_si.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
  data/train_si84_half data/lang_nosp exp/mono0a exp/mono0a_ali || exit 1;

# TRAIN DELTA TRIPHONES
steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 2000 10000 \
  data/train_si84_half data/lang_nosp exp/mono0a_ali exp/tri1 || exit 1;

# THAT PART OF COD IS IMPORTANT or the mono mkgraph.sh might be writing
# data/lang_test_tgpr/tmp/LG.fst which will cause this to fail.
#while [ ! -f data/lang_nosp_test_tgpr/tmp/LG.fst ] || \
#   [ -z data/lang_nosp_test_tgpr/tmp/LG.fst ]; do
#  sleep 20;
#done
sleep 30;


## the following command demonstrates how to get lattices that are
## "word-aligned" (arcs coincide with words, with boundaries in the right
## place).
sil_label=`grep '!SIL' data/lang_nosp_test_tgpr/words.txt | awk '{print $2}'`

# ALIGN DELTA TRIPHONES
steps/align_si.sh --nj 10 --cmd "$train_cmd" \
  data/train_si84 data/lang_nosp exp/tri1 exp/tri1_ali_si84 || exit 1;

#TRAIN LDA +MLLT TRIPHONES
steps/train_lda_mllt.sh --cmd "$train_cmd" \
  --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
  data/train_si84 data/lang_nosp exp/tri1_ali_si84 exp/tri2b || exit 1;

# ALIGN LDS+MLLT TRIPHONES
steps/align_si.sh  --nj 10 --cmd "$train_cmd" \
  --use-graphs true data/train_si84 \
  data/lang_nosp exp/tri2b exp/tri2b_ali_si84  || exit 1;

# TRAIN SAT TRIPHONES
steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
  data/train_si84 data/lang_nosp exp/tri2b_ali_si84 exp/tri3b || exit 1;

# From 3b system, align all si284 data.ALIGN SAT TRIPHONES WITH FMLLR
steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" \
  data/train_si84 data/lang_nosp exp/tri3b exp/tri3b_ali_si84 || exit 1;

# From 3b system, train another SAT system (tri4a) with all the si284 data.

steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 \
  data/train_si84 data/lang_nosp exp/tri3b_ali_si84 exp/tri4a || exit 1;

# Silprob for normal lexicon.
steps/get_prons.sh --cmd "$train_cmd" \
  data/train_si84 data/lang_nosp exp/tri4a || exit 1;
utils/dict_dir_add_pronprobs.sh --max-normalize true \
  data/local/dict_nosp \
  exp/tri4a/pron_counts_nowb.txt exp/tri4a/sil_counts_nowb.txt \
  exp/tri4a/pron_bigram_counts_nowb.txt data/local/dict || exit 1

utils/prepare_lang.sh data/local/dict \
  "<SPOKEN_NOISE>" data/local/lang_tmp data/lang || exit 1;

for lm_suffix in bg bg_5k tg tg_5k tgpr tgpr_5k; do
  mkdir -p data/lang_test_${lm_suffix}
  cp -r data/lang/* data/lang_test_${lm_suffix}/ || exit 1;
  rm -rf data/lang_test_${lm_suffix}/tmp
  cp data/lang_nosp_test_${lm_suffix}/G.* data/lang_test_${lm_suffix}/
done

# Train and test MMI, and boosted MMI, on tri4b (LDA+MLLT+SAT on
# all the data).  Use 30 jobs.
steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
  data/train_si84 data/lang exp/tri4a exp/tri4a_ali_si84 || exit 1;

################  para treinamento com dnn modelo hibrido #############

local/nnet/run_dnn.sh

######################################################################




























