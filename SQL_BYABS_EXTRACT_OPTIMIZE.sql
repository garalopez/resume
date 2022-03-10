USE [MeaningfulUse]
GO
/****** Object:  StoredProcedure [dbo].[extract]    Script Date: 7/24/2017 2:11:52 PM ******/
DECLARE
                -- Add the parameters for the stored procedure here
                @Facility varchar(3) = 'TRS', 
                @Begin datetime = '2018-06-01',
                @End datetime = '2018-06-01'


              
-------------------------------------------------------------------------
-------------------------------- QUERY LIST -----------------------------
-------------------------------------------------------------------------
DECLARE @query_list table (query varchar(max)) 
INSERT INTO @query_list values 
('ETHNICITY'),('DISCH.IAD'),('DISCH.PED'),('DISCH.RM'),('DISCH.SCP'),('EKG.INTERP'),('EKG.INTERPDATE'),('EKG.INTERPTIME'),
('GEN.AD'),('GEN.SMKST'),('PCOD'),('RACE'),('REGPORTAL'),('VS.BMI'),('VS.BP'),('VS.HEIGHT'),('VS.WEIGHT'),
--- STK queries ---
('AMI.CPR'),('AMI.CPRTIME'),('AMI.CPRDATE'),('AMI.NOASA1'),('AMI.NOASA2'),('AMI.NOFIBRIN1'),('AMI.NOSTATIN2'),('AMI.NOSTATINDC'),
('NIH.SCORE'),('OM.LIMIT6'),('QS4.ONSETD'),('QS4.ONSETT'),('QS4.ONSETU'),('QSTK.REANOANTIT'),('QV4.MONPRO'),('STK.ED'),('STK.EDNG1'),
('STK.INFO'),('STK.NOANTICOAG1'),('STK.NOANTITHR1'),('STK.NOTPA1'),('STK.REHAB'),('STK.REHABND'),('STK.SYMPTOMS'),
--- VTE queries ---
('OM.COMFORTCARE'),('QV0371.RLVL'),('QV4.MONPRO'),('VTE.ASSESS'),('VTE.DEVICE'),('VTE.ED'),('VTE.EDNG1'),('VTE.INFO'),('VTE.MECH2'),
('VTE.NONE'),('VTE.NONE1'),('VTE.NOOLT'),('VTE.NOOLTORDER'),('VTE.NOPROPHY1')

SELECT
'501332' as 'hospital.id',
CONVERT(varchar(8),CURRENT_TIMESTAMP,112) as 'document.date',
CONVERT(varchar(8),CURRENT_TIMESTAMP,108) as 'document.time',
(
SELECT
--------------------------------------------------------------------------
-------------------------------- ABS MAIN --------------------------------
--------------------------------------------------------------------------
(
SELECT

ABSPAT.AbstractStatusField as 'abs.status',
CONVERT(varchar(8), ABSPAT.AbstractStatusDateField, 112) AS 'abs.status.date',
ABSPAT.AbstractorField_UnvUserID AS 'abstractor',
ABSPAT.PatientClassField_AbsPatClassID as 'pt.status',
(SELECT MM.MappedTo 
                           FROM livendb.dbo.DMisMaps MM
                                     WHERE MM.MapID = 'ENCOUNTER' 
                                     AND MM.MappedFromID = ABSPAT.PatientClassField_AbsPatClassID) as 'encounter.status.code',
ABSPAT.VisitID as 'account.number',
(SELECT MM.MappedTo 
                  FROM livendb.dbo.DMisMaps MM
                           WHERE MM.MapID = 'QMDXDIS' 
                           AND MM.MappedFromID = ABSPAT.FinalDischargeDisposition_MisDischDisposID) as 'dis.disposition.code',
ABSVISIT.Expire48Hours as 'dis.expired.48hr',
(SELECT DMISDR.NationalProviderIdNumber
             FROM livendb.dbo.DMisProvider DMISDR
             WHERE DMISDR.ProviderID = ABSDR.AttendingProviderField_UnvUserID) as 'attending.provider.npi',
ABSDR.PrimaryCareProviderField_UnvUserID as 'primary.care.provider',
(SELECT DMISDR.NationalProviderIdNumber
             FROM livendb.dbo.DMisProvider DMISDR
             WHERE DMISDR.ProviderID = ABSDR.PrimaryCareProviderField_UnvUserID) as 'primary.care.provider.npi',
ABSDRG.DrgStatusField as 'drg.status',
ABSDRG.DrgAdmitting_MisDrgCmgID as 'drg.adm',
ABSDRG.DrgFinal_MisDrgCmgID as 'drg.final',
-------------diagnosises----------
(
SELECT 
CONVERT(varchar(8), ABSDX.DiagnosisEffectiveDateID, 112) as 'diagnosiseffectivedate',
ABSDX.DiagnosisCode_MisDxID as 'dx',
CASE
                WHEN ABSDX.SortOrder = '1' THEN 
                (SELECT MM.MappedTo 
                               FROM livendb.dbo.DMisMaps MM
                                            WHERE MM.MapID = 'PRINCIPAL' 
                                            AND MM.MappedFromID = '1')
END as 'principal.dx.code',

FROM livefdb.dbo.AbsAcct_Diagnoses ABSDX
WHERE ABSPAT.SourceID = ABSDX.SourceID
AND ABSPAT.VisitID = ABSDX.VisitID

FOR XML PATH ('dx'), TYPE
),

FOR XML path(''), ROOT('abs.pat.main'), TYPE
),

--------------------------------------------------------------------------
-------------------------------- ADM MAIN --------------------------------
--------------------------------------------------------------------------
(
SELECT 
ADMVS.VisitID as 'adm.urn', --admpat_visitid
ADMVS.PatientID as 'mri.urn', --PatientID
ADMVS.RoomID as 'room', --RoomID
MISACC.Name as 'accomodation', --MISACCName
ADMVS.BedID as 'bed', --BedID
CASE
WHEN ADMVS.InpatientOrOutpatient = 'I' THEN --InpatientOrOutpatient
(SELECT ADMVS.LocationID) END as 'inpatient.location', --LocationID
CASE
WHEN ADMVS.InpatientOrOutpatient = 'I' THEN --InpatientOrOutpatient
(SELECT MISLOCNOMEN.CodeID) END as 'inpatient.location.code', --CodeID
(
SELECT
ADMVSQ.QueryID as 'cd.query',
ADMVSQ.Response as 'cd.response',
NOMENQ.MisNomenclatureMapID as 'nomenclature.id',
CASE 
 WHEN NOMENQC.CodeSetID = 'SNOMED_CT'
 THEN NOMENQC.CodeID
END as 'SNOMED_CT',
CASE 
 WHEN NOMENQC.CodeSetID = 'SNOMED_CT_US'
 THEN NOMENQC.CodeID
END as 'SNOMED_CT_US',
CASE 
 WHEN NOMENQC.CodeSetID = 'RXNORM'
 THEN NOMENQC.CodeID
END as 'RXNORM',
CASE 
 WHEN NOMENQC.CodeSetID = 'ICD10'
 THEN NOMENQC.CodeID
END as 'ICD10',
CASE 
 WHEN NOMENQC.CodeSetID = 'ICD9'
 THEN NOMENQC.CodeID
END as 'ICD9',
CASE 
 WHEN NOMENQC.CodeSetID = 'LOINC'
 THEN NOMENQC.CodeID
END as 'LOINC',
CASE 
 WHEN NOMENQC.CodeSetID = 'CPT'
 THEN NOMENQC.CodeID
END as 'CPT',
(SELECT MM.MappedTo 
                                FROM livendb.dbo.DMisMaps MM
                                                WHERE MM.MapID = 'CQM.NEGATE' 
                                              AND MM.MappedFromID = ADMVSQ.QueryID) as 'mis.map.code',
NOMENQ.NomenclatureYesID as 'nomenclature.id.yes',
CASE 
 WHEN NOMENQCY.CodeSetID = 'SNOMED_CT'
 THEN NOMENQCY.CodeID
END as 'SNOMED_CT',
CASE 
 WHEN NOMENQCY.CodeSetID = 'SNOMED_CT_US'
 THEN NOMENQCY.CodeID
END as 'SNOMED_CT_US',
CASE 
 WHEN NOMENQCY.CodeSetID = 'RXNORM'
 THEN NOMENQCY.CodeID
END as 'RXNORM',
CASE 
 WHEN NOMENQCY.CodeSetID = 'ICD10'
 THEN NOMENQCY.CodeID
END as 'ICD10',
CASE 
 WHEN NOMENQCY.CodeSetID = 'ICD9'
 THEN NOMENQCY.CodeID
END as 'ICD9',
CASE 
 WHEN NOMENQCY.CodeSetID = 'LOINC'
 THEN NOMENQCY.CodeID
END as 'LOINC',
CASE 
 WHEN NOMENQCY.CodeSetID = 'CPT'
 THEN NOMENQCY.CodeID
END as 'CPT',
NOMENQ.NomenclatureNoID as 'nomenclature.id.no',
CASE 
 WHEN NOMENQCN.CodeSetID = 'SNOMED_CT'
 THEN NOMENQCN.CodeID
END as 'SNOMED_CT',
CASE 
 WHEN NOMENQCN.CodeSetID = 'SNOMED_CT_US'
 THEN NOMENQCN.CodeID
END as 'SNOMED_CT_US',
CASE 
 WHEN NOMENQCN.CodeSetID = 'RXNORM'
 THEN NOMENQCN.CodeID
END as 'RXNORM',
CASE 
 WHEN NOMENQCN.CodeSetID = 'ICD10'
 THEN NOMENQCN.CodeID
END as 'ICD10',
CASE 
 WHEN NOMENQCN.CodeSetID = 'ICD9'
 THEN NOMENQCN.CodeID
END as 'ICD9',
CASE 
 WHEN NOMENQCN.CodeSetID = 'LOINC'
 THEN NOMENQCN.CodeID
END as 'LOINC',
CASE 
 WHEN NOMENQCN.CodeSetID = 'CPT'
 THEN NOMENQCN.CodeID
END as 'CPT',
NOMENMQ.MisNomenclatureMapID as 'nomenclature.id.mult',
MISGRE.Name as 'cd.group.response',
MISXQM.SetID as 'x.query.map.system',
MISXQM.Code as 'x.query.map.code'

FROM livendb.dbo.AdmVisitQueries ADMVSQ

LEFT JOIN livendb.dbo.DMisQueries MISQ
ON ADMVSQ.QueryID = MISQ.QueryID
AND ADMVSQ.SourceID = MISQ.SourceID

LEFT JOIN livendb.dbo.DMisQueriesNomenclatureMaps NOMENQ
ON ADMVSQ.QueryID = NOMENQ.QueryID
AND ADMVSQ.SourceID = NOMENQ.SourceID

LEFT JOIN livendb.dbo.DMisQueriesNomenMapsMult NOMENMQ
ON ADMVSQ.QueryID = NOMENMQ.QueryID
AND ADMVSQ.SourceID = NOMENMQ.SourceID
AND ADMVSQ.Response = NOMENMQ.GroupResponseID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQC
ON NOMENQ.MisNomenclatureMapID = NOMENQC.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQC.SourceID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQCY
ON NOMENQ.NomenclatureYesID = NOMENQCY.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQCY.SourceID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQCN
ON NOMENQ.NomenclatureNoID = NOMENQCN.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQCN.SourceID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQCM
ON NOMENQ.MisNomenclatureMapID = NOMENQCM.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQCM.SourceID

LEFT JOIN livendb.dbo.DMisGroupResponseElements MISGRE
ON MISQ.GroupResponseID = MISGRE.GroupResponseID
AND ADMVSQ.Response = MISGRE.CodeID
AND ADMVSQ.SourceID = MISGRE.SourceID

LEFT JOIN livendb.dbo.DMisInfceQueryMapsEntryMaps MISXQM
ON ADMVSQ.QueryID = MISXQM.QueryID
AND ADMVSQ.SourceID = MISXQM.SourceID
AND ADMVSQ.Response = MISXQM.EntryID

WHERE ADMVS.SourceID = ADMVSQ.SourceID
AND ADMVS.VisitID = ADMVSQ.VisitID
AND ADMVSQ.QueryID IN (SELECT query FROM @query_list)

FOR XML PATH('customer.defined.queries'), TYPE
),
(
SELECT 
ADMVSCQ.QueryID as 'ccdqr.query',
ADMVSCQ.VisitID as 'visit.id',
ADMVSCQ.Response as 'ccdqr.response',
NOMENQ.MisNomenclatureMapID as 'nomenclature.id',
CASE 
 WHEN NOMENQC.CodeSetID = 'SNOMED_CT'
 THEN NOMENQC.CodeID
END as 'SNOMED_CT',
CASE 
 WHEN NOMENQC.CodeSetID = 'SNOMED_CT_US'
 THEN NOMENQC.CodeID
END as 'SNOMED_CT_US',
CASE 
 WHEN NOMENQC.CodeSetID = 'RXNORM'
 THEN NOMENQC.CodeID
END as 'RXNORM',
CASE 
 WHEN NOMENQC.CodeSetID = 'ICD10'
 THEN NOMENQC.CodeID
END as 'ICD10',
CASE 
 WHEN NOMENQC.CodeSetID = 'ICD9'
 THEN NOMENQC.CodeID
END as 'ICD9',
CASE 
 WHEN NOMENQC.CodeSetID = 'LOINC'
 THEN NOMENQC.CodeID
END as 'LOINC',
CASE 
 WHEN NOMENQC.CodeSetID = 'CPT'
 THEN NOMENQC.CodeID
END as 'CPT',
(SELECT MM.MappedTo 
                                FROM livendb.dbo.DMisMaps MM
                                                WHERE MM.MapID = 'CQM.NEGATE' 
                                              AND MM.MappedFromID = ADMVSCQ.QueryID) as 'mis.map.code',
NOMENQ.NomenclatureYesID as 'nomenclature.id.yes',
CASE 
 WHEN NOMENQCY.CodeSetID = 'SNOMED_CT'
 THEN NOMENQCY.CodeID
END as 'SNOMED_CT',
CASE 
 WHEN NOMENQCY.CodeSetID = 'SNOMED_CT_US'
 THEN NOMENQCY.CodeID
END as 'SNOMED_CT_US',
CASE 
 WHEN NOMENQCY.CodeSetID = 'RXNORM'
 THEN NOMENQCY.CodeID
END as 'RXNORM',
CASE 
 WHEN NOMENQCY.CodeSetID = 'ICD10'
 THEN NOMENQCY.CodeID
END as 'ICD10',
CASE 
 WHEN NOMENQCY.CodeSetID = 'ICD9'
 THEN NOMENQCY.CodeID
END as 'ICD9',
CASE 
 WHEN NOMENQCY.CodeSetID = 'LOINC'
 THEN NOMENQCY.CodeID
END as 'LOINC',
CASE 
 WHEN NOMENQCY.CodeSetID = 'CPT'
 THEN NOMENQCY.CodeID
END as 'CPT',
NOMENMQ.MisNomenclatureMapID as 'nomenclature.id.mult',
MISGRE.Name as 'cd.group.response',
MISXQM.SetID as 'x.query.map.system',
MISXQM.Code as 'x.query.map.code'


FROM livendb.dbo.AdmVisitClinicalQueries ADMVSCQ

LEFT JOIN livendb.dbo.DMisQueries MISQ
ON ADMVSCQ.QueryID = MISQ.QueryID
AND ADMVSCQ.SourceID = MISQ.SourceID

LEFT JOIN livendb.dbo.DMisQueriesNomenclatureMaps NOMENQ
ON ADMVSCQ.QueryID = NOMENQ.QueryID
AND ADMVSCQ.SourceID = NOMENQ.SourceID

LEFT JOIN livendb.dbo.DMisQueriesNomenMapsMult NOMENMQ
ON ADMVSCQ.QueryID = NOMENMQ.QueryID
AND ADMVSCQ.SourceID = NOMENMQ.SourceID
AND ADMVSCQ.Response = NOMENMQ.GroupResponseID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQC
ON NOMENQ.MisNomenclatureMapID = NOMENQC.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQC.SourceID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQCY
ON NOMENQ.NomenclatureYesID = NOMENQCY.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQCY.SourceID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQCN
ON NOMENQ.MisNomenclatureMapID = NOMENQCN.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQCN.SourceID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQCM
ON NOMENQ.NomenclatureNoID = NOMENQCM.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQCM.SourceID

LEFT JOIN livendb.dbo.DMisGroupResponseElements MISGRE
ON MISQ.GroupResponseID = MISGRE.GroupResponseID
AND ADMVSCQ.Response = MISGRE.CodeID
AND ADMVSCQ.SourceID = MISGRE.SourceID

LEFT JOIN livendb.dbo.DMisInfceQueryMapsEntryMaps MISXQM
ON ADMVSCQ.QueryID = MISXQM.QueryID
AND ADMVSCQ.SourceID = MISXQM.SourceID
AND ADMVSCQ.Response = MISXQM.EntryID

WHERE ADMVS.SourceID = ADMVSCQ.SourceID
AND ADMVS.VisitID = ADMVSCQ.VisitID
AND ADMVSCQ.QueryID IN (SELECT query FROM @query_list)

FOR XML PATH('adm.pat.ccdqr'),TYPE
),
(
SELECT 
ADMVSMCQ.MultCounter as 'ccdqr.mul.ctr',
CONVERT(varchar(8), ADMVSMCQ.DateTime,112) as 'ccdqr.mul.date',
ADMVSMCQ.Response as 'ccdqr.mul.response',
NOMENQ.MisNomenclatureMapID as 'nomenclature.id',
NOMENQ.NomenclatureYesID as 'nomenclature.id.yes',
NOMENMQ.MisNomenclatureMapID as 'nomenclature.id.mult',
MISGRE.Name as 'cd.group.response',
MISXQM.SetID as 'x.query.map.system',
MISXQM.Code as 'x.query.map.code'

FROM livendb.dbo.AdmVisitClinicalQueriesMult ADMVSMCQ

LEFT JOIN livendb.dbo.DMisQueries MISQ
ON ADMVSMCQ.QueryID = MISQ.QueryID
AND ADMVSMCQ.SourceID = MISQ.SourceID

LEFT JOIN livendb.dbo.DMisQueriesNomenclatureMaps NOMENQ
ON ADMVSMCQ.QueryID = NOMENQ.QueryID
AND ADMVSMCQ.SourceID = NOMENQ.SourceID

LEFT JOIN livendb.dbo.DMisQueriesNomenMapsMult NOMENMQ
ON ADMVSMCQ.QueryID = NOMENMQ.QueryID
AND ADMVSMCQ.SourceID = NOMENMQ.SourceID
AND ADMVSMCQ.Response = NOMENMQ.GroupResponseID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQC
ON NOMENQ.MisNomenclatureMapID = NOMENQC.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQC.SourceID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQCY
ON NOMENQ.NomenclatureYesID = NOMENQCY.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQCY.SourceID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQCN
ON NOMENQ.MisNomenclatureMapID = NOMENQCN.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQCN.SourceID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes NOMENQCM
ON NOMENQ.NomenclatureNoID = NOMENQCM.MisNomenclatureMapID
AND NOMENQ.SourceID = NOMENQCM.SourceID

LEFT JOIN livendb.dbo.DMisGroupResponseElements MISGRE
ON MISQ.GroupResponseID = MISGRE.GroupResponseID
AND ADMVSMCQ.Response = MISGRE.CodeID
AND ADMVSMCQ.SourceID = MISGRE.SourceID

LEFT JOIN livendb.dbo.DMisInfceQueryMapsEntryMaps MISXQM
ON ADMVSMCQ.QueryID = MISXQM.QueryID
AND ADMVSMCQ.SourceID = MISXQM.SourceID
AND ADMVSMCQ.Response = MISXQM.EntryID


WHERE  ADMVS.SourceID = ADMVSMCQ.SourceID
AND ADMVS.VisitID = ADMVSMCQ.VisitID
AND ADMVSMCQ.QueryID IN (SELECT query FROM @query_list)

FOR XML PATH('adm.pat.ccdqr.multiple'),TYPE
)

FROM livendb.dbo.AdmVisits ADMVS


LEFT JOIN livendb.dbo.DMisAccommodation MISACC
ON (ADMVS.AccommodationID = MISACC.AccommodationID)

LEFT JOIN  livendb.dbo.DMisLocation MISLOC
ON (ADMVS.LocationID = MISLOC.LocationID)

LEFT JOIN  livendb.dbo.DMisLocation MISEVLOC
ON (ADMVS.LocationID = MISEVLOC.LocationID)

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes MISLOCNOMEN
ON (MISLOC.MisNomenclatureMapID = MISLOCNOMEN.MisNomenclatureMapID
AND ADMVS.SourceID = MISLOCNOMEN.SourceID
AND MISLOCNOMEN.CodeSetID='SNOMED_CT')

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes MISEVLOCNOMEN
ON (MISEVLOC.MisNomenclatureMapID = MISEVLOCNOMEN.MisNomenclatureMapID
AND ADMVS.SourceID = MISEVLOCNOMEN.SourceID)

LEFT JOIN livendb.dbo.AdmittingData ADMDATA
ON (ADMVS.SourceID = ADMDATA.SourceID
AND ADMVS.VisitID = ADMDATA.VisitID)

LEFT JOIN livendb.dbo.AdmDepartureData DPDATA
ON (ADMVS.SourceID = DPDATA.SourceID
AND ADMVS.VisitID = DPDATA.VisitID)

LEFT JOIN livendb.dbo.AdmProviders ADMDR
ON (ADMVS.SourceID = ADMDR.SourceID
AND ADMVS.VisitID = ADMDR.VisitID)

LEFT JOIN livendb.dbo.DMisProvider MISDR
ON (ADMDR.PrimaryCareID = MISDR.ProviderID
AND ADMDR.SourceID = MISDR.SourceID)

LEFT JOIN livendb.dbo.AdmDischarge ADMDIS
ON (ADMVS.SourceID = ADMDIS.SourceID
AND ADMVS.VisitID = ADMDIS.VisitID)

LEFT JOIN livendb.dbo.AdmVitalSigns ADMVTS
ON (ADMVS.SourceID = ADMVTS.SourceID
AND ADMVS.VisitID = ADMVTS.VisitID)

LEFT JOIN livendb.dbo.DMisProvider MISDRAT
ON ADMDR.AttendID = MISDRAT.ProviderID
AND ADMDR.SourceID = MISDRAT.SourceID

LEFT JOIN livendb.dbo.DMisProvider MISDRAD
ON ADMDR.AdmitID = MISDRAD.ProviderID
AND ADMDR.SourceID = MISDRAD.SourceID

LEFT JOIN livendb.dbo.DMisService MISSVC
ON ADMVS.InpatientServiceID = MISSVC.ServiceID
AND ADMVS.SourceID = MISSVC.SourceID

LEFT JOIN livendb.dbo.DMisNomenclatureMapCodes SVCNOMEN
ON MISSVC.MisNomenclatureMapID = SVCNOMEN.MisNomenclatureMapID
AND ADMVS.SourceID = SVCNOMEN.SourceID

LEFT JOIN livendb.dbo.DMisDischargeDisposition MISDIS
ON (ADMVS.SourceID = MISDIS.SourceID
AND ADMDIS.DispositionID = MISDIS.DispositionID)

LEFT JOIN livendb.dbo.DMisMaps MAPDIS
ON (ADMVS.SourceID = MAPDIS.SourceID
AND ADMDIS.DispositionID = MAPDIS.MappedFromID
AND MAPDIS.MapID = 'QMDXDIS')

LEFT JOIN livendb.dbo.AdmCdaTransmitted ADMCDATRANS
ON (ADMVS.SourceID = ADMCDATRANS.SourceID
AND ADMVS.VisitID = ADMCDATRANS.VisitID)

WHERE ABSPAT.SourceID =  ADMVS.SourceID
AND ABSPAT.VisitID = ADMVS.VisitID

FOR XML PATH (''), ROOT('adm.pat.main'), TYPE
)

-----------------End Master Select Statement -----------

FROM livefdb.dbo.AbsAcct_Main ABSPAT

LEFT JOIN livefdb.dbo.AbsAcct_VisitData ABSVISIT
ON ABSPAT.SourceID = ABSVISIT.SourceID
AND ABSPAT.VisitID = ABSVISIT.VisitID

LEFT JOIN livefdb.dbo.AbsAcct_RegData ABSDR
ON ABSPAT.SourceID = ABSDR.SourceID
AND ABSPAT.VisitID = ABSDR.VisitID

LEFT JOIN livefdb.dbo.AbsAcct_Drgs ABSDRG
ON ABSPAT.SourceID = ABSDRG.SourceID
AND ABSPAT.VisitID = ABSDRG.VisitID

WHERE ABSPAT.SourceID = @Facility
      AND ABSPAT.AbstractStatusDateField >= @Begin
      AND ABSPAT.AbstractStatusDateField < DATEADD(dd,1,@End)
  AND ABSPAT.PatientClassField_AbsPatClassID IN ('AMB','AMBR','CLI','ER','IN','INO','POV','RCR', 'REF', 'REFA', 'SDC')




FOR XML PATH(''),ELEMENTS,TYPE)

FOR XML PATH('extract')


