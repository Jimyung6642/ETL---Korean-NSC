/**************************************
 --encoding : UTF-8
 --Author: ������
 --Date: 2018.09.12
 
 @NHISNSC_rawdata: DB containing NHIS National Sample cohort DB
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
 @DEVICE_MAPPINGTABLE : mapping table between EDI and OMOP vocabulary
 
 --Description: device ���̺� ����
			   1) device_exposure_end_date�� drug_exposure�� end_date�� ���� ������� ����
			   2) quantity�� ��� �ܰ�(UN_COST) Ȥ�� �ݾ�(AMT)�� �������̰ų�, ��뷮(DD_MQTY_EXEC_FREQ, MDCN_EXEC_FREQ, DD_MQTY_FREQ)�� �������� ��찡 ����,
				  ������ �ƴ� ��찡 ����(�޵����� �߶� ���� ��� ��) 
					1. �ܰ�(UN_COST)�� �ݾ�(AMT)�� ������ ��� (Null�� �ƴϰų� 0���� �ƴ� ���) AMT/UN_COST
					2. �ܰ�(UN_COST)�� �ݾ�(AMT)�� ������ �ƴ� ���(0, Null, UN_COST>AMT) 30t�� ��� ��뷮(DD_MQTY_EXEC_FREQ, MDCN_EXEC_FREQ, DD_MQTY_FREQ)�� ������,
					   60t�� ��� ��뷮 (DD_EXEC_FREQ, MDCN_EXEC_FREQ, DD_MQTY_FREQ)�� ������ ���
					3. �ܰ�, �ݾ�, ��뷮 ��� ������(0�� ���)�� ��� 1�� ����
 --Generating Table: Device_exposure
***************************************/

/**************************************
 1. ���̺� ���� 
***************************************/ 
 
/*
CREATE TABLE @NHISNSC_database.DEVICE_EXPOSURE ( 
     device_exposure_id				BIGINT	 		PRIMARY KEY , 
     person_id						INTEGER			NOT NULL , 
     divce_concept_id				INTEGER			NOT NULL , 
     device_exposure_start_date		DATE			NOT NULL , 
     device_exposure_end_date		DATE			NULL , 
     device_type_concept_id			INTEGER			NOT NULL , 
     unique_device_id				VARCHAR(20)		NULL , 
     quantity						float			NULL , 
     provider_id					INTEGER			NULL , 
     visit_occurrence_id			BIGINT			NULL , 
	 device_source_value			VARCHAR(50)		NULL ,
	 device_source_concept_id		integer			NULL 
    );
*/
/**************************************
 2. ������ �Է� �� Ȯ��
***************************************/  

--30t �Է� 
insert into @NHISNSC_database.DEVICE_EXPOSURE
(device_exposure_id, person_id, divce_concept_id, device_exposure_start_date, 
device_exposure_end_date, device_type_concept_id, unique_device_id, quantity, 
provider_id, visit_occurrence_id, device_source_value, device_source_concept_id)
select  convert(bigint, convert(varchar, a.master_seq) + convert(varchar, row_number() over (partition by a.key_seq, a.seq_no order by b.target_concept_id))) as device_exposure_id,
		a.person_id as person_id,
		b.target_concept_id as device_concept_id ,
		CONVERT(VARCHAR, a.recu_fr_dt, 23) as device_source_start_date,
		CONVERT(VARCHAR, DATEADD(DAY, a.mdcn_exec_freq-1, a.recu_fr_dt),23) as device_source_end_date,
		44818705 as device_type_concept_id,
		null as unique_device_id,
case	when a.AMT is not null and cast(a.AMT as float) > 0 and a.UN_COST is not null and cast(a.UN_COST as float) > 0 and cast(a.AMT as float)>=cast(a.UN_COST as float) then cast(a.AMT as float)/cast(a.UN_COST as float)
		when a.AMT is not null and cast(a.AMT as float) > 0 and a.UN_COST is not null and cast(a.UN_COST as float) > 0 and cast(a.UN_COST as float)>cast(a.AMT as float) then a.DD_MQTY_EXEC_FREQ * a.MDCN_EXEC_FREQ * a.DD_MQTY_FREQ 
		else a.DD_MQTY_EXEC_FREQ * a.MDCN_EXEC_FREQ * a.DD_MQTY_FREQ 
		end as quantity,
		null as provider_id,
		a.key_seq as visit_occurence_id,
		a.div_cd as device_source_value,
		null as device_source_concept_id

FROM 
	(SELECT x.key_seq, x.seq_no, x.recu_fr_dt, x.div_cd, 
			case when x.mdcn_exec_freq is not null and x.mdcn_exec_freq > '0' and isnumeric(x.mdcn_exec_freq)=1 then cast(x.mdcn_exec_freq as float) else 1 end as mdcn_exec_freq,
			case when x.dd_mqty_exec_freq is not null and x.dd_mqty_exec_freq > '0' and isnumeric(x.dd_mqty_exec_freq)=1 then cast(x.dd_mqty_exec_freq as float) else 1 end as dd_mqty_exec_freq,
			case when x.dd_mqty_freq is not null and x.dd_mqty_freq > '0' and isnumeric(x.dd_mqty_freq)=1 then cast(x.dd_mqty_freq as float) else 1 end as dd_mqty_freq,
			cast(x.amt as float) as amt , cast(x.un_cost as float) as un_cost, y.master_seq, y.person_id
	FROM @NHISNSC_rawdata.@NHIS_30T x, @NHISNSC_database.SEQ_MASTER y
	WHERE y.source_table='130'
	AND x.key_seq=y.key_seq
	AND x.seq_no=y.seq_no) a JOIN (select * from @NHISNSC_database.@SOURCE_TO_CONCEPT_MAP where domain_id='device' and invalid_reason is null) b 
ON a.div_cd=b.source_code
;

--60t �Է� 
insert into @NHISNSC_database.DEVICE_EXPOSURE
(device_exposure_id, person_id, divce_concept_id, device_exposure_start_date, 
device_exposure_end_date, device_type_concept_id, unique_device_id, quantity, 
provider_id, visit_occurrence_id, device_source_value, device_source_concept_id)
select 	convert(bigint, convert(varchar, a.master_seq) + convert(varchar, row_number() over (partition by a.key_seq, a.seq_no order by b.target_concept_id))) as device_exposure_id,
		a.person_id as person_id,
		b.target_concept_id as device_concept_id ,
		CONVERT(VARCHAR, a.recu_fr_dt, 23) as device_source_start_date,
		CONVERT(VARCHAR, DATEADD(DAY, a.mdcn_exec_freq-1, a.recu_fr_dt),23) as device_source_end_date,
		44818705 as device_type_concept_id,
		null as unique_device_id,
case	when a.AMT is not null and cast(a.AMT as float) > 0 and a.UN_COST is not null and cast(a.UN_COST as float) > 0 and cast(a.AMT as float)>=cast(a.UN_COST as float) then cast(a.AMT as float)/cast(a.UN_COST as float)
		when a.AMT is not null and cast(a.AMT as float) > 0 and a.UN_COST is not null and cast(a.UN_COST as float) > 0 and cast(a.UN_COST as float)>cast(a.AMT as float) then a.MDCN_EXEC_FREQ * a.DD_MQTY_FREQ * a.DD_EXEC_FREQ
		else a.MDCN_EXEC_FREQ * a.DD_MQTY_FREQ * a.DD_EXEC_FREQ
		end as quantity,
		null as provider_id,
		a.key_seq as visit_occurence_id,
		a.div_cd as device_source_value,
		null as device_source_concept_id

FROM 
	(SELECT x.key_seq, x.seq_no, x.recu_fr_dt, x.div_cd, 
			case when x.mdcn_exec_freq is not null and x.mdcn_exec_freq > '0' and isnumeric(x.mdcn_exec_freq)=1 then cast(x.mdcn_exec_freq as float) else 1 end as mdcn_exec_freq,
			case when x.dd_mqty_freq is not null and x.dd_mqty_freq > '0' and isnumeric(x.dd_mqty_freq)=1 then cast(x.dd_mqty_freq as float) else 1 end as dd_mqty_freq,
			case when x.dd_exec_freq is not null and x.dd_exec_freq > '0' and isnumeric(x.dd_exec_freq)=1 then cast(x.dd_exec_freq as float) else 1 end as dd_exec_freq,
			cast(x.amt as float) as amt , cast(x.un_cost as float) as un_cost, y.master_seq, y.person_id
	FROM @NHISNSC_rawdata.@NHIS_60T x, @NHISNSC_database.SEQ_MASTER y
	WHERE y.source_table='160'
	AND x.key_seq=y.key_seq
	AND x.seq_no=y.seq_no) a JOIN (select * from @NHISNSC_database.@SOURCE_TO_CONCEPT_MAP where domain_id='device' and invalid_reason is null) b
ON a.div_cd=b.source_code
;

-- quantity�� 0�� ��� 1�� ���� 
update @NHISNSC_database.DEVICE_EXPOSURE
set quantity = 1
where quantity = 0
;


/******************* quantity 0�� ��� 1�� �����ϱ� �� ��� Ȯ��*********************
select * from @ResultDatabaseSchema.device_exposure where quantity=0 -- ���� �� -> 6268(���Ƴ���ġħ5275��) / ���� �� -> 0
select * from @ResultDatabaseSchema.device_exposure where quantity=1 -- ���� �� -> 4548117 / ���� �� -> 4554385
*************************************************************************************/
