

/*
server: ENVIDBSNAPSHOTSSQL.TRAXTECH.COM
database: Multiclient01_Snap_Test
table: rate.GSK_KN_AIR_OCEAN_MASTER_RATES
*/
--Use Multiclient01_Snap_Test


--[1]

-- TEST
--select * from rate.vw_GSK_KN_SourceRates_Temp_v1


ALTER PROCEDURE rate.usp_GSK_KN_Rates_Create_View_v1
	(
	 @mode nvarchar(50),		-- 'Air', 'Ocean FCL', 'Ocean LCL'
	 @cat nvarchar(50),			-- 'Freight', 'Accessorial'vw_GSK_KN_SourceRates_Temp_v1
	 @accgroup nvarchar(50)		-- 'Origin', 'Destination', 'Others1', 'Others2', 'Freight'	=>	Origin-[PUC, ATV, ATF] | Destination-[DNT, DNF, DNV, DOH, 240] | Others1-[470, 762, CF1] | Others2-[CRS, PKL, SRG] | Freight-[Freight]
	)

AS
BEGIN

set @mode = ltrim(rtrim(@mode))
set @cat = ltrim(rtrim(@cat))
set @accgroup = ltrim(rtrim(@accgroup))

if exists(select [name] from sys.views where object_id = object_id('rate.vw_GSK_KN_SourceRates_Temp_v1'))
	begin drop view rate.vw_GSK_KN_SourceRates_Temp_v1 end

declare @query nvarchar(max)  
set @query = N'CREATE VIEW rate.vw_GSK_KN_SourceRates_Temp_v1
	AS
	SELECT distinct
	trax_filename as [comment], mode,
	[version] = 
			case when [trax_filename] like ''%2017%''
				then replace(substring([trax_filename], charindex(''2017'', [trax_filename], 1), len([trax_filename])-(charindex(''2017'', [trax_filename], 1)-1)), ''.xlsx'', '''')
				 when [trax_filename] not like ''%2017%''
				then concat(''2016'', replace(substring([trax_filename], charindex('' V'', [trax_filename], 1), len([trax_filename])-(charindex(''Elavon'', [trax_filename], 1)-1)), ''.xlsx'', ''''))
			end,
	valid_from,
	valid_to,
	rate_code,
	orig_city,
	orig_country_code,
	dest_city,
	dest_country_code,
	equipment_load_size = 
			case when mode = ''Air'' then ''''
				 else equipment_load_size
				end,
	'
	
declare @freightInsert nvarchar(max) = N'rate = port_to_port_rate,
	[currency1] as [currency],
	rate_base_uom = port_to_port_rate_uom,
	minimum_charge = lhl_min,
	rate_type = port_to_port_rate_uom
	'

declare @accOrigInsert nvarchar(max) = N'[orig_transport_cost] as [PUC],
	[orig_transport_cost_uom] as [PUC_UOM],
	[OTC] as [PUC_MIN],
	[OTC_UOM] as [PUC_MIN_UOM],
	[fixed_orig_acc_charges] as [ATF],
	[fixed_orig_acc_charges_uom] as [ATF_UOM],
	[var_orig_acc_charges] as [ATV],
	[var_orig_acc_charges_UOM] as [ATV_UOM],
	[currency1] as [currency]
	'

declare @accDestInsert nvarchar(max) = N'[DNT_MIN] as [DNT],
	[DNT_MIN_UOM] as [DNT_UOM],
	[DNT] as [DNT_MIN],
	[DNT_UOM] as [DNT_MIN_UOM],
	[DNF],
	[DNF_UOM],
	[DNV],
	[DNV_UOM],
	[DNS],
	[DNS_UOM],
	[DOH],
	[DOH_UOM],
	[240],
	[240_UOM],
	[currency1] as [currency]
	'

declare @accOthers1Insert nvarchar(max) = N'[470] = try_cast([470] as varchar(200)),
	[470_UOM],
	[762] = try_cast([762] as varchar(200)),
	[762_UOM],
	[CF1],
	[CF1_UOM],
	[currency1] as [currency]
	'

declare @accOthers2Insert nvarchar(max) = N'[CRS],
	[CRS_UOM],
	[PKL],
	[PKL_UOM],
	[SRG],
	[SRG_UOM],
	[currency1] as [currency]
	'
	

if(@cat = 'Freight')
	begin set @query = @query + @freightInsert end
if(@cat = 'Accessorial' and @accgroup = 'Origin')
	begin set @query = @query + @accOrigInsert end
if(@cat = 'Accessorial' and @accgroup = 'Destination')
	begin set @query = @query + @accDestInsert end
if(@cat = 'Accessorial' and @accgroup = 'Others1')
	begin set @query = @query + @accOthers1Insert end
if(@cat = 'Accessorial' and @accgroup = 'Others2')
	begin set @query = @query + @accOthers2Insert end


set @query = @query + N'from rate.GSK_KN_AIR_OCEAN_MASTER_RATES with (nolock)
	where
		mode = '''+@mode+'''
		--and rate_code in (''K25279'',''K25283'',''K50066'',''K50184'',''K50401'',''K50419'')
		--and rate_code in (''K54486'',''K55524'',''K55525'',''K55526'',''K55527'',''K54324'')
		--and rate_code = ''K56537''
	'
--print @query

exec sp_executesql @query


END
GO 


