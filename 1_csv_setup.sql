drop table if exists #tempdate
drop table if exists #tempdateseparated

select
	[transaction_id],
	[transaction_date] as [transaction_datetime]	
	into #tempdate
from [cloudwalk_transact_sample].[dbo].[all_transactions_csv]

select
	[transaction_id],
	REPLACE(REPLACE(SUBSTRING([transaction_datetime], 1, 10), '-', '/'),'/11/','/12/') as [transaction_date], -- não existe 31/11/2019. Por isso mudei pra dezembro
	SUBSTRING([transaction_datetime], 12, 16) as [transaction_time]
	into #tempdateseparated
from #tempdate

select 
	b.[transaction_id] as [transaction_id],
	b.[merchant_id],
    b.[user_id],
    b.[card_number],
	CAST(CONVERT(varchar(11), a.[transaction_date]) as date) as [transaction_date],
	CAST(CONVERT(varchar(16), a.[transaction_time]) as time) as [transaction_time],
	b.[transaction_amount],
	ISNULL(b.[device_id], -1) as [device_id],
	b.[has_cbk]
	into [cloudwalk_transact_sample].[dbo].[all_transactions]
from #tempdateseparated as a
	inner join [cloudwalk_transact_sample].[dbo].[all_transactions_csv] as b 
		on a.[transaction_id] = b.[transaction_id]