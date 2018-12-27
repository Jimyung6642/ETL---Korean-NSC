/**************************************
 --encoding : UTF-8
 --Author: �̼���
 --Date: 2018.09.12
 
 @NHISNSC_rawdata : DB containing NHIS National Sample cohort DB
 @NHISNSC_database : DB for NHIS-NSC in CDM format
 @NHIS_JK: JK table in NHIS NSC
 @NHIS_20T: 20 table in NHIS NSC
 @NHIS_30T: 30 table in NHIS NSC
 @NHIS_40T: 40 table in NHIS NSC
 @NHIS_60T: 60 table in NHIS NSC
 @NHIS_GJ: GJ table in NHIS NSC
 @CONDITION_MAPPINGTABLE : mapping table between KCD and OMOP vocabulary
 @DRUG_MAPPINGTABLE : mapping table between EDI and OMOP vocabulary
 @PROCEDURE_MAPPINGTABLE : mapping table between Korean procedure and OMOP vocabulary
 
 --Description: Procedure_occurrence ���̺� ����
			   * 30T(����), 60T(ó����) ���̺��� ���� ETL�� �����ؾ� ��
 --Generating Table: PROCEDURE_OCCURRENCE
***************************************/

/**************************************
 1. ��ȯ ������ �Ǽ� �ľ�
***************************************/ 
-- 30T ��ȯ ���� �Ǽ�(1:N ���� ���)
select count(a.key_seq)
from @NHISNSC_rawdata.@NHIS_30T a, (select * from @NHISNSC_database.@source_to_concept_map where domain_id='procedure' and invalid_reason is null) b, @NHISNSC_rawdata.@NHIS_20T c
where a.div_cd=b.source_code
and a.key_seq=c.key_seq

-- ����) 30T ��ȯ ���� �Ǽ� (distinct �� ī��Ʈ)
select count(a.key_seq)
from @NHISNSC_rawdata.@NHIS_30T a, @NHISNSC_rawdata.@NHIS_20T b
where a.key_seq=b.key_seq
and a.div_cd in (select distinct c.source_code
	from (select * from @NHISNSC_database.@source_to_concept_map where domain_id='procedure' and invalid_reason is null) as c)
	
-- ����) 30T �� 1:N ���� �ߺ� �Ǽ�
select count(a.key_seq), sum(cnt)
from @NHISNSC_rawdata.@NHIS_30T a, 
	(select source_code, count(source_code)-1 as cnt 
	from (select * from @NHISNSC_database.@source_to_concept_map where domain_id='procedure' and invalid_reason is null) as c
	group by source_code 
	having count(source_code) > 1) b
where a.div_cd=b.source_code


----------------------------------------
-- 60T ��ȯ ���� �Ǽ�(1:N ���� ���)
select count(a.key_seq)
from @NHISNSC_rawdata.@NHIS_60T a, (select * from @NHISNSC_database.@source_to_concept_map where domain_id='procedure' and invalid_reason is null) b, @NHISNSC_rawdata.@NHIS_20T c
where a.div_cd=b.source_code
and a.key_seq=c.key_seq

-- ����) 60T ��ȯ ���� �Ǽ� (distinct �� ī��Ʈ)
select count(a.key_seq)
from @NHISNSC_rawdata.@NHIS_60T a, @NHISNSC_rawdata.@NHIS_20T b
where a.key_seq=b.key_seq
and a.div_cd in (select distinct source_code
	from (select * from @NHISNSC_database.@source_to_concept_map where domain_id='procedure' and invalid_reason is null) as c)

-- ����) 60T �� 1:N ���� �ߺ� �Ǽ�
select count(a.key_seq), sum(cnt)
from @NHISNSC_rawdata.@NHIS_60T a, 
	(select source_code, count(source_code)-1 as cnt 
	from (select * from @NHISNSC_database.@source_to_concept_map where domain_id='procedure' and invalid_reason is null) as m
	group by source_code 
	having count(source_code) > 1) b,
	@NHISNSC_rawdata.@NHIS_20T c
where a.div_cd=b.source_code
and a.key_seq=c.key_seq



/**************************************
 2. ���̺� ����
***************************************/ 
/*
CREATE TABLE @NHISNSC_database.PROCEDURE_OCCURRENCE ( 
     procedure_occurrence_id		BIGINT			PRIMARY KEY, 
     person_id						INTEGER			NOT NULL, 
     procedure_concept_id			INTEGER			NOT NULL, 
     procedure_date					DATE			NOT NULL, 
     procedure_type_concept_id		INTEGER			NOT NULL,
	 modifier_concept_id			INTEGER			NULL,
	 quantity						INTEGER			NULL, 
     provider_id					INTEGER			NULL, 
     visit_occurrence_id			BIGINT			NULL, 
     procedure_source_value			VARCHAR(50)		NULL,
	 procedure_source_concept_id	INTEGER			NULL,
	 qualifier_source_value			VARCHAR(50)		NULL
    )
;
*/
/**************************************
 3. 30T�� �̿��Ͽ� ������ �Է�
***************************************/
INSERT INTO @NHISNSC_database.PROCEDURE_OCCURRENCE 
	(procedure_occurrence_id, person_id, procedure_concept_id, procedure_date, procedure_type_concept_id, 
	modifier_concept_id, quantity, provider_id, visit_occurrence_id, procedure_source_value, 
	procedure_source_concept_id, qualifier_source_value)
SELECT
	convert(bigint, convert(varchar, a.master_seq) + convert(varchar, row_number() over (partition by a.key_seq, a.seq_no order by b.target_concept_id))) as procedure_occurrence_id,
	a.person_id as person_id,
	CASE WHEN b.target_concept_id IS NOT NULL THEN b.target_concept_id ELSE 0 END as procedure_concept_id,
	CONVERT(VARCHAR, a.recu_fr_dt, 112) as procedure_date,
	45756900 as procedure_type_concept_id,
	NULL as modifier_concept_id,
	convert(float, a.dd_mqty_exec_freq) * convert(float, a.mdcn_exec_freq) * convert(float, a.dd_mqty_freq) as quantity,
	NULL as provider_id,
	a.key_seq as visit_occurrence_id,
	a.div_cd as procedure_source_value,
	null as procedure_source_concept_id,
	null as qualifier_source_value
FROM (SELECt x.key_seq, x.seq_no, x.recu_fr_dt, x.div_cd, 
			case when x.mdcn_exec_freq is not null and isnumeric(x.mdcn_exec_freq)=1 and cast(x.mdcn_exec_freq as float) > '0' then cast(x.mdcn_exec_freq as float) else 1 end as mdcn_exec_freq,
			case when x.dd_mqty_exec_freq is not null and isnumeric(x.dd_mqty_exec_freq)=1 and cast(x.dd_mqty_exec_freq as float) > '0' then cast(x.dd_mqty_exec_freq as float) else 1 end as dd_mqty_exec_freq,
			case when x.dd_mqty_freq is not null and isnumeric(x.dd_mqty_freq)=1 and cast(x.dd_mqty_freq as float) > '0' then cast(x.dd_mqty_freq as float) else 1 end as dd_mqty_freq,
			y.master_seq, y.person_id
	FROM @NHISNSC_rawdata.@NHIS_30T x, 
		 (select master_seq, key_seq, seq_no, person_id from @NHISNSC_database.SEQ_MASTER where source_table='130') y
	WHERE x.key_seq=y.key_seq
	AND x.seq_no=y.seq_no) a, (select * from @NHISNSC_database.@source_to_concept_map where domain_id='procedure' and invalid_reason is null) b
WHERE a.div_cd=b.source_code


/**************************************
 4. 60T�� �̿��Ͽ� ������ �Է�
***************************************/
INSERT INTO @NHISNSC_database.PROCEDURE_OCCURRENCE 
	(procedure_occurrence_id, person_id, procedure_concept_id, procedure_date, procedure_type_concept_id, 
	modifier_concept_id, quantity, provider_id, visit_occurrence_id, procedure_source_value, 
	procedure_source_concept_id, qualifier_source_value)
SELECT 
	convert(bigint, convert(varchar, a.master_seq) + convert(varchar, row_number() over (partition by a.key_seq, a.seq_no order by b.target_concept_id))) as procedure_occurrence_id,
	a.person_id as person_id,
	CASE WHEN b.target_concept_id IS NOT NULL THEN b.target_concept_id ELSE 0 END as procedure_concept_id,
	CONVERT(VARCHAR, a.recu_fr_dt, 112) as procedure_date,
	45756900 as procedure_type_concept_id,
	NULL as modifier_concept_id,
	convert(float, a.dd_mqty_freq) * convert(float, a.dd_exec_freq) * convert(float, a.mdcn_exec_freq) as quantity,
	NULL as provider_id,
	a.key_seq as visit_occurrence_id,
	a.div_cd as procedure_source_value,
	null as procedure_source_concept_id,
	null as qualifier_source_value
FROM (SELECt x.key_seq, x.seq_no, x.recu_fr_dt, x.div_cd, 
			case when x.mdcn_exec_freq is not null and isnumeric(x.mdcn_exec_freq)=1 and cast(x.mdcn_exec_freq as float) > '0' then cast(x.mdcn_exec_freq as float) else 1 end as mdcn_exec_freq,
			case when x.dd_exec_freq is not null and isnumeric(x.dd_exec_freq)=1 and cast(x.dd_exec_freq as float) > '0' then cast(x.dd_exec_freq as float) else 1 end as dd_exec_freq,
			case when x.dd_mqty_freq is not null and isnumeric(x.dd_mqty_freq)=1 and cast(x.dd_mqty_freq as float) > '0' then cast(x.dd_mqty_freq as float) else 1 end as dd_mqty_freq,
			y.master_seq, y.person_id
	FROM @NHISNSC_rawdata.@NHIS_60T x, 
		 (select master_seq, key_seq, seq_no, person_id from @NHISNSC_database.SEQ_MASTER where source_table='160') y
	WHERE x.key_seq=y.key_seq
	AND x.seq_no=y.seq_no) a, (select * from @NHISNSC_database.@source_to_concept_map where domain_id='procedure' and invalid_reason is null) b
WHERE a.div_cd=b.source_code




