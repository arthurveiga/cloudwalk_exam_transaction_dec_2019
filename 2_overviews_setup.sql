
SELECT DISTINCT 
	[merchant_id],
	COUNT([transaction_id]) as [total_transactions],
	COUNT(CASE WHEN [has_cbk] = 1 THEN 1 END) as [quantity_chargebacks]
INTO [cloudwalk_merchants_overview]
FROM [cloudwalk_transact_sample].[dbo].[all_transactions]
GROUP BY [merchant_id]
  
SELECT DISTINCT 
	[user_id],
	COUNT([transaction_id]) as [total_transactions],
	COUNT(CASE WHEN [device_id] != -1 THEN 0 END) as [num_valid_devices],
	COUNT(CASE WHEN [device_id] = -1 THEN 1 END) as [num_invalid_devices],
	COUNT(DISTINCT [card_number]) as [quantity_card_numbers]
INTO [cloudwalk_users_overview]
FROM [cloudwalk_transact_sample].[dbo].[all_transactions]
GROUP BY [user_id]
  
SELECT 
	[card_number],
	COUNT(DISTINCT [user_id]) as num_users_with_same_card,
	COUNT(DISTINCT [device_id]) as num_devices_with_same_card
INTO [card_number_overview]
FROM [cloudwalk_transact_sample].[dbo].[all_transactions]
GROUP BY [card_number]

SELECT 
	COUNT(transaction_id) AS all_time_transactions,
	COUNT(CASE WHEN has_cbk = 0 THEN 1 END) AS no_cbk_transactions,
	COUNT(CASE WHEN has_cbk = 1 THEN 1 END) AS has_cbk_transactions,
	COUNT(CASE WHEN device_id != -1 THEN 1 END) AS valid_device_transactions,
	COUNT(CASE WHEN device_id = -1 THEN 1 END) AS invalid_device_transactions

FROM [cloudwalk_transact_sample].[dbo].[all_transactions]