
/************************************************************************************
**
** RECETTE : comparer directement avec les données de  Showpad
**			 Exporter depuis le back-office les 2 fichiers "allFiles" & "allPages"
************************************************************************************/

-- drop table if exists #t
--- select * into #t from rfd.vw_DIM_ASSETS2 -- 31275//31254 // 31202
-- select * from #t
-- select * from #t where ast_displayName = 'Thales Eye - Brochure - Thales.PDF'


-- drop table if exists #IsContent
--- select ast_id	, ast_displayName , astF_idHash /*, lt_list_tagOnly , astC_allListTagsOnly */ into #IsContent from #t where astC_isContentCount = 1 

-- select * from #IsContent

drop table if exists #AuthorsFirstnameLastname

		SELECT A.cAssetId 
							, 										
							STRING_AGG( A.cAuthorFnameLname , ',')  WITHIN GROUP( ORDER BY A.cAuthorFnameLname ASC )  AS cAuthorFnameLname 	
			into #AuthorsFirstnameLastname
			FROM 
				(
					SELECT	DISTINCT 
							  aa.assetId			AS cAssetId 
							, u.usr_firstname + ' ' + u.usr_lastname  AS cAuthorFnameLname
					FROM rfd.ASSETS_AUTHOR aa left join rfd.vw_DIM_USERS2 u ON ( aa.userId = u.usr_id )
					WHERE aa.userId <> -1
					AND ( u.usr_firstname + ' ' + u.usr_lastname ) <> 'Deleted User'
				) AS A 
			GROUP BY cAssetId


-- drop table dbo.[showpad-asset-overview-allFiles-2022-10-07-06-27-12_v2] 
	
select *
from ThalesDigitalSeller_filesShowpad.dbo.[showpad-asset-overview-allFiles-2022-10-07-06-27-12] --5480

select *
from dbo.[showpad-asset-overview-allPages-2022-10-07-06-27-54] --824
;

--------------------------------
---- #1) List of tags ----
	WITH cL_ListTags
	AS
	(
		SELECT asso_assetIdHash			AS lt_assetIdHash

			, STRING_AGG(CONVERT(NVARCHAR(max), tag_name), ';') WITHIN GROUP (ORDER BY tag_name ASC) 
										AS lt_list_tag	

		FROM rfd.vw_ASSO_ASSET_TAGS [at]
			INNER JOIN rfd.vw_DIM_TAGS t
			ON [at].asso_tagIdHash = t.tag_idHash
		GROUP BY asso_assetIdHash
	) 
	,

	---- #2) List of tagCategories ----
	cL_ListTagCategories
	AS
	(
		SELECT asso_assetIdHash		AS ltc_assetIdHash
				, t.[tag_name]		AS ltc_tag
				, tc.[name]			AS ltc_tagCategory
		FROM rfd.vw_ASSO_ASSET_TAGS [at]
			INNER JOIN rfd.vw_DIM_TAGS t			ON ( [at].asso_tagIdHash = t.tag_idHash )
			INNER JOIN trd.TAG_CATEGORY_TAGS tct	ON ( t.tag_idHash = tct.tagId_hash )
			INNER JOIN trd.TAG_CATEGORIES tc		ON ( tct.tagCategoryId_hash = tc.tagCategoryId_hash )
	) -- select * from cL_ListTagCategories where ltc_assetIdHash = '85c2330f4ca7472bcf9b2e18c6eeb277' 
	,
	---- #3) List of Channels ----
	cL_ListChannels /* Hidden Channel */
	AS
	(
		SELECT chnl_name
		FROM rfd.vw_DIM_CHANNELS 
		WHERE chnl_name IN ( 'Customers Interests'
							,'Civil Markets'
							,'New Digital Offers'
							,'Solutions Portfolio'
							,'Defence Markets'
							,'Worldwide Credentials' )
	)
	,
	---- #4) List of mandatory tags ----
	cL_ListMandaTags 
	AS
	(
	--SELECT
	--	ltc_assetIdHash																 
	--	, STRING_AGG( CONVERT(NVARCHAR(max), ltc_tag), ';') WITHIN GROUP (ORDER BY ltc_tag ASC) AS lt_list_tag	
	--FROM
	--(
		SELECT ltc_assetIdHash																 
		,  ltc_tag 
		, ltc_tagCategory
		FROM cL_ListTagCategories
/*
		WHERE ltc_tagCategory IN ( 'GBU' , 'Type of Content' , 'Market Segment' , 'Hidden Product Line' , 'Hidden Product' , 'Sensitivity' , 'Thales Geography'
			, 'Country' , 'Worldwide Credentials' , 'Country Page' , 'Hidden Type of Page' )

		OR ltc_tagCategory IN ( SELECT gbu_name FROM trd.REF_GBU WHERE gbu_name <> 'OFF GBU' ) /* BL */

		OR ltc_tagCategory IN ( SELECT tagCategoryName FROM trd.REF_MARKET_SUB_SEGMENT ) /* Market sub segment */

		OR ltc_tag IN ( 'Large Countries' , 'DGDI'  ) 

		OR ( ltc_tagCategory = 'Hidden Channel' AND ltc_tag IN ( SELECT chnl_name FROM cL_ListChannels ) )
*/
		GROUP BY ltc_assetIdHash ,
		 ltc_tag ,
		 ltc_tagCategory
	-- ) T	
	--GROUP BY ltc_assetIdHash
	) --	
	select * into #cL_ListMandaTags from cL_ListMandaTags
--------------------------------

--------------------------------
drop table if exists #cL_ListMandaTags

select *
from #cL_ListMandaTags
WHERE ltc_tagCategory IN ( 'GBU' , 'Type of Content' , 'Market Segment' , 'Hidden Product Line' , 'Hidden Product' , 'Sensitivity' , 'Thales Geography'
	, 'Country' , 'Worldwide Credentials' , 'Country Page' , 'Hidden Type of Page' )

OR ltc_tagCategory IN ( SELECT gbu_name FROM trd.REF_GBU WHERE gbu_name <> 'OFF GBU' ) /* BL */
		
OR ltc_tagCategory IN ( SELECT tagCategoryName FROM trd.REF_MARKET_SUB_SEGMENT ) /* Market sub segment */
OR ltc_tag IN ( 'Large Countries' , 'DGDI'  ) 
OR ( ltc_tagCategory = 'Hidden Channel' AND ltc_tag IN ( 'Customers Interests'
													,'Civil Markets'
													,'New Digital Offers'
													,'Solutions Portfolio'
													,'Defence Markets'
													,'Worldwide Credentials' ) ) 
--------------------------------


select ltc_tag , COUNT(*) as nb
from #cL_ListMandaTags m
		inner join #IsContent c on ( m.ltc_assetIdHash = c.astF_idHash)
where ltc_tagCategory = 'Market Segment' 
group by ltc_tag


select ltc_tag , COUNT(*) as nb
from #cL_ListMandaTags m
		inner join #IsContent c on ( m.ltc_assetIdHash = c.astF_idHash)
where ltc_tagCategory = 'Hidden Product Line' 
group by ltc_tag

select ltc_tag , COUNT(*) as nb
from #cL_ListMandaTags m
		inner join #IsContent c on ( m.ltc_assetIdHash = c.astF_idHash)
where ltc_tagCategory = 'Hidden Product' 
group by ltc_tag

select ltc_tag , COUNT(*) as nb
from #cL_ListMandaTags m
		inner join #IsContent c on ( m.ltc_assetIdHash = c.astF_idHash)
where ltc_tagCategory IN ( SELECT tagCategoryName FROM trd.REF_MARKET_SUB_SEGMENT ) /* Market sub segment */ 
group by ltc_tag

select ltc_tag , COUNT(*) as nb
from #cL_ListMandaTags m
		inner join #IsContent c on ( m.ltc_assetIdHash = c.astF_idHash)
where ltc_tagCategory = 'Type of Content'  
group by ltc_tag


select ltc_tag , COUNT(*) as nb
from #cL_ListMandaTags m
		inner join #IsContent c on ( m.ltc_assetIdHash = c.astF_idHash)
where ltc_tagCategory = 'GBU'  
group by ltc_tag

select ltc_tag , COUNT(*) as nb
from #cL_ListMandaTags m
		inner join #IsContent c on ( m.ltc_assetIdHash = c.astF_idHash)
where ltc_tagCategory IN ( SELECT gbu_name FROM trd.REF_GBU WHERE gbu_name <> 'OFF GBU' ) /* BL */
group by ltc_tag
order by 1

select ltc_tag , COUNT(*) as nb
from #cL_ListMandaTags m
		inner join #IsContent c on ( m.ltc_assetIdHash = c.astF_idHash)
where ltc_tagCategory = 'Sensitivity'  
group by ltc_tag

--------------------------------
drop table if exists #TagCategories

SELECT asso_assetIdHash		AS [ltc_assetIdHash]
		, tc.[name]			AS [ltc_tagCategory]
		, t.tag_name		AS [ltc_tagName]
INTO #TagCategories
FROM ThalesDigitalSeller.rfd.vw_ASSO_ASSET_TAGS [at]
	INNER JOIN ThalesDigitalSeller.rfd.vw_DIM_TAGS t			ON ( [at].asso_tagIdHash = t.tag_idHash )
	INNER JOIN ThalesDigitalSeller.trd.TAG_CATEGORY_TAGS tct	ON ( t.tag_idHash = tct.tagId_hash )
	INNER JOIN ThalesDigitalSeller.trd.TAG_CATEGORIES tc		ON ( tct.tagCategoryId_hash = tc.tagCategoryId_hash )
-- 89702
/* Liste des filtres pour avoir tous les tags obligatoires :

		WHERE ltc_tagCategory IN ( 'GBU' , 'Type of Content' , 'Market Segment' , 'Hidden Product Line' , 'Hidden Product' , 'Sensitivity' , 'Thales Geography'
			, 'Country' , 'Worldwide Credentials' , 'Country Page' , 'Hidden Type of Page' )

		OR ltc_tagCategory IN ( SELECT gbu_name FROM trd.REF_GBU WHERE gbu_name <> 'OFF GBU' ) /* BL */

		OR ltc_tagCategory IN ( SELECT tagCategoryName FROM trd.REF_MARKET_SUB_SEGMENT ) /* Market sub segment */

		OR ltc_tag IN ( 'Large Countries' , 'DGDI'  ) 

		OR ( ltc_tagCategory = 'Hidden Channel' AND ltc_tag IN ( SELECT chnl_name FROM cL_ListChannels ) )

*/
select ltc_tagCategory , ltc_tagName , COUNT(*) as nb
from #TagCategories
WHERE ltc_tagCategory IN ( SELECT tagCategoryName FROM trd.REF_MARKET_SUB_SEGMENT ) /* Market sub segment */
group by ltc_tagCategory , ltc_tagName
order by ltc_tagCategory ,
		 ltc_tagName

select *
from #TagCategories
where ltc_assetIdHash = 'c3bf10c6ff9ffdbeaba0c43dd2f49817'

--------------------------------
drop table if exists #allShowpad

---- Section 'AllFiles' ----
with cShowpadBackOfficeAllFiles 
as
(
	select distinct id	, [asset name] , REPLACE( value , ' (Live)' , '') AS [Tag] , authors
	-- select * 
	from ThalesDigitalSeller_filesShowpad.dbo.[showpad-asset-overview-allFiles-2023-05-26-09-00-04]
				CROSS APPLY STRING_SPLIT( REPLACE( tags, ' (Live),' , '|') , '|')
) -- select * from cShowpadBackOfficeAllFiles  where CHARINDEX( ',' , tag , 0 ) > 0 order by [Tag]
,
cShowpadBackOfficeAllFiles_Author 
as
(
	SELECT id	, [asset name] ,  STRING_AGG( Author , ',') within group( order by Author asc )  AS listAuthorsSortedShowpad
	FROM
	(
		select distinct id	, [asset name] , value AS [Author] 
		from ThalesDigitalSeller_filesShowpad.dbo.[showpad-asset-overview-allFiles-2023-05-26-09-00-04]
					CROSS APPLY STRING_SPLIT( authors , ',')
	) T
	GROUP BY id	, [asset name] 

) -- select * from cShowpadBackOfficeAllFiles_Author 
,	
---- Section 'AllPages' ----
cShowpadBackOfficeAllPages
as
(
	select distinct id	, [asset name]  , REPLACE( value , ' (Live)' , '') AS [Tag] , authors
	-- select *
	from ThalesDigitalSeller_filesShowpad.dbo.[showpad-asset-overview-allPages-2023-05-26-09-00-20] 
				CROSS APPLY STRING_SPLIT(REPLACE( tags, ' (Live),' , '|') , '|') -- tags ,  '(Live),')
) -- select * from cShowpadBackOfficeAllPages where CHARINDEX( ',' , tag , 0 ) > 0
,
cShowpadBackOfficeComplete
AS
(
	select id	, [asset name]  , Tag , authors
	FROM cShowpadBackOfficeAllFiles
		UNION
	select id	, [asset name]  , Tag , authors
	FROM cShowpadBackOfficeAllPages

)
/*
, 
---- #2) List of tagCategories ----
cL_ListTagCategories
AS
(
	SELECT asso_assetIdHash		AS [ltc_assetIdHash]
			, tc.[name]			AS [ltc_tagCategory]
			, t.tag_name		AS [ltc_tagName]
	FROM ThalesDigitalSeller.rfd.vw_ASSO_ASSET_TAGS [at]
		INNER JOIN ThalesDigitalSeller.rfd.vw_DIM_TAGS t			ON ( [at].asso_tagIdHash = t.tag_idHash )
		INNER JOIN ThalesDigitalSeller.trd.TAG_CATEGORY_TAGS tct	ON ( t.tag_idHash = tct.tagId_hash )
		INNER JOIN ThalesDigitalSeller.trd.TAG_CATEGORIES tc		ON ( tct.tagCategoryId_hash = tc.tagCategoryId_hash )
) --	select * from cL_ListTagCategories where ltc_assetIdHash = 'a4c548207de22b161cf6be07f485484c'
*/
-- select COUNT(distinct [Id] ) as nb from cShowpadBackOfficeComplete -- 6302

-- drop table if exists #allShowpad
select shw.* , las.listAuthorsSortedShowpad
into #allShowpad
from cShowpadBackOfficeComplete shw -- left join cL_ListTagCategories tagcat on ( shw.Tag = tagcat.ltc_tagName )
		left join cShowpadBackOfficeAllFiles_Author las /* Sorted Auhors */
		on shw.id = las.id
order by shw.id 
-- 51768 // 51855 // 51836


select COUNT(*) as nb from #allShowpad

select * from #allShowpad
where Tag like '%é%' 

/* 1 - MARKET SEGEMENT - */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select distinct astSgmtC_segment from rfd.vw_DIM_ASSETS_SEGMENT where astSgmt_segmentId <> -1 )
group by Tag


/* 2 - MARKET SUB SEGEMENT - */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select distinct astSsSgmtC_subSegment from rfd.vw_DIM_ASSETS_SUB_SEGMENT where astSsSgmt_subSegmentId <> -1 )
group by Tag

/* 3 - PRODUCT- */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select astPrdtC_productTag  from rfd.vw_DIM_ASSETS_PRODUCT where astPrdt_productId <> -1 )
group by Tag
order by 1 

select * from #allShowpad where Tag like '%ARAMIS%' -- ARAMISâ„¢ --

/* 4 - PRODUCT LINE - */
SELECT asso_assetIdHash		AS ltc_assetIdHash
		, t.[tag_name]		AS ltc_tag
		, tc.[name]			AS ltc_tagCategory
into #refProductLine
FROM rfd.vw_ASSO_ASSET_TAGS [at]
	INNER JOIN rfd.vw_DIM_TAGS t			ON ( [at].asso_tagIdHash = t.tag_idHash )
	INNER JOIN trd.TAG_CATEGORY_TAGS tct	ON ( t.tag_idHash = tct.tagId_hash )
	INNER JOIN trd.TAG_CATEGORIES tc		ON ( tct.tagCategoryId_hash = tc.tagCategoryId_hash )
where  tc.[name] = 'Hidden Product Line'

select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select ltc_tag  from #refProductLine  )
group by Tag
order by 1 

/* 5 - Type Content - */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select distinct astCtTypC_contentTag  from rfd.vw_DIM_ASSETS_CONTENT_TYPE where astCtTyp_contentId <> -1 )
group by Tag
order by 1 

/* 6 - Sensitivity - */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select distinct astSensiC_sensitivityTag from rfd.vw_DIM_ASSETS_SENSITIVITY where astSensi_sensitivityId <> -1 )
group by Tag
order by 1 

/* 7 - GBU - */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select distinct astBl_gbuName from rfd.vw_DIM_ASSETS_BL where astBl_gbuName <> 'OFF GBU' )
group by Tag
order by 1 

/* 8 - BL - */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select distinct astBl_blName from rfd.vw_DIM_ASSETS_BL where astBl_blName <> 'OFF BL' )
group by Tag
order by 1 

/* 9 - Large Countries - */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( 'Large Countries' )
group by Tag
order by 1 
-- Large Countries	7

/* 10 - DGDI- */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( 'DGDI' )
group by Tag
order by 1 
-- DGDI	86

/* 11 - Country- */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select distinct astCntryC_country from rfd.vw_DIM_ASSETS_COUNTRY where astCntry_countryId <> -1 )
group by Tag
order by 1 

/* 12 - Région- */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select distinct astCntry_regionName from rfd.vw_DIM_ASSETS_COUNTRY where astCntry_countryId <> -1 )
group by Tag
order by 1 

/* 13 - Worldwide Credentials */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( 'Worldwide Credentials' )
group by Tag
order by 1 

/* 14 - Hidden Channels */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag   IN ( 'Customers Interests'
													,'Civil Markets'
													,'New Digital Offers'
													,'Solutions Portfolio'
													,'Defence Markets'
													,'Worldwide Credentials' )
group by Tag
order by 1 

select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( 'Worldwide Credentials' )
group by Tag
order by 1 

/* 15 - Country Page*/
-- cf. 16 - Landing Page --

/* 16 - Landing Page - */
select Tag , COUNT(*) as nb
from #allShowpad m
		inner join #IsContent c on ( m.[id] = c.astF_idHash)
where Tag IN  ( select distinct ctTyp_name from rfd.vw_DIM_CONTENT_TYPE_PAGE_TYPE where ctTyp_id is NULL )
group by Tag
order by 1 

-----------------------------------------------------------------------------------------------------------------
/***************** Contrôle depuis les exports de Showpad *****************/
select distinct id , [asset name] from #allShowpad m left join #IsContent c on ( m.[id] = c.astF_idHash)
where c.astF_idHash is null
/*
id	asset name
27d9e442db548df05fcdf7ec3dc63c9f	Audio Podcast EUROSATORY 2022 (Eng) - Thales.mp3
48f8e3b649f55278d9056f99afdb76eb	Audio Podcast EUROSATORY 2022 (Fr) - Thales.mp3
8ca42cd1113e8666362ffd20ce993e08	InControl_Package.zip
db4ae71200d1d2729cbb55643c806e1d	Thales FlytX helicopter retrofit.gif
*/
drop table #allShowpad_02_Kpis_Elementaires

--select  Tag , max( unit_isWorldwideCredentials )
--from
--		(
		select * ,
				case when m.Tag in ( 'Large Countries' )
						then 1
						else 0
				end		as unit_isLargeCountries ,

				case when m.Tag in ( 'DGDI' )
						then 1
						else 0
				end		as unit_isDgdi,

				case when m.Tag in ( select distinct gbu_name from rfd.ASSETS_BL where gbu_name <> 'OFF GBU' )
						then 1
						else 0
				end		as unit_isGbu ,

				case when m.Tag in ( select distinct astBl_blName from rfd.vw_DIM_ASSETS_BL where astBl_blName <> 'OFF BL' )
						then 1
						else 0
				end		as unit_isBl ,

				case when m.Tag in ( select distinct astSgmtC_segment from rfd.vw_DIM_ASSETS_SEGMENT where astSgmt_segmentId <> -1  )
						then 1
						else 0
				end		as unit_isMarketSegment ,

				case when m.Tag in ( select distinct astSsSgmtC_subSegment from rfd.vw_DIM_ASSETS_SUB_SEGMENT where astSsSgmt_subSegmentId <> -1 )
						then 1
						else 0
				end		as unit_isMarketSubSegment,

				case when m.Tag in ( SELECT [tcHrchy_tagName]  FROM [rfd].[vw_DIM_CATEGORIES_HIERARCHY_TAG]  WHERE tcHrchy_tagCategoryName = 'Hidden Product Line' /* 90 Product Lines */ )
						then 1
						else 0
				end		as unit_isProductLine,

				case when m.Tag in ( SELECT [tcHrchy_tagName]  FROM [rfd].[vw_DIM_CATEGORIES_HIERARCHY_TAG]  WHERE tcHrchy_tagCategoryName = 'Hidden Product' /* 462 Products  */   )
						then 1
						else 0
				end		as unit_isProductName,

				case when m.Tag in ( select distinct astCtTypC_contentTag  from rfd.vw_DIM_ASSETS_CONTENT_TYPE where astCtTyp_contentId <> -1  )
						then 1
						else 0
				end		as unit_isContentType,

				case when m.Tag in ( select distinct astSensiC_sensitivityTag from rfd.vw_DIM_ASSETS_SENSITIVITY where astSensi_sensitivityId <> -1   )
						then 1
						else 0
				end		as unit_isSensitivity,

				case when m.Tag in ( select distinct astCntryC_country from rfd.vw_DIM_ASSETS_COUNTRY where astCntry_countryId <> -1  )
						then 1
						else 0
				end		as unit_isCountry,

				case when m.Tag in ( select distinct astCntry_regionName from rfd.vw_DIM_ASSETS_COUNTRY where astCntry_countryId <> -1  )
						then 1
						else 0
				end		as unit_isRegion,

				case when m.Tag in ( 'Country Page' )
						then 1
						else 0
				end		as unit_isCountryPage ,

				case when m.Tag in ( 'Worldwide Credentials' )
						then 1
						else 0
				end		as unit_isWorldwideCredentials ,

				case when m.Tag in ( select distinct ctTyp_name from rfd.vw_DIM_CONTENT_TYPE_PAGE_TYPE where ctTyp_id is NULL )
						then 1
						else 0
				end		as unit_isLandingPage,

				case when m.Tag in ( 'Customers Interests'
										,'Civil Markets'
										,'New Digital Offers'
										,'Solutions Portfolio'
										,'Defence Markets'
										,'Worldwide Credentials' )
						then 1
						else 0
				end		as unit_isChannel

		into #allShowpad_02_Kpis_Elementaires
		from #allShowpad m inner join #IsContent c on ( m.[id] = c.astF_idHash) /*exclure raw et audo */ 
		-- 51729
--) T
--group by Tag
--order by 2 desc , 1

select top 1000 * from #allShowpad_02_Kpis_Elementaires


drop table if exists zzz_allShowpad_02_Kpis_Elementaires

select *
into zzz_allShowpad_02_Kpis_Elementaires
from #allShowpad_02_Kpis_Elementaires
-- 51729

drop table if exists #allShowpad_03_Kpis_elementaires_max

select  s.id 	, [asset name] ,		authors ,	ast_id ,	astF_idHash , listAuthorsSortedShowpad ,

			cAllTags ,
			cOnlyMandatoryTags ,

			[asset name] + ';' + cOnlyMandatoryTags as cDisplayNameOnlyMandatoryTags,

			MAX(unit_isLargeCountries) AS unit_isLargeCountries , 
			MAX(unit_isDgdi) AS unit_isDgdi , 
			MAX(unit_isGbu) AS unit_isGbu , 
			MAX(unit_isBl) AS unit_isBl , 
			MAX(unit_isMarketSegment) AS unit_isMarketSegment , 
			cMarketSegment ,

			MAX(unit_isMarketSubSegment) AS unit_isMarketSubSegment , 
			cSubMarketSegment ,

			MAX(unit_isProductLine) AS unit_isProductLine , 
			cProductLine ,

			MAX(unit_isProductName) AS unit_isProductName , 
			cProductName ,

			MAX(unit_isContentType) AS unit_isContentType ,
			cContentType , 

			MAX(unit_isSensitivity) AS unit_isSensitivity , 
			cSensitivity ,

			MAX(unit_isCountry) AS unit_isCountry , 
			cCountry ,

			MAX(unit_isRegion) AS unit_isRegion , 
			cRegion ,

			MAX(unit_isCountryPage) AS unit_isCountryPage ,
			cCountryPage , 

			MAX(unit_isWorldwideCredentials) AS unit_isWorldwideCredentials , 
			cWorldwideCredentials ,

			MAX(unit_isLandingPage) AS unit_isLandingPage , 
			cLandingPage ,
 
			MAX(unit_isChannel) AS unit_isChannel ,
			cChannel 
into  #allShowpad_03_Kpis_elementaires_max 
from zzz_allShowpad_02_Kpis_Elementaires s
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cMarketSegment
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isMarketSegment = 1 
								) AS G
								GROUP BY id
						) ms on s.id = ms.id  
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cSubMarketSegment
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isMarketSubSegment = 1 
								) AS G
								GROUP BY id
						) mss	on s.id = mss.id  
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cProductLine
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isProductLine = 1 
								) AS G
								GROUP BY id
						) pl	on s.id = pl.id  
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cProductName
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isProductName = 1 
								) AS G
								GROUP BY id
						) pn	on s.id = pn.id  
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cContentType
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isContentType = 1 
								) AS G
								GROUP BY id
						) ct	on s.id = ct.id  
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cSensitivity
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isSensitivity = 1 
								) AS G
								GROUP BY id
						) cs	on s.id = cs.id  
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cCountry 
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isCountry = 1 
								) AS G
								GROUP BY id
						) c	on s.id = c.id  
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cRegion 
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isRegion = 1 
								) AS G
								GROUP BY id
						) r	on s.id = r.id  
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cCountryPage 
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isCountryPage = 1 
								) AS G
								GROUP BY id
						) cp	on s.id = cp.id  	
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cWorldwideCredentials
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isWorldwideCredentials = 1 
								) AS G
								GROUP BY id
						) wc	on s.id = wc.id  	
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cLandingPage 
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isLandingPage = 1 
								) AS G
								GROUP BY id
						) lp	on s.id = lp.id  		
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cChannel
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isChannel = 1 
								) AS G
								GROUP BY id
						) ch	on s.id = ch.id  								
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cOnlyMandatoryTags
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
									where unit_isLargeCountries = 1 OR 
											unit_isDgdi = 1 OR 
											unit_isGbu = 1 OR 
											unit_isBl = 1 OR 
											unit_isMarketSegment = 1 OR 
											unit_isMarketSubSegment = 1 OR 
											unit_isProductLine = 1 OR 
											unit_isProductName = 1 OR 
											unit_isContentType = 1 OR 
											unit_isSensitivity = 1 OR 
											unit_isCountry = 1 OR 
											unit_isRegion = 1 OR 
											unit_isCountryPage = 1 OR 
											unit_isWorldwideCredentials = 1 OR 
											unit_isLandingPage = 1 OR 
											unit_isChannel = 1  
								) AS G
								GROUP BY id
						) manda	on s.id = manda.id  			
		left outer join ( 
								SELECT id , STRING_AGG( Tag , ';') WITHIN GROUP( ORDER BY Tag ASC ) AS cAllTags
								FROM
								(
									SELECT id , Tag
									FROM #allShowpad_02_Kpis_Elementaires
								) AS G
								GROUP BY id
						) allTags	on s.id = allTags.id  	
				
--where s.id = '026748d28e866c986997886353591c53'
group by  s.id , [asset name] ,		authors ,	ast_id ,	astF_idHash , cMarketSegment , cSubMarketSegment , cProductLine , cProductName , cContentType , cSensitivity , cCountry , cRegion , cCountryPage , cWorldwideCredentials
, cLandingPage , cChannel , [asset name] , cOnlyMandatoryTags , cAllTags , listAuthorsSortedShowpad
-- 6296 -- 6300

select * from #allShowpad_03_Kpis_elementaires_max

drop table if exists #allShowpad_04_Kpis_cheminTaggingFullValide

select * ,

IIF( unit_isGbu = 1 AND unit_isBl = 1 AND unit_isMarketSegment = 1 AND unit_isMarketSubSegment = 1 AND unit_isProductLine = 1 AND unit_isProductName = 1 AND unit_isContentType = 1 AND unit_isSensitivity= 1 , 1 , 0)
	AS pathTagging_isAsset ,

IIF( unit_isGbu = 1 AND unit_isBl = 1 AND unit_isChannel = 1 AND unit_isLandingPage = 1 , 1 , 0)
	AS pathTagging_isLandingPage ,

IIF( unit_isDgdi = 1 AND unit_isContentType = 1 AND unit_isSensitivity= 1 AND unit_isCountry = 1 AND unit_isRegion = 1 , 1 , 0)
	AS pathTagging_isCountryFactsheet ,

IIF( unit_isDgdi = 1 AND unit_isCountry = 1 AND unit_isRegion = 1 AND unit_isWorldwideCredentials = 1 AND unit_isCountryPage = 1  , 1 , 0)
	AS pathTagging_isCountryPageDGDI,

IIF( unit_isLargeCountries = 1 AND unit_isCountry = 1 AND unit_isRegion = 1 AND unit_isWorldwideCredentials = 1 AND unit_isCountryPage = 1  , 1 , 0)
	AS pathTagging_isCountryPageLargeCountry

into  #allShowpad_04_Kpis_cheminTaggingFullValide
from #allShowpad_03_Kpis_elementaires_max

select * from #allShowpad_04_Kpis_cheminTaggingFullValide

select pathTagging_isAsset ,
		pathTagging_isLandingPage	 ,
		pathTagging_isCountryFactsheet	 ,
		pathTagging_isCountryPageDGDI	 ,
		pathTagging_isCountryPageLargeCountry
		 , COUNT(*) as nb 
 from #allShowpad_04_Kpis_cheminTaggingFullValide
 group by  pathTagging_isAsset ,
		pathTagging_isLandingPage	 ,
		pathTagging_isCountryFactsheet	 ,
		pathTagging_isCountryPageDGDI	 ,
		pathTagging_isCountryPageLargeCountry


drop table if exists #allShowpad_05_Kpis_atLeastOneValidTaggingPath

select * , IIF(  pathTagging_isAsset + pathTagging_isLandingPage + 	pathTagging_isCountryFactsheet + pathTagging_isCountryPageDGDI + pathTagging_isCountryPageLargeCountry > 0 , 1 , 0 ) /* Check un des 5 chemins Tagging 100% valide */
			AS pathTagging_hasAtLeastOneValidPath
into #allShowpad_05_Kpis_atLeastOneValidTaggingPath
from #allShowpad_04_Kpis_cheminTaggingFullValide

select * from #allShowpad_05_Kpis_atLeastOneValidTaggingPath

	select * 
	from #allShowpad_05_Kpis_atLeastOneValidTaggingPath 
	where pathTagging_hasAtLeastOneValidPath = 1
	-- 586

	select * 
	from #allShowpad_05_Kpis_atLeastOneValidTaggingPath 
	where pathTagging_hasAtLeastOneValidPath = 0
	-- 5718
	

/* VALIDATION : comparer la chaîne de Tags obligatoires */
select  *, c.lt_list_tagOnly , c.astC_allListTagsOnly , s.cOnlyMandatoryTags   
from #IsContent c inner join
--- select ast_id	, ast_displayName , astF_idHash , lt_list_tagOnly 
 #allShowpad_05_Kpis_atLeastOneValidTaggingPath s on c.astF_idHash = s.id
	where s.cOnlyMandatoryTags  <> c.lt_list_tagOnly
/*
Garden Island Team.mp4 // 1e3d9558666cc87d27b82fdb9e106180 // Australia;AWS;C1	Australia;AWS;C1	Australia;AWS;C1;Large Countries
AM_Demolition Stores_v1.0.pdf // cc7ccb234600794704a7de12052a4c92 // Australia;C1;Defence Markets	Australia;C1;Defence Markets	Australia;Brochure;C1;Defence Markets;VTS
*/
select  *, c.lt_list_tagOnly , c.astC_allListTagsOnly , s.cOnlyMandatoryTags   
from #IsContent c inner join
 #allShowpad_05_Kpis_atLeastOneValidTaggingPath s on c.astF_idHash = s.id
	where len( s.cOnlyMandatoryTags) <> len(c.lt_list_tagOnly)


drop table if exists #allShowpad_06_Kpis_duplicatedContent

select  c.lt_list_tagOnly	,  c.astC_allListTagsOnly , 
 s.* ,
COUNT(*) over(partition by ast_displayName , lt_list_tagOnly ) as nbDblonDisplayNameTags
,
IIF( COUNT(*) over(partition by ast_displayName , lt_list_tagOnly ) > 1 , 1 , 0 ) as DupContent_isDblnDisplayNameTags 
 ,
COUNT(*) over(partition by ast_displayName , authors ) as nbDblonDisplayNameAuthors
,
IIF( COUNT(*) over(partition by ast_displayName , authors ) > 1 , 1 , 0 ) as DupContent_isDblnDisplayNameAuthors
into #allShowpad_06_Kpis_duplicatedContent
from #IsContent c inner join
	 #allShowpad_05_Kpis_atLeastOneValidTaggingPath s on c.astF_idHash = s.id
	where s.cOnlyMandatoryTags  = c.lt_list_tagOnly
-- 6267

select * from #allShowpad_06_Kpis_duplicatedContent



drop table #allShowpad_07_Kpis_duplicatedContent_TagsOrAuthors

select * ,
IIF( DupContent_isDblnDisplayNameTags + DupContent_isDblnDisplayNameAuthors > 0 , 1 , 0) as DupContent_isDblnTagsOrAuthors 
into #allShowpad_07_Kpis_duplicatedContent_TagsOrAuthors
from #allShowpad_06_Kpis_duplicatedContent

select *  from #allShowpad_07_Kpis_duplicatedContent_TagsOrAuthors
 
select DupContent_isDblnDisplayNameTags , DupContent_isDblnDisplayNameAuthors	, DupContent_isDblnTagsOrAuthors, COUNT(*) as nbContent
from #allShowpad_07_Kpis_duplicatedContent_TagsOrAuthors
where DupContent_isDblnTagsOrAuthors = 1
group by DupContent_isDblnDisplayNameTags , DupContent_isDblnDisplayNameAuthors	, DupContent_isDblnTagsOrAuthors
-- 204
/*
DupContent_isDblnDisplayNameTags	DupContent_isDblnDisplayNameAuthors	DupContent_isDblnTagsOrAuthors	nbContent
0	1	1	65
1	1	1	139
*/

select pathTagging_hasAtLeastOneValidPath, COUNT(*) as nb 
from #allShowpad_05_Kpis_atLeastOneValidTaggingPath
where ast_id is not null
group by pathTagging_hasAtLeastOneValidPath

/* VALIDATION : comparer les listes de tous les tags par contenu */
select astC_allListTagsOnly , cAllTags -- , *
from #allShowpad_07_Kpis_duplicatedContent_TagsOrAuthors
where astC_allListTagsOnly <> cAllTags
-- 66 : tri caractère spécial (- , & , ...) et accent sur e

select astC_allListTagsOnly , cAllTags
from #allShowpad_07_Kpis_duplicatedContent_TagsOrAuthors
where len(astC_allListTagsOnly) <> len(cAllTags)
-- 0

/* VALIDATION : comparer la liste des auteurs */ /* NOTE : Les export BO Showpad ne permettent pas d'identifier les utilisateurs désactivés */
select  * , -- 
 --s.authors   ,
 afln.cAuthorFnameLname ,  s.listAuthorsSortedShowpad 
from #IsContent c inner join
--- select ast_id	, ast_displayName , astF_idHash , lt_list_tagOnly 
 #allShowpad_05_Kpis_atLeastOneValidTaggingPath s on c.astF_idhash = s.id
	left join #AuthorsFirstnameLastname afln on c.ast_id = afln.cAssetId

	where s.listAuthorsSortedShowpad  <> afln.cAuthorFnameLname 
-- 0 écart sur auteurs	

select * 
from #AuthorsFirstnameLastname #t -- [rfd].[vw_DIM_ASSETS2] 
where 	astF_idHash = '001ba8577833c8ede597f8cb9a5b2b57'

-----------------------------------------------------------------------------------------------------------------


		WHERE ltc_tagCategory IN ( 'GBU' , 'Type of Content' , 'Market Segment' , 'Hidden Product Line' , 'Hidden Product' , 'Sensitivity' , 'Thales Geography'
			, 'Country' , 'Hidden Type of Page' )

		OR ltc_tagCategory IN ( SELECT gbu_name FROM trd.REF_GBU WHERE gbu_name <> 'OFF GBU' ) /* BL */

		OR ltc_tagCategory IN ( SELECT tagCategoryName FROM trd.REF_MARKET_SUB_SEGMENT ) /* Market sub segment */
		-- OR ltc_tagCategory IN ( SELECT tagName FROM trd.REF_MARKET_SEGMENT ) /* Market sub segment */

		OR ltc_tag IN ( 'Large Countries' , 'DGDI'  , 'Worldwide Credentials' , 'Country Page'  ) 
		OR ( ltc_tagCategory = 'Hidden Channel' AND ltc_tag IN ( SELECT chnl_name FROM cL_ListChannels ) )


----------------------------
select * 
from #allShowpad shw left join #TagCategories tagcat on ( shw.[id] = tagcat.ltc_assetIdHash and shw.Tag = tagcat.ltc_tagName )
-- NOTE : un tag peut appartenir à plusieurs catégories. Ex : Defence Markets appartient aux catégories "Market Segment" & "Hidden Channel"
----------------------------


select [asset name] ,  authors ,  COUNT(distinct id) as nb
from #allShowpad
group by  [asset name] , authors
having COUNT(distinct id) > 1
order by 3 desc
-- 69 doublons sur : nom du contenu + auteurs (ID Asset différents => Contenus distincts) --

-- NOTE : un tag peut être dans plusieurs catégories // ex : Land Forces dans "Defence" & "Hidden Industry" --


	SELECT DISTINCT ltc_tagCategory , ltc_tagName
	FROM cL_ListTagCategories

/************************************************************************************/

;
ALTER  -- CREATE 
VIEW [rfd].[vw_DIM_ASSETS2] -- vw_DIM_ASSETS2
AS

	WITH cPeriodCalc
	AS
	(
		SELECT 6 AS [PeriodMonths] /* Period in months */
	)
	,
	cDivision
	AS
	(
		SELECT DISTINCT ass.assetId , ass.divisionId	 
		FROM rfd.ASSETS ass
				INNER JOIN rfd.vw_DIM_DIVISIONS div /* Live division only */
				ON ass.divisionId = div.div_id

	)
	,
	cAuthor
	AS
	(
		SELECT  assetId			AS cAssetId
			  , userId			AS cAuthorId
			  , ROW_NUMBER() OVER( PARTITION BY assetId ORDER BY userId ) AS rankAuthor
		FROM rfd.ASSETS_AUTHOR
		WHERE userId <> -1
	) -- select distinct cAssetId from cAuthor
	

	, 
	cSensitivity
	AS
	(
		SELECT DISTINCT astSensi_id AS cAssetId
		FROM rfd.vw_DIM_ASSETS_SENSITIVITY
		WHERE astSensi_sensitivityId <> -1
	)
	, 
	cAssetsDuplicate
	AS
	(
		SELECT displayName AS cDisplayName
		FROM rfd.ASSETS 
		GROUP BY displayName
		HAVING COUNT(*) > 1
	)
	, 
	cEvtInChannels /* Channel parmi une des 6 expériences (Civil Markets, Customer Interests ...) */ 
	AS
	(
		SELECT DISTINCT fEvt.evtF_assetId
		FROM rfd.vw_DIM_EVENTS dEvt
				INNER JOIN rfd.vw_FACT_EVENTS2 fEvt
				ON evt_id = evtF_id
		WHERE dEvt.evtC_isChannel = 1
	)
	,
	cAss
	AS
	(
		SELECT --DISTINCT
				ass.*
			  , CAST(
					CASE 
						WHEN ass.[uploadedAt] IS NULL AND ass.[updatedAt] IS NULL THEN NULL
						WHEN ass.[uploadedAt] IS NULL AND ass.[updatedAt] IS NOT NULL THEN ass.[updatedAt]
						WHEN ass.[uploadedAt] IS NOT NULL AND ass.[updatedAt] IS NULL THEN ass.[uploadedAt]
						ELSE IIF(ass.[uploadedAt] >= ass.[updatedAt]
								,ass.[uploadedAt]
								,ass.[updatedAt] 
								)
							END
													AS DATE)	AS [astC_FrechnessDt]			
	
		FROM rfd.ASSETS ass
		)
	, 
	cListAuthors /* Pour chaque contenu, concaténer les auteurs */
	AS
	(
	--	SELECT aut.cAssetId , 
	--			cAss.displayName + ';' + aut.cAuthor AS [cAssetNameAuthor] ,
	--			cAuthor
	--	FROM
	--	(
			SELECT A.cAssetId , 				
									
										STRING_AGG( A.cAuthor , ' , ') WITHIN GROUP( ORDER BY A.cAuthor ASC )  AS cAuthor 	
			FROM 
				(
					SELECT	DISTINCT 
							  aa.assetId			AS cAssetId 
							, u.usr_lastname + ' ' + u.usr_firstname AS cAuthor
					FROM rfd.ASSETS_AUTHOR aa left join rfd.vw_DIM_USERS2 u ON ( aa.userId = u.usr_id )
					WHERE aa.userId <> -1
					AND u.usrC_isReallyActive = 1
				) AS A 
			GROUP BY cAssetId --, ast.displayName	, aut.cAuthor 
		--) AS aut
		--	LEFT JOIN cAss ON (aut.cAssetId = cAss.assetId)
		--WHERE cAss.assetId IS NOT NULL

		-- 415
	) -- select * from cListAuthors
	,	
	cListGbu /* Par asset, liste de GBU depuis table préparée Data Factory => A vérifier */
	AS
	(
		SELECT cAssetId , STRING_AGG( cGBU , ' , ') AS cGbu
		FROM
		(
			SELECT DISTINCT
					aa.assetId		AS cAssetId
				  , bl.gbu_name		AS cGBU	

			FROM rfd.ASSETS_AUTHOR aa left join rfd.ASSETS_BL bl ON ( aa.assetId = bl.assetId )
		) AS G
		GROUP BY cAssetId
		-- 22471 
	)
	,	
	cListGbuBl /* Par asset, liste de BL depuis table préparée Data Factory => A vérifier */
	AS
	(
		SELECT cAssetId , STRING_AGG( cGBUBl , ' , ') AS cGBUBl
		FROM
		(
			SELECT DISTINCT
					aa.assetId							AS cAssetId
				  , bl.gbu_name + ' / ' + bl.bl_name	AS cGBUBl

			FROM rfd.ASSETS_AUTHOR aa left join rfd.ASSETS_BL bl ON ( aa.assetId = bl.assetId )
		) AS GB
		GROUP BY cAssetId
		-- 4496 
	)
	, 
	cSensitivityC3 /* Sensitivity C3 = Crypté (strictement interdit sur la plateforme) */ 
	AS
	(
		SELECT DISTINCT astSensi_id AS cAssetId
		FROM rfd.vw_DIM_ASSETS_SENSITIVITY
		WHERE astSensiC_sensitivityTag = 'C3'
	)
	,
	cAssetListTags /* For each asset, list of associated tags */
	AS
	(
		 SELECT asso_assetIdHash , STRING_AGG(CONVERT(NVARCHAR(max), tag_name), ';') WITHIN GROUP (ORDER BY tag_name ASC) AS list_tags
		 FROM rfd.vw_ASSO_ASSET_TAGS [at]
				INNER JOIN rfd.vw_DIM_TAGS t
				ON [at].asso_tagIdHash = t.tag_idHash
		GROUP BY asso_assetIdHash
	)
	, -- with
	---- #1) List of tags ----
	cL_ListTags
	AS
	(
		SELECT asso_assetIdHash			AS lt_assetIdHash

			, STRING_AGG(CONVERT(NVARCHAR(max), tag_name), ';') WITHIN GROUP (ORDER BY tag_name ASC) 
										AS lt_list_tag	

		FROM rfd.vw_ASSO_ASSET_TAGS [at]
			INNER JOIN rfd.vw_DIM_TAGS t
			ON [at].asso_tagIdHash = t.tag_idHash
		GROUP BY asso_assetIdHash
	) 
	,
	-- with
	---- #2) List of tagCategories ----
	cL_ListTagCategories
	AS
	(
		SELECT asso_assetIdHash		AS ltc_assetIdHash
				, t.[tag_name]		AS ltc_tag
				, tc.[name]			AS ltc_tagCategory
		FROM rfd.vw_ASSO_ASSET_TAGS [at]
			INNER JOIN rfd.vw_DIM_TAGS t			ON ( [at].asso_tagIdHash = t.tag_idHash )
			INNER JOIN trd.TAG_CATEGORY_TAGS tct	ON ( t.tag_idHash = tct.tagId_hash )
			INNER JOIN trd.TAG_CATEGORIES tc		ON ( tct.tagCategoryId_hash = tc.tagCategoryId_hash )
	) -- 	select * into #tagCateTrmt from cL_ListTagCategories --where ltc_assetIdHash = '85c2330f4ca7472bcf9b2e18c6eeb277' 
	,
	---- #3) List of Channels ----
	cL_ListChannels /* Hidden Channel */
	AS
	(
		SELECT DISTINCT chnl_name
		FROM rfd.vw_DIM_CHANNELS 
		WHERE chnl_name IN ( 'Customers Interests'
							,'Civil Markets'
							,'New Digital Offers'
							,'Solutions Portfolio'
							,'Defence Markets'
							,'Worldwide Credentials' )
	)
	,
	---- #4) List of mandatory tags ----
	cL_ListMandaTags 
	AS
	(
	SELECT
		ltc_assetIdHash																 
		, STRING_AGG( CONVERT(NVARCHAR(max), ltc_tag), ';') WITHIN GROUP (ORDER BY ltc_tag ASC) AS lt_list_tag	
	FROM
	(
		SELECT ltc_assetIdHash																 
		,  ltc_tag 
		FROM cL_ListTagCategories
		WHERE ltc_tagCategory IN ( 'GBU' , 'Type of Content' , 'Market Segment' , 'Hidden Product Line' , 'Hidden Product' , 'Sensitivity' , 'Thales Geography'
			, 'Country' , 'Worldwide Credentials' , 'Country Page' , 'Hidden Type of Page' )

		OR ltc_tagCategory IN ( SELECT gbu_name FROM trd.REF_GBU WHERE gbu_name <> 'OFF GBU' ) /* BL */

		OR ltc_tagCategory IN ( SELECT tagCategoryName FROM trd.REF_MARKET_SUB_SEGMENT ) /* Market sub segment */
		-- OR ltc_tagCategory IN ( SELECT tagName FROM trd.REF_MARKET_SEGMENT ) /* Market sub segment */

		OR ltc_tag IN ( 'Large Countries' , 'DGDI'  ) 
		OR ( ltc_tagCategory = 'Hidden Channel' AND ltc_tag IN ( SELECT chnl_name FROM cL_ListChannels ) )
		GROUP BY ltc_assetIdHash ,
		 ltc_tag
	) T	
	GROUP BY ltc_assetIdHash
	) -- select * from cL_ListMandaTags --11896 vs 11877
	,
	cL_tag_tagCate	/* Calcul des Flags pour la validation des chaînes de Tags 100% valides */
	AS
		(
		SELECT --lt.* , 
			lt_assetIdHash , 
			lt_list_tag ,
			ltc_tag ,
			--ltc_tagCategory ,

			IIF(  ltc_tag = 'Large Countries' , 1  , 0 )				AS [cL_isOkLargeCountries] ,

			IIF( ltc_tag = 'DGDI' , 1  , 0 ) 							AS [cL_isOkDgdi] ,

			IIF(  ltc_tagCategory = 'GBU'  , 1  , 0 )					AS [cL_isOkGbu] ,

			IIF(  ltc_tagCategory IN ( SELECT gbu_name FROM trd.REF_GBU WHERE gbu_name <> 'OFF GBU' ), 1  , 0 )	/* La catégorie correspond à la valeur (car hiérarchie) */	
																		AS [cL_isOkBl] ,

			IIF(  ltc_tagCategory = 'Type of Content' , 1  , 0 )		AS [cL_isOkTypeContent] ,

			IIF(  ltc_tagCategory = 'Market Segment' , 1  , 0 )			AS [cL_isOkMarketSgmt] ,

			IIF(  ltc_tagCategory IN ( SELECT tagCategoryName FROM trd.REF_MARKET_SUB_SEGMENT) , 1  , 0 )	/* La catégorie correspond à la valeur (car hiérarchie) */							
																		AS [cL_isOkMarketSubSgmt] ,
/* XNG // OLD TO DEL
			IIF(  ltc_tagCategory IN ( SELECT tagName FROM trd.REF_MARKET_SEGMENT ) , 1  , 0 )	/* La catégorie correspond à la valeur (car hiérarchie) */							
																		AS [cL_isOkMarketSubSgmt] ,
*/
			IIF(  ltc_tagCategory = 'Hidden Product Line' , 1  , 0 )	AS [cL_isOkProductLine] ,

			IIF(  ltc_tagCategory = 'Hidden Product' , 1  , 0 )			AS [cL_isOkProductName] ,

			IIF(  ltc_tagCategory = 'Sensitivity' , 1  , 0 )			AS [cL_isOkSensitivity] ,

			IIF(  ltc_tagCategory = 'Thales Geography' , 1  , 0 )		AS [cL_isOkThalesGeography],

			IIF(  ltc_tagCategory = 'Country' , 1  , 0 )				AS [cL_isOkCountry] ,

			IIF(  ltc_tag = 'Worldwide Credentials' , 1  , 0 )			AS [cL_isOkWorldwidCredentials] ,
			
			IIF(  ltc_tag = 'Country Page' , 1  , 0 )					AS [cL_isOkCountryPage] ,		

			IIF(  ltc_tagCategory = 'Hidden Channel' AND ltc_tag IN ( SELECT chnl_name FROM cL_ListChannels ) , 1  , 0 )	
																		AS [cL_isOkChannel] , /* Channel créé artificiellement par le Métier pour les tags obligatoires spécifiques aux contenus de Type Landing Page */	

			IIF(  ltc_tagCategory = 'Hidden Type of Page' , 1  , 0 )	AS [cL_isOkTypeLandingPage] /* Mission page, Overview Page, etc */ 	

		FROM cL_ListTags lt
				LEFT OUTER JOIN cL_ListTagCategories ltc
				ON ( lt.lt_assetIdHash = ltc.ltc_assetIdHash )
	)  -- 	select * from cL_tag_tagCate  -- where lt_assetIdHash = 'c0b9248a9b34785f7791c74681e2a253' 
	,
	cL_tagCategory_KPIs
	AS
	(
		select  lt_assetIdHash , 
				lt_list_tag ,
				MAX(cL_isOkLargeCountries )		AS [cL_isOkLargeCountries] ,
				MAX(cL_isOkDgdi )				AS [cL_isOkDgdi] ,
				MAX(cL_isOkGbu)					AS [cL_isOkGbu] ,
				MAX(cL_isOkBl)					AS [cL_isOkBl] ,

				MAX(cL_isOkMarketSgmt)			AS [cL_isOkMarketSgmt] ,
				MAX(cL_isOkMarketSubSgmt)		AS [cL_isOkMarketSubSgmt] ,
				MAX(cL_isOkProductLine)			AS [cL_isOkProductLine] ,
				MAX(cL_isOkProductName)			AS [cL_isOkProductName] ,

				MAX(cL_isOkTypeContent)			AS [cL_isOkTypeContent] ,
				MAX(cL_isOkSensitivity)			AS [cL_isOkSensitivity] ,
				MAX(cL_isOkThalesGeography)		AS [cL_isOkThalesGeography] , 
				MAX(cL_isOkCountry)				AS [cL_isOkCountry], 

				MAX(cL_isOkCountryPage)			AS [cL_isOkCountryPage], 
				MAX(cL_isOkWorldwidCredentials)	AS [cL_isOkWorldwidCredentials], 
				MAX(cL_isOkChannel)				AS [cL_isOkChannel],  
				MAX(cL_isOkTypeLandingPage)		AS [cL_isOkTypeLandingPage]

		from cL_tag_tagCate 
		group by lt_assetIdHash ,
				 lt_list_tag
	) -- select * from cL_tagCategory_KPIs -- where lt_assetIdHash = 'a4c548207de22b161cf6be07f485484c' --where cL_isOkGbu = 1 and	cL_isOkBl =1 and cL_isOkTypeLandingPage = 1
	,
	cL_tagCategory_KPIsConsolides
	AS
	(
		SELECT 	lt_assetIdHash , 
				lt_list_tag ,	

				cL_isOkLargeCountries  ,
				cL_isOkDgdi  ,
				cL_isOkGbu ,
				cL_isOkBl ,
				cL_isOkMarketSgmt ,
				cL_isOkMarketSubSgmt ,
				cL_isOkProductLine ,
				cL_isOkProductName ,
				cL_isOkTypeContent ,
				cL_isOkSensitivity ,
				cL_isOkThalesGeography ,
				cL_isOkCountry ,
				cL_isOkCountryPage ,
				cL_isOkWorldwidCredentials ,
				cL_isOkChannel ,
				cL_isOkTypeLandingPage ,

			/* Check chaîne de tags 100% valides */
			CASE WHEN cL_isOkGbu = 1 
						AND cL_isOkBl = 1 
						AND cL_isOkMarketSgmt = 1
						AND cL_isOkMarketSubSgmt = 1
						AND cL_isOkProductLine = 1
						AND cL_isOkProductName = 1
						AND cL_isOkTypeContent = 1
						AND cL_isOkSensitivity = 1 
					THEN 1
					ELSE 0
				END								AS [cL_mandaTags_isOkAsset] ,

			CASE WHEN cL_isOkGbu = 1 
						AND cL_isOkBl = 1 
						AND cL_isOkChannel = 1
						AND cL_isOkTypeLandingPage = 1
					THEN 1
					ELSE 0
				END								AS [cL_mandaTags_isOkLandingPage] ,

			CASE WHEN cL_isOkDgdi = 1 
						AND cL_isOkTypeContent = 1
						AND cL_isOkSensitivity = 1
						AND cL_isOkThalesGeography = 1
						AND cL_isOkCountry = 1
					THEN 1
					ELSE 0
				END								AS [cL_mandaTags_isOkCountryFactsheet] ,

			CASE WHEN cL_isOkLargeCountries = 1 
						AND cL_isOkThalesGeography = 1
						AND cL_isOkCountry = 1
						AND cL_isOkWorldwidCredentials = 1
						AND cL_isOkCountryPage = 1
					THEN 1
					ELSE 0
				END								AS [cL_mandaTags_isOkCountryPageLargeCountries] ,

			CASE WHEN cL_isOkDgdi = 1 
						AND cL_isOkThalesGeography = 1
						AND cL_isOkCountry = 1
						AND cL_isOkWorldwidCredentials = 1
						AND cL_isOkCountryPage = 1
					THEN 1
					ELSE 0
				END								AS [cL_mandaTags_isOkCountryPageDgdi] 
		/*************************************/

		FROM cL_tagCategory_KPIs
	)

	/* Liste des valeurs de tags pour chaque Catégorie de tag
	*********************************************************/
	,
	cLargeCountries 
	AS
	(
		SELECT cAssetId , STRING_AGG( cLargeCountries , ' , ') AS cLLargeCountries
			FROM
			(
				SELECT    assetId		AS cAssetId , 
						 t.[name]		AS cLargeCountries
				FROM [trd].[ASSETS] a		
				INNER JOIN [trd].[ASSET_TAGS] s ON s.assetId_hash = a.assetId_hash
				INNER JOIN [trd].[TAGS] t ON t.tagId_hash = s.tagId_hash
				WHERE  LOWER(t.[name]) = 'LARGE COUNTRIES'	
			) AS G
			GROUP BY cAssetId
	) 
	,
	cDgdi
	AS
	(
		SELECT cAssetId , STRING_AGG( cDgdi , ' , ') AS cLDgdi
			FROM
			(
				SELECT    assetId		AS cAssetId , 
						 t.[name]		AS cDgdi
				FROM [trd].[ASSETS] a		
				INNER JOIN [trd].[ASSET_TAGS] s ON s.assetId_hash = a.assetId_hash
				INNER JOIN [trd].[TAGS] t ON t.tagId_hash = s.tagId_hash
				WHERE  LOWER(t.[name]) = 'LARGE COUNTRIES'	
			) AS G
			GROUP BY cAssetId
	) 
	,
	cListGbuCtrl /* Par asset, liste de GBU depuis les TAGS / TAG CATEGORIES */
	AS
	(
		SELECT cAssetId , STRING_AGG( cGbu , ' , ') AS cLGbu
			FROM
			(
				SELECT    assetId		AS cAssetId , 
						 t.[name]		AS cGbu
				FROM [trd].[ASSETS] a		
				INNER JOIN [trd].[ASSET_TAGS] s ON s.assetId_hash = a.assetId_hash
				INNER JOIN [trd].[TAGS] t ON t.tagId_hash = s.tagId_hash
				WHERE  LOWER(t.[name]) IN (SELECT DISTINCT gbu_name FROM rfd.ASSETS_BL WHERE gbu_name <> 'OFF GBU' )	
			) AS G
			GROUP BY cAssetId
	) -- select top 100 * from cListGbuCtrl 
	,	
	cListBlCtrl /* Par asset, liste de BL depuis les TAGS / TAG CATEGORIES */
	AS
	(

 		SELECT cAssetId , STRING_AGG( cBl , ' , ') AS cLBl
		FROM
		(
			SELECT    assetId		AS cAssetId , 
					 t.[name]		AS cBl
			FROM [trd].[ASSETS] a		
			INNER JOIN [trd].[ASSET_TAGS] s ON s.assetId_hash = a.assetId_hash
			INNER JOIN [trd].[TAGS] t ON t.tagId_hash = s.tagId_hash
			WHERE  LOWER(t.[name]) IN (SELECT DISTINCT bl_name FROM rfd.ASSETS_BL WHERE bl_name <> 'OFF BL' )	
		) AS G
		GROUP BY cAssetId
	) -- select top 100 * from cListBlCtrl where cAssetId = 70
	,
	cListMktSgmt
	AS
	(
		SELECT cAssetId , STRING_AGG( cMarketSegment , ' , ') AS cLMarketSegment
		FROM
		(
			SELECT DISTINCT
					assetId		AS cAssetId
				  , segment		AS cMarketSegment 
			FROM rfd.ASSETS_SEGMENT
			WHERE idSegment <> -1
		) AS G
		GROUP BY cAssetId
	)
	,
	cListMktSubSgmt
	AS
	(
		SELECT cAssetId , STRING_AGG( cMarketSubSegment , ' , ') AS cLMarketSubSegment
		FROM
		(
			SELECT assetId		 AS cAssetId , 
				  sub_segment	AS cMarketSubSegment 
			FROM rfd.ASSETS_SUB_SEGMENT
			WHERE id_sub_segment <> -1
		) AS G
		GROUP BY cAssetId
	)
	,
	cListProdLine
	AS
	(
		SELECT cAssetId , STRING_AGG( cProductLine , ' , ') AS cLProductLine
		FROM
		(
			SELECT    assetId		AS cAssetId , 
					 t.[name]	AS cProductLine
			FROM [trd].[ASSETS] a
			INNER JOIN [trd].[ASSET_TAGS] s ON s.assetId_hash = a.assetId_hash
			INNER JOIN [trd].[TAGS] t ON t.tagId_hash = s.tagId_hash
			WHERE  LOWER(t.[name]) IN (SELECT LOWER(tagName) FROM trd.REF_HID_PRODUCT_LINE)	
		) AS G
		GROUP BY cAssetId
	)
	,
	cListProdName
	AS
	(
		SELECT cAssetId , STRING_AGG( cProductName , ' , ') AS cLProductName 
		FROM
		(
			SELECT assetId		AS cAssetId , 
				   productTag	AS cProductName
			FROM rfd.ASSETS_PRODUCT
		) AS G
		GROUP BY cAssetId
	)
	,
	cListTypeContent
	AS
	(
		SELECT cAssetId , STRING_AGG( cTypeContent , ' , ') AS cLTypeContent
		FROM
		(
			SELECT DISTINCT
					assetId		AS cAssetId
				  , contentTag	AS cTypeContent 
			FROM rfd.ASSETS_CONTENT_TYPE
			WHERE idContent <> -1
		) AS G
		GROUP BY cAssetId
	)
	,
	cListSensitivity
	AS
	(
		SELECT cAssetId , STRING_AGG( cSensitivity , ' , ') AS cLSensitivity
		FROM
		(
			SELECT DISTINCT
					assetId				AS cAssetId
				  , sensitivityTag		AS cSensitivity	
			FROM rfd.ASSETS_SENSITIVITY
			WHERE idSensitivity <> -1
			

		) AS G
		GROUP BY cAssetId
	)
	,
	cListCountry
	AS
	(
		SELECT cAssetId , STRING_AGG( cCountry , ' , ') AS cLCountry
		FROM
		(
			SELECT DISTINCT
					assetId		AS cAssetId
				  , country		AS cCountry 
			FROM rfd.ASSETS_COUNTRY
			WHERE idCountry <> -1
			

		) AS G
		GROUP BY cAssetId
	)
	,
	cListRegion
	AS
	(
		SELECT cAssetId , STRING_AGG( cRegion , ' , ') AS cLRegion
		FROM
		(
			SELECT    assetId			AS cAssetId
					, t.[name]			AS cRegion
			FROM [trd].[ASSETS] a
			INNER JOIN [trd].[ASSET_TAGS] s ON s.assetId_hash = a.assetId_hash
			INNER JOIN [trd].[TAGS] t ON t.tagId_hash = s.tagId_hash
			WHERE  LOWER(t.[name]) IN (SELECT LOWER(tagName) FROM trd.REF_GEOGRAPHY)			
		) AS G
		GROUP BY cAssetId
	)
	,
	cWorldCredentials
	AS
	(
		SELECT cAssetId , STRING_AGG( cWorldCredentials , ' , ') AS cLWorldCredentials
		FROM
		(
			SELECT    assetId			AS cAssetId
					, t.[name]			AS cWorldCredentials
			FROM [trd].[ASSETS] a
			INNER JOIN [trd].[ASSET_TAGS] s ON s.assetId_hash = a.assetId_hash
			INNER JOIN [trd].[TAGS] t ON t.tagId_hash = s.tagId_hash
			WHERE  LOWER(t.[name]) = 'Worldwide Credentials'			
		) AS G
		GROUP BY cAssetId
	)
	,
	cCountryPage
	AS
	(
		SELECT cAssetId , STRING_AGG( cCountryPage , ' , ') AS cLCountryPage
		FROM
		(
			SELECT    assetId			AS cAssetId
					, t.[name]			AS cCountryPage
			FROM [trd].[ASSETS] a
			INNER JOIN [trd].[ASSET_TAGS] s ON s.assetId_hash = a.assetId_hash
			INNER JOIN [trd].[TAGS] t ON t.tagId_hash = s.tagId_hash
			WHERE  LOWER(t.[name]) = 'Country Page'			
		) AS G
		GROUP BY cAssetId
	)
	,
	cListTagChannels
	AS
	(
		SELECT cAssetId , STRING_AGG( cChannel , ' , ') AS cLChannel 
		FROM
		(
			SELECT    assetId			AS cAssetId
					, t.[name]			AS cChannel
			FROM [trd].[ASSETS] a
			INNER JOIN [trd].[ASSET_TAGS] s ON s.assetId_hash = a.assetId_hash
			INNER JOIN [trd].[TAGS] t ON t.tagId_hash = s.tagId_hash
			WHERE  LOWER(t.[name]) IN ( SELECT chnl_name FROM cL_ListChannels )		
		) AS G
		GROUP BY cAssetId
	) --select * from cListTagChannels
	,
	cListTypeLandingPage /* Mission page, Overview Page, etc */
	AS
	(
		SELECT cAssetId , STRING_AGG( cTypeLandingPage , ' , ') AS cLTypeLandingPage
		FROM
		(
			SELECT    assetId			AS cAssetId
					, t.[name]			AS cTypeLandingPage
			FROM [trd].[ASSETS] a
			INNER JOIN [trd].[ASSET_TAGS] s ON s.assetId_hash = a.assetId_hash
			INNER JOIN [trd].[TAGS] t ON t.tagId_hash = s.tagId_hash
			WHERE  LOWER(t.[name]) IN ( SELECT ctTyp_name FROM rfd.vw_DIM_CONTENT_TYPE_PAGE_TYPE WHERE ctTyp_id IS NULL ) 			
		) AS G
		GROUP BY cAssetId
	) -- select top 1000 * from cListTypeLandingPage
	/*********************************************************/
/*	,
	-- Doublons sur Displayname et liste des auteurs (ID Asset sont distincts) // pour le compteur "Ano Duplicated Content" --
	cAnoDupliDblnDisplayNamePrep
	AS
	(
			SELECT A.cAssetId , 				
					STRING_AGG( CAST(A.cAuthorId AS NVARCHAR(10)) , ' , ') WITHIN GROUP( ORDER BY A.cAuthorId ASC )  AS cLAuthorId 	
			FROM 
				(
					SELECT	DISTINCT 
							  aa.assetId			AS cAssetId 
							, u.usr_id				AS cAuthorId
					FROM rfd.ASSETS_AUTHOR aa left join rfd.vw_DIM_USERS u ON ( aa.userId = u.usr_id )
					WHERE aa.userId <> -1
				) AS A 
			GROUP BY cAssetId 

/*
		SELECT	aut.cAssetId		AS [dblDup_assetId], 
				--cAssetNameAuthor	AS [dblDup_NameAuthor],
				-- ast.displayName	+ ';' + aut.cAuthor 
									--AS [dblDup_assetNameAuthor], 
				COUNT(*) OVER( PARTITION BY ast.displayName , aut.cAuthor ) -- cAssetNameAuthor ) -- 
									AS [dblDup_nb]
		FROM cListAuthors aut INNER JOIN cAss ast ON (aut.cAssetId = ast.assetId)
		--WHERE ast.assetId IS NOT NULL
*/
	) -- 	select * from cAnoDupliDblnDisplayNamePrep

	,
	cAnoDupliDblnDisplayName
	AS
	(
		SELECT	ast.displayName , aut.cLAuthorId , 
				COUNT(*) [dblDup_nb]
		FROM cAnoDupliDblnDisplayNamePrep aut 
				INNER JOIN cAss ast ON (aut.cAssetId = ast.assetId)
/*
				LEFT JOIN trd.DIVISIONS div ON (div.divisionId = ast.divisionId)
		WHERE ast.[archivedAt] IS NULL 
			AND ast.[deletedAt] IS NULL 
			AND div.divisionId IS NOT NULL -- For Asset, division is 'Live'
			AND ast.[type] NOT IN ('audio', 'raw') 
			AND ast.[source] <> 'user generated'
			AND ast.[status] = 'active'
*/
		GROUP BY ast.displayName , aut.cLAuthorId 
/*
		SELECT	aut.cAssetId		AS [dblDup_assetId], 
				--cAssetNameAuthor	AS [dblDup_NameAuthor],
				-- ast.displayName	+ ';' + aut.cAuthor 
									--AS [dblDup_assetNameAuthor], 
				COUNT(*) OVER( PARTITION BY ast.displayName , aut.cLAuthorId ) -- cAssetNameAuthor ) -- 
									AS [dblDup_nb]
		FROM cAnoDupliDblnDisplayNamePrep aut INNER JOIN cAss ast ON (aut.cAssetId = ast.assetId)
*/
	)--	select * from cAnoDupliDblnDisplayName
*/
	,
	cListTagsConsolides /* Par asset, liste des tags selon la typologie */
	AS
	(
			SELECT 	ass.assetId							AS [clistTags_assetId] ,

						ass.divisionId ,
						ass.[archivedAt] ,
						ass.[deletedAt],
						 ass.[type] ,
						 ass.[source] ,
						 ass.[status] ,

					cLMktSgmt.cLMarketSegment			AS [cLMarketSegment] ,
					cLMktSubSgmt.cLMarketSubSegment		AS [cLMarketSubSegment] ,
					cLProdLine.cLProductLine			AS [cLProductLine] ,
					cLProdName.cLProductName			AS [cLProductName] ,
					cLtypeContent.cLTypeContent			AS [cLTypeContent] ,
					cLSensitivity.cLSensitivity			AS [cLSensitivity] ,
					cLCountry.cLCountry					AS [cLCountry] ,
					cLRegion.cLRegion					AS [cLRegion] ,
					lgCtr.cLGbu							AS [cLGbu] ,
					lgbCtr.cLBl							AS [cLBl] ,
					cWrldCred.cLWorldCredentials		AS [cLWorldCredentials] ,
					cCntryPage.cLCountryPage			AS [cLCountryPage] ,
					cLChannels.cLChannel				AS [cLChannel] ,
					cLLandingPage.cLTypeLandingPage		AS [cLTypeLandingPage] ,
					CLrgCtrny.cLLargeCountries			AS [cLLargeCountries] ,
					cDgdi.cLDgdi						AS [cLDgdi] ,

					/***** 5 typologies *****/
--/*
					ass.displayName + ';' +
					ISNULL( cLGbu , '' ) + ';' + ISNULL( cLBl , '' ) + ';' +  
					ISNULL( cLMarketSegment , '' ) + ';' +  ISNULL( cLMarketSubSegment , '' ) + ';' + ISNULL( cLProductLine , '' ) + ';' +  ISNULL( cLProductName , '' ) + ';' +  ISNULL( cLTypeContent , '' )  + ';' +  ISNULL( cLSensitivity , '' ) 
														AS [clistTags_Asset] ,

					ass.displayName + ';' +
					ISNULL( cLGbu , '' ) + ';' + ISNULL( cLBl , '' ) + ';' +  
					ISNULL( cLChannels.cLChannel , '' ) + ';' + ISNULL( cLLandingPage.cLTypeLandingPage , '' )  
														AS [clistTags_LandingPage] ,
					ass.displayName + ';' +
					ISNULL( cDgdi.cLDgdi , '' ) + ';' + 
					ISNULL( cLtypeContent.cLTypeContent , '' )  + ';' + ISNULL( cLSensitivity.cLSensitivity , '' ) + ';' + ISNULL( cLRegion.cLRegion , '' ) + ';' + ISNULL( cLCountry.cLCountry , '' ) 
														AS [clistTags_CountryFactsheet] ,

					ass.displayName + ';' +
					ISNULL( cDgdi.cLDgdi , '' ) + ';' + 
					ISNULL( cLRegion.cLRegion , '' ) + ';' + ISNULL( cLCountry.cLCountry , '' ) + ';' + ISNULL( cWrldCred.cLWorldCredentials , '' )  + ';' + ISNULL( cCntryPage.cLCountryPage , '' )  
														AS [clistTags_CountryPageDgdi]  ,

					ass.displayName + ';' +
					ISNULL( CLrgCtrny.cLLargeCountries , '' ) + ';' + 
					ISNULL( cLRegion.cLRegion , '' ) + ';' + ISNULL( cLCountry.cLCountry , '' ) + ';' + ISNULL( cWrldCred.cLWorldCredentials , '' )  + ';' + ISNULL( cCntryPage.cLCountryPage , '' )  
														AS [clistTags_CountryPageLargeCountries] ,
--*/
					/*****************************/

					/***** Liste de tags obligatoires => Pour identifier les duplicated de l'anomalie "Dyplicated Content" *****/

					ass.displayName + ';' +
					ISNULL( cLGbu , '' ) + ';' + ISNULL( cLBl , '' ) + ';' +  
					ISNULL( cLMarketSegment , '' ) + ';' +  ISNULL( cLMarketSubSegment , '' ) + ';' + ISNULL( cLProductLine , '' ) + ';' +  ISNULL( cLProductName , '' ) + ';' +  ISNULL( cLTypeContent , '' )  + ';' +  ISNULL( cLSensitivity , '' ) + ';' +
					ISNULL( cLRegion.cLRegion , '' ) + ';' + ISNULL( cLCountry.cLCountry , '' ) + ';' + ISNULL( cWrldCred.cLWorldCredentials , '' )  + ';' + ISNULL( cCntryPage.cLCountryPage , '' )   + ';' +
					ISNULL( cLChannels.cLChannel , '' ) + ';' + ISNULL( cLLandingPage.cLTypeLandingPage , '' )  

														AS [clistTags_anoDup_mandatory]
	
					--IIF( dblDup_nb > 1 , 1 , 0)
					--									AS [clistTags_anoDup_isDblnNameAuthors]
					
					--,dblDup_nb 							
					--,dblDup_assetAuthors
					/***********************************************************************************************************/

			FROM   cAss ass 
					LEFT JOIN cListMktSgmt cLMktSgmt
					ON ass.assetId = cLMktSgmt.cAssetId /* List of Market Segemnts by Asset */

					LEFT JOIN cListMktSubSgmt cLMktSubSgmt
					ON ass.assetId = cLMktSubSgmt.cAssetId /* List of Market Sub-Segemnts by Asset */		

					LEFT JOIN cListProdLine cLProdLine
					ON ass.assetId = cLProdLine.cAssetId /* List of Types of content by Asset */			

					LEFT JOIN cListProdName cLProdName
					ON ass.assetId = cLProdName.cAssetId /* List of Product Names by Asset */														
	
					LEFT JOIN cListTypeContent cLtypeContent
					ON ass.assetId = cLtypeContent.cAssetId /* List of Product Lines by Asset */		

					LEFT JOIN cListSensitivity cLSensitivity
					ON ass.assetId = cLSensitivity.cAssetId /* List of Sensitivity Tags by Asset */		

					LEFT JOIN cListCountry cLCountry
					ON ass.assetId = cLCountry.cAssetId /* List of Country by Asset */
													
					LEFT JOIN cListRegion cLRegion
					ON ass.assetId = cLRegion.cAssetId /* List of Region by Asset */		
														
					LEFT JOIN cListGbuCtrl lgCtr /* List of GBU by Asset (from TAGS directly) */	
					ON 	ass.assetId = lgCtr.cAssetId 	
														
					LEFT JOIN cListBlCtrl lgbCtr /* List of BL by Asset (from TAGS directly) */	
					ON ass.assetId = lgbCtr.cAssetId 
											
					LEFT JOIN cWorldCredentials cWrldCred /* TAG = 'World Credentials' */
					ON ass.assetId = cWrldCred.cAssetId 

					LEFT JOIN cCountryPage cCntryPage /* TAG = 'Country Page' */
					ON ass.assetId = cCntryPage.cAssetId 

					LEFT JOIN cListTagChannels cLChannels /* List of Channels by Asset (NOT EXPERIENCE !) */	
					ON ass.assetId = cLChannels.cAssetId 

					LEFT JOIN cListTypeLandingPage cLLandingPage /* Mission page , Overview page ... */
					ON ass.assetId = cLLandingPage.cAssetId 																									   

					LEFT JOIN cLargeCountries CLrgCtrny /* TAG = 'Large Countries' */
					ON ass.assetId = CLrgCtrny.cAssetId
													
					LEFT JOIN cDgdi /* TAG = 'DGDI' */
					ON ass.assetId = cDgdi.cAssetId 

						--LEFT JOIN cAnoDupliDblnDisplayName dblDup
						--ON ass.assetId = dblDup.dblDup_assetId 
	) -- select * into #cListTagsConsolides from cListTagsConsolides -- select * from #cListTagsConsolides 
/*
	,
	-- Doublons sur Displayname et liste des tags obligatoires (ID Asset sont distincts) // pour le compteur "Ano Duplicated Content" --
	cAnoDupliDblnMandaTags
	AS
	(
		SELECT 	clistTags_assetId				AS [cAnoDup_assetId] ,
				COUNT(*) OVER( PARTITION BY clistTags_anoDup_mandatory ) /* Display + mandatory tags (if filled in) */
												AS [cAnoDup_nBDblnNameMandaTags] 
		FROM cListTagsConsolides ast
/*						LEFT JOIN trd.DIVISIONS div ON (div.divisionId = ast.divisionId)
		WHERE ast.[archivedAt] IS NULL 
						AND ast.[deletedAt] IS NULL 
						AND div.divisionId IS NOT NULL -- For Asset, division is 'Live'
						AND ast.[type] NOT IN ('audio', 'raw') 
						AND ast.[source] <> 'user generated'
						AND ast.[status] = 'active'
*/
	) --select * from cAnoDupliDblnMandaTags
*/	,
	cAssetsFinal
	AS
	(
	SELECT DISTINCT 
		  ass.assetId							AS [ast_id]	
		, ass.displayName						AS [ast_displayName] 
		, ass.[status]							AS [ast_status]	
		, ass.[source]							AS [ast_source]	
		, ass.[description]						AS [ast_description]	
		, ass.[type]							AS [ast_type]
		, ass.contentFormat						AS [ast_contentFormat]
		, ass.isSensitive						AS [ast_isSensitive]
		, ass.isShareable						AS [ast_isShareable]
		, ass.isDownloadable					AS [ast_isDownloadable]
		, ass.isDivisionShared					AS [ast_isDivisionShared]
		, ass.isAnnotatable						AS [ast_isAnnotatable]
		, ass.externalId						AS [ast_externalId]
		, ass.commentsCount						AS [ast_commentsCount]
		, ass.likesCount						AS [ast_likesCount]
		
		, CAST( ass.[expiresAt]	AS DATE )		AS [astC_expiresAt]
		, CAST( ass.[releasedAt] AS DATE )		AS [astC_releasedAt]
		, CAST( ass.[deletedAt]	AS DATE )		AS [astC_deletedAt]
		, CAST( ass.[uploadedAt] AS DATE )		AS [astC_uploadedAt]
		, CAST( ass.[archivedAt] AS DATE )		AS [astC_archivedAt]
		, CAST( ass.[updatedAt]	AS DATE )		AS [astC_updatedAt]

		-- [ERJ 2022-05-17 -- Adding pivot Date beetween Updateed Date and Uploaded Date using the most recently]	
		-- [This pivot date will be using to link Asset table to Asset Calendar table]
		-- [Date was generated into CTE to be using ]
		, ass.[astC_FrechnessDt]
		  
		, ass.optimizedFileSize					AS [ast_optimizedFileSize] 
		
		-- Complete for tracking and control [Adding by ERJ 2022-05-13]
		 , ass.assetId_hash						AS [astF_idHash]	
		 , ass.divisionId						AS [astF_divisionId]
		
		, CASE WHEN DATEADD( MONTH , 
					   (SELECT -[PeriodMonths] FROM cPeriodCalc) , 
					   CAST( GETDATE() AS DATE ) ) 
			  <= CAST( ass.uploadedAt AS DATE )
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END									AS [astC_isNew] /* Flag to identify new content */  -- [Modify ERJ 20220513] Cast as Bit

		, CASE WHEN div.assetId IS NOT NULL 
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END									AS [astC_isLiveDivision]  -- [Modify ERJ 20220513] Cast as Bit	
		
		, CASE WHEN la.cAuthor /*aut.cAssetId*/ IS NOT NULL 
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END									AS [astC_hasAuthor]	/* Flag if asset has one really active author at least */
		
		, CASE WHEN (ass.optimizedFileSize / 1024 /1024 ) > 200 /* Convert KBytes to MBytes */
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END									AS [astC_isMore200MO]  -- [Modify ERJ 20220513] Cast as Bit	
		
		, CASE WHEN ass.isDownloadable = 0 AND LOWER(ass.displayName) NOT LIKE '%.showpadpage%' AND ass.contentFormat <> 'url'
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END									AS [astC_isNotDownloadable]  -- [Modify ERJ 20220513] Cast as Bit	
		
		, CASE WHEN ass.isDivisionShared = 0 
			AND LOWER(ass.[type]) <> 'page'
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END									AS [astC_isGlobalParameterMissing] -- [Modify ERJ 20220513] Cast as Bit
		
		, CASE WHEN sen.cAssetId IS NULL /* No sensitivy tag for the asset */ 
			AND LOWER(ass.displayName) NOT LIKE '%.showpadpage%'
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END									AS [astC_isSensitivityTagMissing]	-- [Modify ERJ 20220513] Cast as Bit	
		
		, CASE WHEN assDup.cDisplayName IS NOT NULL /* asset is duplicated on display name */ 
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END									AS [astC_hasDuplicatedName]	-- [Modify ERJ 20220513] Cast as Bit	
		
		, CASE WHEN evt.evtF_assetId IS NULL
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END									AS [astC_isAnormalyTagging]	-- [Modify ERJ 20220513] Cast as Bit /* Pas de Channel pour l'Asset parmi une des 6 expériences (Civil Market, Customer Interests ...) */			

		, CASE WHEN ( ass.archivedAt IS NULL or ass.deletedAt IS NULL ) 
				AND c3.cAssetId IS NOT NULL /* Il existe un asset avec sensitivity C3 (crypté) */
			THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END									AS [astC_isSensitivityC3]	

		  -- [ERJ 2022-05-17 -- Adding a pointer corresponding to the criteria for including the asset in the count of Share ]
		  ,CAST( 
			   IIF (
						ass.[deletedAt] IS NULL 
						AND div.assetId IS NOT NULL -- For Asset, division is 'Live'
						AND ass.[source] = 'marketing' 
						AND ass.[status] = 'active'
						,1
						,0
					) 
				AS BIT)							AS [astC_isAssetCount]

		  -- [ERJ 2022-05-17 -- Adding a pointer corresponding to the criteria for including the asset in the count ]
		  ,CAST( 
			   IIF (
						ass.[archivedAt] IS NULL 
						AND ass.[deletedAt] IS NULL 
						AND div.assetId IS NOT NULL -- For Asset, division is 'Live'
						AND ass.[type] NOT IN ('audio', 'raw') 
						AND ass.[source] <> 'user generated'
						--AND ass.[source] = 'marketing' 
						AND ass.[status] = 'active'
						,1
						,0
					) 
				AS BIT)							AS [astC_isContentCount]

		  ,CAST( 
			   IIF (
							div.assetId IS NOT NULL  -- For Asset, division is 'Live'
						AND ass.[source] = 'marketing' 
						AND ass.[status] = 'active'
						,1
						,0
					) 
				AS BIT)							AS [astC_isShareCount]
				
			-- [ERJ 2022-05-17-- Rename] Use flag to categorize period of uploded or updated asset 
			/* Flags d'intervalles de dates => obsolètes */
			,CAST(
				IIF( 
					 DATEADD(MONTH, -6, GETDATE()) <= ass.[astC_FrechnessDt]
					,1
					,0
					) AS BIT)					AS [astC_isInPeriodLast6Months]

			,CAST(
				IIF( 
					 DATEADD(MONTH, -12, GETDATE()) <= ass.[astC_FrechnessDt] 
						AND ass.[astC_FrechnessDt] < DATEADD(MONTH, -6, GETDATE())
					,1
					,0
					) AS BIT)					AS [astC_isInPeriod12-6MonthsBefore]

			,CAST(
				IIF( 
					 DATEADD(MONTH, -24, GETDATE()) <= ass.[astC_FrechnessDt] 
						AND ass.[astC_FrechnessDt] < DATEADD(MONTH, -12, GETDATE())
					,1
					,0
					) AS BIT)					AS [astC_isInPeriod24-12MonthsBefore]

			,CAST(
				IIF( 
					 ass.[astC_FrechnessDt] < DATEADD(MONTH, -24, GETDATE())
					,1
					,0) AS BIT)					AS [astC_isInPeriodOver24Months]

			,CAST(
				IIF( 
					 DATEADD(MONTH, -6, GETDATE()) <= ass.[uploadedAt]
					,1
					,0
					) AS BIT)					AS [astC_isUplodedInPeriodLast6Months]

			,CAST(
				IIF( 
					 DATEADD(MONTH, -6, GETDATE()) <= ass.[updatedAt]
					,1
					,0
					) AS BIT)					AS [astC_isUpdatedInPeriodLast6Months]

			, CAST(
					IIF( LOWER(ass.displayName) NOT LIKE '%.showpadpage%'
					,0
					,1
					) AS BIT)					AS [astC_isShowpadpage] /* deduplicate Display Name 'showpad' & starTime (with hour) for calculate Recipients Views */
			, 
			la.cAuthor							AS [astC_listAuthor]
			, 
			lg.cGBU								AS [astC_listGbu]
			, 
			lgb.cGBUBl							AS [astC_listGbuBl]
			, 
			CASE WHEN ass.[archivedAt] IS NOT NULL 
						THEN ' Archived'
						ELSE ' Live' 
			END									AS [astC_isArchived]
			,
			ass.displayName + ';' + lat.lt_list_tag
												AS [astC_displayNameListTags] /* Display name + All associated tags */
			,

			/****** XNG // Champs temporaires pour la recette **********/		
--/*
			cL_isOkLargeCountries				AS [astC_isOkLargeCountries] ,
			cL_isOkDgdi							AS [astC_isOkDgdi] ,
			cL_isOkGbu							AS [astC_isOkGbu] ,
			cL_isOkBl							AS [astC_isOkBl] ,

			cL_isOkMarketSgmt 					AS [astC_isOkMarketSgmt]  ,
			cL_isOkMarketSubSgmt 				AS [astC_isOkMarketSubSgmt] ,
			cL_isOkProductLine 					AS [astC_isOkProductLine]  ,
			cL_isOkProductName 					AS [astC_isOkProductName] ,
			cL_isOkTypeContent 					AS [astC_isOkTypeContent] ,
			cL_isOkSensitivity 					AS [astC_isOkSensitivity] ,
			cL_isOkThalesGeography 				AS [astC_isOkThalesGeography] ,
			cL_isOkCountry 						AS [astC_isOkCountry] ,

			cL_isOkWorldwidCredentials			AS [astC_isOkWorldwidCredentials], 
			cL_isOkCountryPage					AS [astC_isOkCountryPage], 
			cL_isOkChannel						AS [astC_isOkChannel] ,
			cL_isOkTypeLandingPage				AS [astC_isOkTypeLandingPage] ,
/*
			cLLargeCountries AS [astC_LargeCountries] ,
			cLDgdi AS [astC_Dgdi] ,
			cLGbu AS [astC_Gbu] ,
			cLBl AS [astC_Bl] ,
			cLMarketSegment AS [astC_MarketSegment] ,
			cLMarketSubSegment AS [astC_MarketSubSegment] ,
			cLProductLine AS [astC_ProductLine] ,
			cLProductName AS [astC_ProductName] ,
			cLTypeContent AS [astC_TypeContent] ,
			cLSensitivity AS [astC_Sensitivity] ,
			cLCountry AS [astC_Country] ,
			cLRegion AS [astC_Region] ,
			cLWorldCredentials AS [astC_WorldCredentials] ,
			cLCountryPage AS [astC_CountryPage] ,
			cLChannel AS [astC_Channel] ,
			cLTypeLandingPage AS [astC_TypeLandingPage] ,
*/
 --*/
			/********************************************************/

			/******* Check chaîne de tags 100% valides *******/
--/*
			cL_mandaTags_isOkAsset				AS [astC_mandaTags_isOkAsset] ,

			cL_mandaTags_isOkLandingPage		AS [astC_mandaTags_isOkLandingPage] ,

			cL_mandaTags_isOkCountryFactsheet	AS [astC_mandaTags_isOkCountryFactsheet] ,

			cL_mandaTags_isOkCountryPageLargeCountries			
												AS [astC_mandaTags_isOkCountryPageLargeCountries] ,

			cL_mandaTags_isOkCountryPageDgdi	AS [astC_mandatoryTags_isOkCountryPageDgdi] ,
--*/
			/**************************************************/


			/***** Concaténer les tags définis selon les 5 chaînes de tags *****/
/*
			ltc.clistTags_Asset					AS [astC_mandaTags_listTags_Asset] ,

			ltc.clistTags_LandingPage			AS [astC_mandaTags_listTags_LandingPage] ,

			ltc.clistTags_CountryFactsheet		AS [astC_mandaTags_listTags_CountryFactsheet] ,

			ltc.clistTags_CountryPageDgdi		AS [astC_mandaTags_listTags_CountryPageDgdi] ,

			ltc.clistTags_CountryPageLargeCountries
											AS [astC_mandaTags_CountryPageLargeCountries] ,
*/	
			/******************************************************************/

			/***** Flag final pour le compteur "" Anormal Tagging* : Si "isOkMandatoryTags" = 0 alors 1 sinon 0 ****/
			CASE WHEN ( cL_mandaTags_isOkAsset + cL_mandaTags_isOkLandingPage + cL_mandaTags_isOkCountryFactsheet + cL_mandaTags_isOkCountryPageLargeCountries + cL_mandaTags_isOkCountryPageDgdi ) >= 1
					THEN 1 /*  Au moins une chaîne de tags 100% valide => OK pour ce contenu */
				ELSE 0	/* Aucune chaîne de tags 100% valide => OK pour ce contenu */
			END									AS [astC_isOkMandatoryTags] ,

			/***** Liste de tags obligatoires => Pour identifier les duplicated de l'anomalie "Duplicated Content" *****/				
			-- "Duplicated Content" doublons : DisplayName + list Authors --
			CASE WHEN ass.[archivedAt] IS NULL /* Is Content Count */
						AND ass.[deletedAt] IS NULL 
						AND div.assetId IS NOT NULL -- For Asset, division is 'Live'
						AND ass.[type] NOT IN ('audio', 'raw') 
						AND ass.[source] <> 'user generated'
						AND ass.[status] = 'active'
					THEN ass.displayName + ';' + la.cAuthor 	
			END					AS dupContent ,
		
			-- "Duplicated Content" doublons : DisplayName + Mandatory Tags --
			CASE WHEN ass.[archivedAt] IS NULL /* Is Content Count */
						AND ass.[deletedAt] IS NULL 
						AND div.assetId IS NOT NULL -- For Asset, division is 'Live'
						AND ass.[type] NOT IN ('audio', 'raw') 
						AND ass.[source] <> 'user generated'
						AND ass.[status] = 'active'
					THEN ass.displayName + ';' +lmt.lt_list_tag	
					ELSE NULL 
			END					AS lt_list_tag
			/***********************************************************/

	FROM   cAss ass 
			LEFT JOIN cDivision div
			ON ass.assetId = div.assetId
				LEFT JOIN cAuthor aut
				ON ass.assetId = aut.cAssetId
				AND aut.rankAuthor = 1
					LEFT JOIN cSensitivity sen
					ON ass.assetId = sen.cAssetId
						LEFT JOIN cAssetsDuplicate assDup
						ON ass.displayName = assDup.cDisplayName
							LEFT JOIN cEvtInChannels evt
							ON ass.assetId = evt.evtF_assetId
								
								LEFT JOIN cListAuthors la
								ON ass.assetId = la.cAssetId 
									LEFT JOIN cListGbu lg
									ON ass.assetId = lg.cAssetId 
										LEFT JOIN cListGbuBl lgb
										ON ass.assetId = lgb.cAssetId 

											LEFT JOIN cSensitivityC3 c3
											ON ass.assetId = c3.cAssetId

												LEFT JOIN cL_tagCategory_KPIsConsolides lat -- cL_tagCategory_KPIs lat
												ON ass.assetId_hash = lat.lt_assetIdHash

												LEFT JOIN cListTagsConsolides ltc
												ON ass.assetId = ltc.clistTags_assetId

													LEFT JOIN cL_ListMandaTags lmt
													ON ass.assetId_hash = lmt.ltc_assetIdHash

													--LEFT JOIN cAnoDupliDblnMandaTags dblAnoDup
													--ON ass.assetId = dblAnoDup.cAnoDup_assetId

													--LEFT JOIN cAnoDupliDblnDisplayName dblDupName
													--ON ass.assetId = dblDupName.dblDup_assetId 
	)
	SELECT  ast_id , 
		ast_displayName , 
		ast_status , 
		ast_source , 
		ast_description , 
		ast_type , 
		ast_contentFormat , 
		ast_isSensitive , 
		ast_isShareable , 
		ast_isDownloadable , 
		ast_isDivisionShared , 
		ast_isAnnotatable , 
		ast_externalId , 
		ast_commentsCount , 
		ast_likesCount , 
		astC_expiresAt , 
		astC_releasedAt , 
		astC_deletedAt , 
		astC_uploadedAt , 
		astC_archivedAt , 
		astC_updatedAt , 
		astC_FrechnessDt , 
		ast_optimizedFileSize , 
		astF_idHash , 
		astF_divisionId , 
		astC_isNew , 
		astC_isLiveDivision , 
		astC_hasAuthor , 
		astC_isMore200MO , 
		astC_isNotDownloadable , 
		astC_isGlobalParameterMissing , 
		astC_isSensitivityTagMissing , 
		astC_hasDuplicatedName , 
		astC_isAnormalyTagging , 
		astC_isSensitivityC3 , 
		astC_isAssetCount , 
		astC_isContentCount , 
		astC_isShareCount , 
		astC_isInPeriodLast6Months , 
		[astC_isInPeriod12-6MonthsBefore] , 
		[astC_isInPeriod24-12MonthsBefore] , 
		astC_isInPeriodOver24Months , 
		astC_isUplodedInPeriodLast6Months , 
		astC_isUpdatedInPeriodLast6Months , 
		astC_isShowpadpage , 
		astC_listAuthor , 
		astC_listGbu , 
		astC_listGbuBl , 
		astC_isArchived , 
		astC_displayNameListTags , 

--/*
		astC_isOkLargeCountries ,
		astC_isOkDgdi ,
		astC_isOkGbu ,
		astC_isOkBl ,
		astC_isOkMarketSgmt	  ,
		astC_isOkMarketSubSgmt	 ,
		astC_isOkProductLine	  ,
		astC_isOkProductName	 ,
		astC_isOkTypeContent	 ,
		astC_isOkSensitivity	 ,
		astC_isOkThalesGeography	 ,
		astC_isOkCountry	 ,
		astC_isOkWorldwidCredentials	, 
		astC_isOkCountryPage	, 
		astC_isOkChannel	 ,
		astC_isOkTypeLandingPage	 ,
/*
		astC_LargeCountries , 
		astC_Dgdi , 
		astC_Gbu , 
		astC_Bl , 
		astC_MarketSegment , 
		astC_MarketSubSegment , 
		astC_ProductLine , 
		astC_ProductName , 
		astC_TypeContent , 
		astC_Sensitivity , 
		astC_Country , 
		astC_Region , 
		astC_WorldCredentials , 
		astC_CountryPage , 
		astC_Channel , 
		astC_TypeLandingPage , 
*/
		astC_mandaTags_isOkAsset , 
		astC_mandaTags_isOkLandingPage , 
		astC_mandaTags_isOkCountryFactsheet , 
		astC_mandaTags_isOkCountryPageLargeCountries , 
		astC_mandatoryTags_isOkCountryPageDgdi , 
----		*/

		astC_isOkMandatoryTags , 

--/*
		dupContent , 
		lt_list_tag , 




					CASE WHEN astC_isContentCount = 1 AND lt_list_tag IS NOT NULL
					THEN
					COUNT(*) OVER( PARTITION BY lt_list_tag , 0 ) /* Display + mandatory tags (if filled in) */
					END
												AS [cAnoDup_nBDblnNameMandaTags] 
		,
					CASE WHEN astC_isContentCount = 1 AND lt_list_tag IS NOT NULL
					THEN
					COUNT(*) OVER( PARTITION BY dupContent , 0 ) /* Display + mandatory tags (if filled in) */
					END
												AS [cAnoDup_nBDblnNameAuthors] ,
--*/
					CASE WHEN astC_isContentCount = 1 AND lt_list_tag IS NOT NULL
					THEN CASE WHEN COUNT(*) OVER( PARTITION BY lt_list_tag , 0 ) > 1
							THEN 1
								 WHEN COUNT(*) OVER( PARTITION BY dupContent , 0 ) > 1
									THEN 1
									ELSE 0
							END
							ELSE 0
					END							AS [astC_AnoDup_isDbln] 

	FROM cAssetsFinal


