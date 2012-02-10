# Genetic codes available for codon usage calculations

package GENDB::Tools::Gen_Codes;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@EXPORT_OK = qw($complete_aminoacids $code_4);
$VERSION = 1.00;
1;

$complete_aminoacids = {"A" => ["GCA","GCG","GCT","GCC"],
			"C" => ["TGC","TGT"], 
			"D" => ["GAC","GAT"],
			"E" => ["GAA","GAG"],
			"F" => ["TTC","TTT"],
			"G" => ["GGA","GGC","GGG","GGT"],
			"H" => ["CAC","CAT"],
			"I" => ["ATA","ATC","ATT"],
			"K" => ["AAA","AAG"], 
			"L" => ["CTA","CTG","CTT","CTC","TTA","TTG"],
			"M" => ["ATG"],
			"N" => ["AAC","AAT"],
			"P" => ["CCA","CCG","CCT","CCC"],
			"Q" => ["CAA","CAG"],
			"R" => ["AGA","AGG","CGA","CGG","CGT","CGC"], 
			"S" => ["AGC","AGT","TCA","TCG","TCC","TCT"],
			"T" => ["ACA","ACG","ACT","ACC"],
			"V" => ["GTA","GTG","GTT","GTC"],
			"W" => ["TGG"],
			"Y" => ["TAC","TAT"],
			"*" => ["TAA","TAG","TGA"]};

$code_4 = {"A" => ["GCA","GCG","GCT","GCC"],
			"C" => ["TGC","TGT"], 
			"D" => ["GAC","GAT"],
			"E" => ["GAA","GAG"],
			"F" => ["TTC","TTT"],
			"G" => ["GGA","GGC","GGG","GGT"],
			"H" => ["CAC","CAT"],
			"I" => ["ATA","ATC","ATT"],
			"K" => ["AAA","AAG"], 
			"L" => ["CTA","CTG","CTT","CTC","TTA","TTG"],
			"M" => ["ATG"],
			"N" => ["AAC","AAT"],
			"P" => ["CCA","CCG","CCT","CCC"],
			"Q" => ["CAA","CAG"],
			"R" => ["AGA","AGG","CGA","CGG","CGT","CGC"], 
			"S" => ["AGC","AGT","TCA","TCG","TCC","TCT"],
			"T" => ["ACA","ACG","ACT","ACC"],
			"V" => ["GTA","GTG","GTT","GTC"],
			"W" => ["TGG","TGA"],
			"Y" => ["TAC","TAT"],
			"*" => ["TAA","TAG"]};
