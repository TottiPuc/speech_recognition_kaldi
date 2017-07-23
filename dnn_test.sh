#!/bin/bash

# Copyright 2012-2014  Brno University of Technology (Author: Karel Vesely)
# Apache 2.0

# This example script trains a DNN on top of fMLLR features.
# The training is done in 3 stages,
#
# 1) RBM pre-training:
#    in this unsupervised stage we train stack of RBMs,
#    a good starting point for frame cross-entropy trainig.
# 2) frame cross-entropy training:
#    the objective is to classify frames to correct pdfs.
# 3) sequence-training optimizing sMBR:
#    the objective is to emphasize state-sequences with better
#    frame accuracy w.r.t. reference alignment.


. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)

# Config:
gmmdir=exp/tri4a
data_fmllr=data-fmllr-tri4a
stage=0 # resume training with --stage=N
# End of config.
. utils/parse_options.sh || exit 1;



if [ $stage -le 0 ]; then
  # Store fMLLR features, so we can train on them easily,
  # test_eval92
  dir=$data_fmllr/test_eval92_5k
  steps/nnet/make_fmllr_feats.sh --nj 8 --cmd "$train_cmd" \
     --transform-dir $gmmdir/decode_nosp_tgpr_eval92_5k \
     $dir data/test_eval92_5k $gmmdir $dir/log $dir/data || exit 1
fi


#if [ $stage -le 1 ]; then
#  dir=exp/dnn5b_pretrain-dbn_dnn
#  ali=${gmmdir}_ali_si84
#  feature_transform=exp/dnn5b_pretrain-dbn/final.feature_transform
#  dbn=exp/dnn5b_pretrain-dbn/6.dbn
#  (tail --pid=$$ -F $dir/log/train_nnet.log 2>/dev/null)& # forward log

  # Decode (reuse HCLG graph)
#  steps/nnet/decode.sh --nj 8 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.1 \
#    $gmmdir/graph_nosp_tgpr $data_fmllr/test_eval92_5k $dir/decode_nosp_tgpr_eval92_5k || exit 1;
#fi


dir=exp/dnn5b_pretrain-dbn_dnn_smbr
srcdir=exp/dnn5b_pretrain-dbn_dnn
acwt=0.1

if [ $stage -le 2 ]; then
  # Decode (reuse HCLG graph)
  for ITER in 5 4 3 1; do
    steps/nnet/decode.sh --nj 8 --cmd "$decode_cmd" --config conf/decode_dnn.config \
      --nnet $dir/${ITER}.nnet --acwt $acwt \
      $gmmdir/graph_nosp_tgpr $data_fmllr/test_eval92_5k $dir/decode_nosp_tgpr_eval92_5k_it${ITER} || exit 1;
  done
fi

# Getting results [see RESULTS file]
# for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done





