# MySQL dump 8.10
#
# Host: dbhost    Database: gendb
#--------------------------------------------------------
# Server version	3.23.27-beta-log

#
# Dumping data for table 'feature_type'
#

INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'misc_feature ',NULL,1,0);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'misc_difference ',NULL,2,1);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'conflict ',NULL,3,2);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'unsure ',NULL,4,2);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'old_sequence ',NULL,5,2);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'variation ',NULL,6,2);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'modified_base ',NULL,7,2);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'gene ',NULL,8,1);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'misc_signal ',NULL,9,1);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'promoter ',NULL,10,9);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'CAAT_signal ',NULL,11,10);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'TATA_signal ',NULL,12,10);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'-35_signal ',NULL,13,10);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'-10_signal ',NULL,14,10);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'GC_signal ',NULL,15,10);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'RBS ',NULL,16,9);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'polyA_signal ',NULL,17,9);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'enhancer ',NULL,18,9);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'attenuator ',NULL,19,9);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'terminator ',NULL,20,9);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'rep_origin ',NULL,21,9);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'misc_RNA ',NULL,22,1);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'prim_transcript ',NULL,23,22);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'precursor_RNA ',NULL,24,23);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'mRNA ',NULL,25,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'5\'clip ',NULL,26,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'3\'clip ',NULL,27,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'5\'UTR ',NULL,28,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'3\'UTR ',NULL,29,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'exon ',NULL,30,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'CDS ',NULL,31,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'sig_peptide ',NULL,32,31);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'transit_peptide ',NULL,33,31);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'mat_peptide ',NULL,34,31);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'intron ',NULL,35,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'polyA_site ',NULL,36,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'rRNA ',NULL,37,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'tRNA ',NULL,38,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'scRNA ',NULL,39,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'snRNA ',NULL,40,24);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'immunoglobulin_related ',NULL,41,0);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'C_region ',NULL,42,41);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'D_segment ',NULL,43,41);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'J_segment ',NULL,44,41);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'N_region ',NULL,45,41);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'S_region ',NULL,46,41);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'V_region ',NULL,47,41);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'V_segment ',NULL,48,41);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'repeat_region ',NULL,49,0);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'repeat_unit ',NULL,50,49);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'LTR ',NULL,51,49);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'satellite ',NULL,52,49);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'misc_binding ',NULL,53,0);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'primer_bind ',NULL,54,53);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'protein_bind ',NULL,55,53);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'STS ',NULL,56,53);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'misc_recomb ',NULL,57,0);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'iDNA ',NULL,58,57);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'misc_structure ',NULL,59,0);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'stem_loop ',NULL,60,59);
INSERT INTO feature_type (icon, definition, name, xml_dtd, id, parent_feature_type) VALUES (NULL,NULL,'D-loop ',NULL,61,59);

