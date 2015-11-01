#!/bin/bash

LMs=$1; shift
test_sets=$1; shift

 # Create the text_phones files with transcription on the level of phones
 cut -f2- -d' ' $WORK/train/text | sed "s/\t/ /" |  grep -v '_' | \
 perl local/phonetic_transcription_cs.pl | \
 sed "s/       /\t/" | cut -f2- | sed -e 's:^:_SIL_ :' -e 's:$: _SIL_:' > $WORK/train/text_phones_a
 cut -f1 -d' ' $WORK/train/text |  grep -v '_' > $WORK/train/text_phones_b
 paste $WORK/train/text_phones_b $WORK/train/text_phones_a | sed "s/\t/ /" > $WORK/train/text_phones
 rm $WORK/train/text_phones_*

 for s in $test_sets ; do
    for lm in $LMs; do
        tgt_dir=$WORK/${s}_`basename ${lm}`
        cut -f2- -d' ' $WORK/local/$s/trans.txt | sed "s/\t/ /" |  grep -v '_' | \
        perl local/phonetic_transcription_cs.pl | \
        sed "s/       /\t/" | cut -f2- | sed -e 's:^:_SIL_ :' -e 's:$: _SIL_:' >  $WORK/local/$s/text_phones_a
        cat $WORK/local/$s/trans.txt |  grep -v '_' | cut -f1 -d' ' > $WORK/local/$s/text_phones_b
        paste  $WORK/local/$s/text_phones_b $WORK/local/$s/text_phones_a | sed "s/\t/ /" > $WORK/local/$s/text_phones
        rm $WORK/local/$s/text_phones_*
    done
 done

