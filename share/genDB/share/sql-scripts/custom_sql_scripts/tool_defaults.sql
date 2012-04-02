
INSERT INTO `tool` VALUES (
'1',
'BLASTP-KEGG',
'/home/sgivan/projects/BGA/share/genDB/bin/blast2p',
'BLASTP of KEGG',
'kegg',
'www.kegg.com/dbget-bin/www_bget?',
NULL,
1,
'1E-50',
'1E-40',
'blast_helper',
'1E-30',
NULL,
'1E-20',
'1E-10',
1
);

INSERT INTO `tool` VALUES (
'1',
'BLASTP-swissprot',
'/home/sgivan/projects/BGA/share/genDB/bin/blast2p',
'BLASTP of Swissprot',
'swissprot',
'expasy.org/uniprot/',
NULL,
2,
'1E-50',
'1E-40',
'blast_helper',
'1E-30',
NULL,
'1E-20',
'1E-10',
2
);

INSERT INTO `tool` VALUES (
'1',
'Pfam',
NULL,
'HMM Search of Pfam',
'/dbase/PFAM/Pfam-A',
'pfam.janelia.org/family?entry=',
NULL,
3,
'1E-30',
'1E-20',
'pfam_helper',
'1E-10',
NULL,
'1E-5',
'1E-3',
3
);


INSERT INTO `tool` VALUES (
'1',
'tmhmm',
NULL,
'HMM prediction of TM domains',
NULL,
NULL,
NULL,
4,
NULL,
NULL,
'tmhmm_helper',
NULL,
NULL,
NULL,
NULL,
4
);

update `GENDB_counters` set `val` = 4 where `object` = 'tool';

# also the following line is unnessary,
# it is added as a template for further entries...
# remember to increas val according to the number of 
# elements in annotator table.....
update GENDB_counters set val=5 where object='annotator';
