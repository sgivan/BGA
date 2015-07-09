CREATE TABLE funcat (
	icon text,
	definition text,
	name text,
	parent_funcat int,
	PRIMARY KEY (id),
	id int NOT NULL
	);
CREATE TABLE orf_annotations (
	orf_id int,
	annotation_id int
	);
CREATE TABLE contig (
	name char(50),
	length int,
	loverlap int,
	lneighbor_id int,
	sequence mediumtext,
	roverlap int,
	rneighbor_id int,
	PRIMARY KEY (id),
	id int NOT NULL
	);
CREATE UNIQUE INDEX contig_name_key ON contig (name);
CREATE TABLE annotator (
	name char(20),
	description text,
	PRIMARY KEY (id),
	id int NOT NULL
	);
CREATE UNIQUE INDEX annotator_name_key ON annotator (name);
CREATE TABLE orf (
	molweight float,
	contig_id int,
	startcodon char(3),
	name char(50),
	alt_names text,
	status int,
	stop int,
	ag int,
	gc int,
	frame int,
	isoelp float,
	PRIMARY KEY (id),
	id int NOT NULL,
	start int
	);
CREATE UNIQUE INDEX orf_name_key ON orf (name);
CREATE TABLE orfstate (
	tool_id int,
	date_ordered int,
	date_done int,
	orf_id int,
	PRIMARY KEY (id),
	id int NOT NULL
	);
CREATE TABLE orf_names (
	name char(50),
	orf_id int,
	PRIMARY KEY (id),
	id int NOT NULL
	);
CREATE UNIQUE INDEX orf_names_name_key ON orf_names (name);
CREATE TABLE annotation_facts (
	fact_id int,
	annotation_id int
	);
CREATE TABLE annotation (
	product char(100),
	name char(50),
	annotator_id int,
	comment text,
	orf_id int,
	description text,
	offset int,
	ec text,
	feature_type int,
	PRIMARY KEY (id),
	id int NOT NULL,
	category int,
	date int,
	tool_id tinyint
	);
CREATE TABLE feature (
	contig_id int,
	name text,
	subfeature_id int,
	type int,
	orf_id int,
	end int,
	fact_id int,
	next_feature int,
	xml_data text,
	PRIMARY KEY (id),
	id int NOT NULL,
	start int
	);
CREATE TABLE feature_type (
	icon text,
	definition text,
	name text,
	xml_dtd text,
	PRIMARY KEY (id),
	id int NOT NULL,
	parent_feature_type int
	);
CREATE TABLE tool (
	input_type int,
	name char(20),
	executable_name text,
	description text,
	dbname text,
	dburl text,
	cost int,
	number int,
	level1 text,
	level2 text,
	helper_package text,
	level3 text,
	user_value int,
	level4 text,
	level5 text,
	PRIMARY KEY (id),
	id int NOT NULL
	);
CREATE UNIQUE INDEX tool_name_key ON tool (name);
CREATE TABLE fact (
	dbto int,
	tool_id int,
	orfto int,
	dbfrom int,
	orffrom int,
	dbref text,
	orf_id int,
	description text,
	toolresult text,
	PRIMARY KEY (id),
	id int NOT NULL,
	information int
	);
CREATE TABLE GENDB_counters (
	object char(30),
	val int);
INSERT INTO GENDB_counters (object, val) VALUES ('funcat', 0);
INSERT INTO GENDB_counters (object, val) VALUES ('contig', 0);
INSERT INTO GENDB_counters (object, val) VALUES ('annotator', 0);
INSERT INTO GENDB_counters (object, val) VALUES ('orf', 0);
INSERT INTO GENDB_counters (object, val) VALUES ('orfstate', 0);
INSERT INTO GENDB_counters (object, val) VALUES ('orf_names', 0);
INSERT INTO GENDB_counters (object, val) VALUES ('annotation', 0);
INSERT INTO GENDB_counters (object, val) VALUES ('feature', 0);
INSERT INTO GENDB_counters (object, val) VALUES ('feature_type', 0);
INSERT INTO GENDB_counters (object, val) VALUES ('tool', 0);
INSERT INTO GENDB_counters (object, val) VALUES ('fact', 0);
CREATE TABLE gene_ontology (
    ID int(10),
    orf_id int(10),
    auto_pfamA int(5),
    go_id tinytext,
    term longtext,
    category tinytext
);
