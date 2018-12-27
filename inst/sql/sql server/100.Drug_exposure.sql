/**************************************
 --encoding : UTF-8
 --Author: �̼���
 --Date: 2018.09.11
 
@NHISNSC_rawdata : DB containing NHIS National Sample cohort DB
@NHISNSC_database: DB for NHIS-NSC in CDM format
@NHIS_JK: JK table in NHIS NSC
@NHIS_20T: 20 table in NHIS NSC
@NHIS_30T: 30 table in NHIS NSC
@NHIS_40T: 40 table in NHIS NSC
@NHIS_60T: 60 table in NHIS NSC
@NHIS_GJ: GJ table in NHIS NSC
@CONDITION_MAPPINGTABLE : mapping table between KCD and OMOP vocabulary
@DRUG_MAPPINGTABLE : mapping table between EDI and OMOP vocabulary
 
 --Description: Drug_exposure ���̺� ����
			   * 30T(����), 60T(ó����) ���̺��� ���� ETL�� �����ؾ� ��
 --Generating Table: DRUG_EXPOSURE
***************************************/

/**************************************
 1. ���� �غ�
***************************************/ 
-- 1) 30T�� ��/�� �ڵ� ��Ȳ üũ����
select clause_cd, item_cd, count(clause_cd)
from @NHISNSC_rawdata.@NHIS_30T
group by clause_cd, item_cd
--> ����� "08. ����) 30T, 60T�� �ڵ� �м�.xlsx" ����


-- 2) 30T�� ���Ŀ� �� ���� ������ ���ռ� üũ
-- 1�� ������ �Ǵ� �ǽ� Ƚ��
select dd_mqty_exec_freq, count(dd_mqty_exec_freq) as cnt
from @NHISNSC_rawdata.@NHIS_30T
where dd_mqty_exec_freq is not null and ISNUMERIC(dd_mqty_exec_freq) = 0
group by dd_mqty_exec_freq


-- �������ϼ� �Ǵ� �ǽ�Ƚ��
select mdcn_exec_freq, count(mdcn_exec_freq) as cnt
from @NHISNSC_rawdata.@NHIS_30T
where mdcn_exec_freq is not null and ISNUMERIC(mdcn_exec_freq) = 0
group by mdcn_exec_freq


-- 1ȸ ���෮
select dd_mqty_freq, count(dd_mqty_freq) as cnt
from @NHISNSC_rawdata.@NHIS_30T
where dd_mqty_freq is not null and ISNUMERIC(dd_mqty_freq) = 0
group by dd_mqty_freq
--> ����� "08. ����) 30T, 60T�� �ڵ� �м�.xlsx" ����


-- 3) 60T�� ���Ŀ� �� ���� ������ ���ռ� üũ
-- 1ȸ ���෮
select dd_mqty_freq, count(dd_mqty_freq) as cnt
from @NHISNSC_rawdata.@NHIS_60T
where dd_mqty_freq is not null and ISNUMERIC(dd_mqty_freq) = 0
group by dd_mqty_freq

-- 1�� ���෮
select dd_exec_freq, count(dd_exec_freq) as cnt
from @NHISNSC_rawdata.@NHIS_60T
where dd_exec_freq is not null and ISNUMERIC(dd_exec_freq) = 0
group by dd_exec_freq

-- �������ϼ� �Ǵ� �ǽ�Ƚ��
select mdcn_exec_freq, count(mdcn_exec_freq) as cnt
from @NHISNSC_rawdata.@NHIS_60T
where mdcn_exec_freq is not null and ISNUMERIC(mdcn_exec_freq) = 0
group by mdcn_exec_freq
--> ����� "08. ����) 30T, 60T�� �ڵ� �м�.xlsx" ����


-- 4) ���� ���̺��� ���ڵ� 1:N �Ǽ� üũ
select source_code, count(source_code)
from   (select source_code from @NHISNSC_database.@source_to_concept_map where domain_id='Drug' and invalid_reason is null) a
group by source_code
having count(source_code)>1
--> 1:N ���� ���ڵ� ����


--�� ���̳� �þ�� ����
--30T
select count(*) from @NHISNSC_rawdata.@NHIS_30T
where div_cd in (select source_code
				from   (select source_code from @NHISNSC_database.@source_to_concept_map where domain_id='Drug' and invalid_reason is null) a
				group by source_code
				having count(source_code)>1)
--60T
select count(*) from @NHISNSC_rawdata.@NHIS_60T
where div_cd in (select source_code
				from   (select source_code from @NHISNSC_database.@source_to_concept_map where domain_id='Drug' and invalid_reason is null) a
				group by source_code
				having count(source_code)>1)

--����ΰǼ� �ľ�
--30T
select count(*) from @NHISNSC_rawdata.@NHIS_30T
where DIV_CD not in (
select DIV_CD from @NHISNSC_rawdata.@NHIS_30T a, (select * from @NHISNSC_database.@source_to_concept_map where domain_id='drug' and invalid_reason is null) b
where a.DIV_CD=b.source_code
)

--60T
select count(*) from @NHISNSC_rawdata.@NHIS_60T
where DIV_CD not in (
select DIV_CD from @NHISNSC_rawdata.@NHIS_60T a, (select * from @NHISNSC_database.@source_to_concept_map where domain_id='drug' and invalid_reason is null) b
where a.DIV_CD=b.source_code
)


-- 5) ��ȯ ���� �Ǽ� �ľ�
--30T�� ��ȯ���� �Ǽ�
select count(a.key_seq)
from @NHISNSC_rawdata.@NHIS_30T a, 
	(select source_code
	from @NHISNSC_database.@source_to_concept_map
	where domain_id='drug' and invalid_reason is null ) as b, 
	@NHISNSC_rawdata.NHID_GY20_T1 c
where a.div_cd=b.source_code
and a.key_seq=c.key_seq

--60T�� ��ȯ���� �Ǽ�
select count(a.key_seq)
from @NHISNSC_rawdata.@NHIS_60T a, 
	(select source_code
	from @NHISNSC_database.@source_to_concept_map 
	where domain_id='drug' and invalid_reason is null) b, 
	@NHISNSC_rawdata.NHID_GY20_T1 c
where a.div_cd=b.source_code
and a.key_seq=c.key_seq


/**************************************
 1.1. drug_exposure_end_date ��� ����� ���ϱ� ���� ������ ������ (2017.02.17 by ������)
***************************************/ 
-- observation period ���� ���� �Ǽ�
select a.person_id, a.drug_exposure_id, a.drug_exposure_start_date, a.drug_exposure_end_date, b.observation_period_start_date, b.observation_period_end_date, c.death_date
from @NHISNSC_database.drug_exposure a, @NHISNSC_database.observation_period b, @NHISNSC_database.DEATH C
where a.person_id=b.person_id
and a.person_id = c.person_id
and (a.drug_exposure_start_date < b.observation_period_start_date
or a.drug_exposure_end_date > b.observation_period_end_date)

select b.concept_name, x.*
from 
(select A.*, B.target_concept_id
from @NHISNSC_rawdata.@NHIS_30T AS A
join( select * from @NHISNSC_database.@source_to_concept_map where domain_id='drug') as B
on A.div_cd=b.source_code 
   where cast(DD_MQTY_EXEC_FREQ as float)<1
   and cast(DD_MQTY_EXEC_FREQ as float)>=0) x
   join @NHISNSC_database.concept b
   on x.target_concept_id= b.concept_id

select b.concept_name, x.*
from 
(select A.*, B.target_concept_id
from @NHISNSC_rawdata.@NHIS_30T AS A
join (select * from @NHISNSC_database.@source_to_concept_map where domain_id='drug') as B
on A.div_cd=b.source_code 
   where cast(DD_MQTY_EXEC_FREQ as float)>1) x
   join @NHISNSC_database.CONCEPT b
   on x.target_concept_id= b.concept_id


select b.concept_name, x.*
from 
(select A.*, B.target_concept_id
from @NHISNSC_rawdata.@NHIS_60T AS A
join (select * from @NHISNSC_database.@source_to_concept_map where domain_id='drug') as B
on A.div_cd=b.source_code 
   where cast(DD_MQTY_FREQ as float)>1) x
   join @NHISNSC_database.concept b
   on x.target_concept_id= b.concept_id

 

/**************************************
 2. ���̺� ����
***************************************/  
/*
CREATE TABLE @NHISNSC_database.DRUG_EXPOSURE ( 
     drug_exposure_id				BIGINT	 	NOT NULL , 
     person_id						INTEGER			NOT NULL , 
     drug_concept_id				INTEGER			NULL , 
     drug_exposure_start_date		DATE			NOT NULL , 
     drug_exposure_end_date			DATE			NULL , 
     drug_type_concept_id			INTEGER			NOT NULL , 
     stop_reason					VARCHAR(20)		NULL , 
     refills						INTEGER			NULL , 
     quantity						FLOAT			NULL , 
     days_supply					INTEGER			NULL , 
     sig							VARCHAR(MAX)	NULL , 
	 route_concept_id				INTEGER			NULL ,
	 effective_drug_dose			FLOAT			NULL ,
	 dose_unit_concept_id			INTEGER			NULL ,
	 lot_number						VARCHAR(50)		NULL ,
     provider_id					INTEGER			NULL , 
     visit_occurrence_id			BIGINT			NULL , 
     drug_source_value				VARCHAR(50)		NULL ,
	 drug_source_concept_id			INTEGER			NULL ,
	 route_source_value				VARCHAR(50)		NULL ,
	 dose_unit_source_value			VARCHAR(50)		NULL
    );
*/	

/**************************************
 3. 30T�� �̿��Ͽ� ������ �Է�
***************************************/  
insert into @NHISNSC_database.DRUG_EXPOSURE 
(drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, 
drug_type_concept_id, stop_reason, refills, quantity, days_supply, 
sig, route_concept_id, effective_drug_dose, dose_unit_concept_id, lot_number,
provider_id, visit_occurrence_id, drug_source_value, drug_source_concept_id, route_source_value, 
dose_unit_source_value)
SELECT convert(bigint, convert(varchar, a.master_seq) + convert(varchar, row_number() over (partition by a.key_seq, a.seq_no order by b.target_concept_id))) as drug_exposure_id,
	a.person_id as person_id,
	b.target_concept_id as drug_concept_id,
	CONVERT(date, a.recu_fr_dt, 112) as drug_exposure_start_date,
	--DATEADD(day, CEILING(convert(float, a.mdcn_exec_freq)/convert(float, a.dd_mqty_exec_freq))-1, convert(date, a.recu_fr_dt, 112)) as drug_exposure_end_date, (����: 2017.02.17 by �̼���)
	DATEADD(day, convert(float, a.mdcn_exec_freq)-1, convert(date, a.recu_fr_dt, 112)) as drug_exposure_end_date,
	case when a.FORM_CD in ('02', '2', '04', '06', '10', '12') then 38000180 
		when a.FORM_CD not in ('02', '2', '04', '06', '10', '12') then 581452 
		end as drug_type_concept_id, 
	NULL as stop_reason,
	NULL as refills,
	convert(float, a.dd_mqty_exec_freq) * convert(float, a.mdcn_exec_freq) * convert(float, a.dd_mqty_freq) as quantity,
	a.mdcn_exec_freq as days_supply,
	a.clause_cd as sig,
	CASE 
		WHEN a.clause_cd='03' and a.item_cd='01' then 4128794 -- oral
		WHEN a.clause_cd='03' and a.item_cd='02' then 45956875 -- not applicable
		WHEN a.clause_cd='04' and a.item_cd='01' then 4139962 -- Subcutaneous
		WHEN a.clause_cd='04' and a.item_cd='02' then 4112421 -- intravenous
		WHEN a.clause_cd='04' and a.item_cd='03' then 4112421
		ELSE 0
	END as route_concept_id,
	NULL as effective_drug_dose,
	NULL as dose_unit_concept_id,
	NULL as lot_number,
	NULL as provider_id,
	a.key_seq as visit_occurrence_id,
	a.div_cd as drug_source_value,
	null as drug_source_concept_id,
	a.clause_cd + '/' + a.item_cd as route_source_value,
	NULL as dose_unit_source_value
FROM 
	(SELECt x.key_seq, x.seq_no, x.recu_fr_dt, x.div_cd,
			case when x.mdcn_exec_freq is not null and isnumeric(x.mdcn_exec_freq)=1 and cast(x.mdcn_exec_freq as float) > '0' then cast(x.mdcn_exec_freq as float) else 1 end as mdcn_exec_freq,
			case when x.dd_mqty_exec_freq is not null and isnumeric(x.dd_mqty_exec_freq)=1 and cast(x.dd_mqty_exec_freq as float) > '0' then cast(x.dd_mqty_exec_freq as float) else 1 end as dd_mqty_exec_freq,
			case when x.dd_mqty_freq is not null and isnumeric(x.dd_mqty_freq)=1 and cast(x.dd_mqty_freq as float) > '0' then cast(x.dd_mqty_freq as float) else 1 end as dd_mqty_freq,
			case when x.clause_cd is not null and len(x.clause_cd) = 1 and isnumeric(x.clause_cd)=1 and convert(int, x.clause_cd) between 1 and 9 then '0' + x.clause_cd else x.clause_cd end as clause_cd,
			case when x.item_cd is not null and len(x.item_cd) = 1 and isnumeric(x.item_cd)=1 and convert(int, x.item_cd) between 1 and 9 then '0' + x.item_cd else x.item_cd end as item_cd,
			y.master_seq, y.person_id			
	FROM @NHISNSC_rawdata.@NHIS_30T x, 
	     (select master_seq, person_id, key_seq, seq_no from @NHISNSC_database.SEQ_MASTER where source_Table='130') y
		, (select form_cd, KEY_SEQ, PERSON_ID from @NHISNSC_rawdata.@NHIS_20T) z
	WHERE x.key_seq=y.key_seq
	AND x.seq_no=y.seq_no
	and y.key_seq=z.KEY_SEQ
	and y.person_id=z.PERSON_ID	) a,
	(select * from @NHISNSC_database.@source_to_concept_map where domain_id='Drug' and invalid_reason is null) b
where a.div_cd=b.source_code
;

/**************************************
 4. 60T�� �̿��Ͽ� ������ �Է�
***************************************/
insert into @NHISNSC_database.DRUG_EXPOSURE 
(drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, 
drug_type_concept_id, stop_reason, refills, quantity, days_supply, 
sig, route_concept_id, effective_drug_dose, dose_unit_concept_id, lot_number,
provider_id, visit_occurrence_id, drug_source_value, drug_source_concept_id, route_source_value, 
dose_unit_source_value)
SELECT convert(bigint, convert(varchar, a.master_seq) + convert(varchar, row_number() over (partition by a.key_seq, a.seq_no order by b.target_concept_id))) as drug_exposure_id,
	a.person_id as person_id,
	b.target_concept_id as drug_concept_id,
	CONVERT(date, a.recu_fr_dt, 112) as drug_exposure_start_date,
	-- DATEADD(day, CEILING(convert(float, a.mdcn_exec_freq)/convert(float, a.dd_exec_freq))-1, convert(date, a.recu_fr_dt, 112)) as drug_exposure_end_date, (����: 2017.02.17 by �̼���)
	DATEADD(day, convert(float, a.mdcn_exec_freq)-1, convert(date, a.recu_fr_dt, 112)) as drug_exposure_end_date,
	case when a.FORM_CD in ('02', '2', '04', '06', '10', '12') then 38000180 
		when a.FORM_CD not in ('02', '2', '04', '06', '10', '12') then 581452 
		end as drug_type_concept_id, 
	NULL as stop_reason,
	NULL as refills,
	convert(float, a.dd_mqty_freq) * convert(float, a.dd_exec_freq) * convert(float, a.mdcn_exec_freq) as quantity,
	a.mdcn_exec_freq as days_supply,
	null as sig,
	null as route_concept_id,
	NULL as effective_drug_dose,
	NULL as dose_unit_concept_id,
	NULL as lot_number,
	NULL as provider_id,
	a.key_seq as visit_occurrence_id,
	a.div_cd as drug_source_value,
	null as drug_source_concept_id,
	null as route_source_value,
	NULL as dose_unit_source_value
FROM 
	(SELECt x.key_seq, x.seq_no, x.recu_fr_dt, x.div_cd,
			case when x.mdcn_exec_freq is not null and isnumeric(x.mdcn_exec_freq)=1 and cast(x.mdcn_exec_freq as float) > '0' then cast(x.mdcn_exec_freq as float) else 1 end as mdcn_exec_freq,
			case when x.dd_mqty_freq is not null and isnumeric(x.dd_mqty_freq)=1 and cast(x.dd_mqty_freq as float) > '0' then cast(x.dd_mqty_freq as float) else 1 end as dd_mqty_freq,
			case when x.dd_exec_freq is not null and isnumeric(x.dd_exec_freq)=1 and cast(x.dd_exec_freq as float) > '0' then cast(x.dd_exec_freq as float) else 1 end as dd_exec_freq,
			y.master_seq, y.person_id			
	FROM @NHISNSC_rawdata.@NHIS_60T x, 
	     (select master_seq, person_id, key_seq, seq_no from @NHISNSC_database.SEQ_MASTER where source_Table='160') y
	, (select form_cd, KEY_SEQ, PERSON_ID from @NHISNSC_rawdata.@NHIS_20T) z
	WHERE x.key_seq=y.key_seq
	AND x.seq_no=y.seq_no
	and y.key_seq=z.KEY_SEQ
	and y.person_id=z.PERSON_ID	) a,
	(select * from @NHISNSC_database.@source_to_concept_map where domain_id='Drug' and invalid_reason is null) b
where a.div_cd=b.source_code
;


/**************************************
 5. drug_start_date�� ������� ������ ������ ����
***************************************/
delete from a 
from @NHISNSC_database.DRUG_EXPOSURE a, @NHISNSC_database.death b
where a.person_id=b.person_id
and b.death_date < a.drug_exposure_start_date



/**************************************
 6. drug_end_date�� �������� ������ �������� drug_end_date�� ������ڷ� ����
***************************************/
update a
set drug_exposure_end_date=b.death_date
from @NHISNSC_database.DRUG_EXPOSURE a, @NHISNSC_database.DEATH b
where a.person_id=b.person_id
and (b.death_date < a.drug_exposure_start_date
or b.death_date < a.drug_exposure_end_date)


-------------------------------------------
����) http://tennesseewaltz.tistory.com/236
UPDATE A
      SET A.SEQ     = B.CMT_NO
        , A.CarType = B.CAR_TYPE
     FROM TABLE_AAA A
          JOIN TABLE_BBB B ON A.OPCode = B.OP_CODE
    WHERE A.LineCode = '����'
-------------------------------------------