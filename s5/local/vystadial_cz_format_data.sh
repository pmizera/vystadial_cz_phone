#!/bin/bash

. ./path.sh || exit 1;

echo "Preparing train, dev and test data"
srcdir=lang_prep/local/data
lmdir=lang_prep/local/nist_lm_phone
tmpdir=lang_prep/local/lm_tmp_phone
lexicon=lang_prep/local/dict_phone/lexicon.txt
mkdir -p $tmpdir

echo Preparing language models for test

for lm_suffix in phone_bg; do
  test=lang_prep/lang_${lm_suffix}
  mkdir -p $test
  cp -r lang_prep/lang_${lm_suffix}/* $test
  
  gunzip -c $lmdir/lm_${lm_suffix}.arpa.gz | \
    egrep -v '<s> <s>|</s> <s>|</s> </s>' | \
    arpa2fst - | fstprint | \
    utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$test/words.txt \
     --osymbols=$test/words.txt  --keep_isymbols=false --keep_osymbols=false | \
    fstrmepsilon | fstarcsort --sort_type=ilabel > $test/G.fst
  fstisstochastic $test/G.fst
 # The output is like:
 # 9.14233e-05 -0.259833
 # we do expect the first of these 2 numbers to be close to zero (the second is
 # nonzero because the backoff weights make the states sum to >1).
 # Because of the <s> fiasco for these particular LMs, the first number is not
 # as close to zero as it could be.

 # Everything below is only for diagnostic.
 # Checking that G has no cycles with empty words on them (e.g. <s>, </s>);
 # this might cause determinization failure of CLG.
 # #0 is treated as an empty word.
  mkdir -p $tmpdir/g
  awk '{if(NF==1){ printf("0 0 %s %s\n", $1,$1); }} END{print "0 0 #0 #0"; print "0";}' \
    < "$lexicon"  >$tmpdir/g/select_empty.fst.txt
  fstcompile --isymbols=$test/words.txt --osymbols=$test/words.txt $tmpdir/g/select_empty.fst.txt | \
   fstarcsort --sort_type=olabel | fstcompose - $test/G.fst > $tmpdir/g/empty_words.fst
  fstinfo $tmpdir/g/empty_words.fst | grep cyclic | grep -w 'y' && 
    echo "Language model has cycles with empty words" && exit 1
  rm -r $tmpdir/g
done

utils/validate_lang.pl lang_prep/lang_${lm_suffix} || exit 1

echo "Succeeded in formatting data."
rm -r $tmpdir
