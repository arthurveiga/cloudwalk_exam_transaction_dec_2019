DROP TABLE IF EXISTS #TEMP1
DROP TABLE IF EXISTS #TEMP2
DROP TABLE IF EXISTS #TEMP3
DROP TABLE IF EXISTS #TEMP4
DROP TABLE IF EXISTS #TEMP5
DROP TABLE IF EXISTS [cloudwalk_transact_sample].[dbo].[all_transactions_with_elapsed_time]
DROP TABLE IF EXISTS [cloudwalk_transact_sample].[dbo].all_multiple_transactions_with_elapsed_time
DROP TABLE IF EXISTS [cloudwalk_transact_sample].[dbo].all_single_transactions_with_elapsed_time


SELECT [transaction_id]
	,[merchant_id]
	,[user_id]
	,[card_number]
	,[transaction_date]
	,[transaction_time]
	,CAST([transaction_date] AS DATETIME) + CAST([transaction_time] AS DATETIME) AS [transaction_datetime]
	,[transaction_amount]
	,[device_id]
	,CASE WHEN [device_id] = -1 THEN 0 ELSE 1 END AS valid_device
	,[has_cbk]
INTO #TEMP1
FROM [cloudwalk_transact_sample].[dbo].[all_transactions]

SELECT *
	,(CASE 
		WHEN (valid_device = 1 AND has_cbk = 0) THEN 2
		WHEN (valid_device = 1 AND has_cbk = 1) THEN 3
		WHEN (valid_device = 0 AND has_cbk = 0) THEN 0
		WHEN (valid_device = 0 AND has_cbk = 1) THEN 1
	  END) AS [valid_device_and_has_cbk_id]
	,(CASE 
		WHEN (valid_device = 1 AND has_cbk = 0) THEN 'VALID DEVICE, NO CBK'
		WHEN (valid_device = 1 AND has_cbk = 1) THEN 'VALID DEVICE, CBK'
		WHEN (valid_device = 0 AND has_cbk = 0) THEN 'INVALID DEVICE, NO CBK'
		WHEN (valid_device = 0 AND has_cbk = 1) THEN 'INVALID DEVICE, CBK'
	  END) AS [valid_device_and_has_cbk]
into #TEMP2
FROM #TEMP1
ORDER BY transaction_datetime

SELECT 
	A.user_id,
	MIN(A.transaction_datetime) as first_user_transaction
INTO #TEMP3
FROM #TEMP2 AS A
GROUP BY user_id
ORDER BY user_id ASC


SELECT
	A.[transaction_id],
	A.[merchant_id],
	A.[user_id],
	CAST(B.first_user_transaction AS DATE) AS first_transaction_date,
	CAST(B.first_user_transaction AS TIME) AS first_transaction_time,
	B.first_user_transaction AS first_transaction_datetime,
	A.[transaction_date],
	A.[transaction_time],
	A.[transaction_datetime] AS this_transaction_datetime,
	A.[transaction_amount],
	CAST(A.valid_device AS BIT) as valid_device,
	CAST(A.[has_cbk] AS BIT) as has_cbk,
	A.valid_device_and_has_cbk_id,
	A.valid_device_and_has_cbk,
	DATEDIFF(second, B.first_user_transaction, A.transaction_datetime) as seconds_elapsed_since_first_transaction
INTO all_transactions_with_elapsed_time
FROM #TEMP2 AS A
	INNER JOIN #TEMP3 AS B
		ON A.user_id = B.user_id
	ORDER BY A.user_id ASC, A.transaction_datetime ASC

--------------------------------------------------------------
-- ALL MULTIPLE TRANSACTIONS


SELECT
	A.[transaction_id],
	A.[merchant_id],
	A.[user_id],
	CAST(B.first_user_transaction AS DATE) AS first_transaction_date,
	CAST(B.first_user_transaction AS TIME) AS first_transaction_time,
	B.first_user_transaction AS first_transaction_datetime,
	A.[transaction_date],
	A.[transaction_time],
	A.[transaction_datetime] AS this_transaction_datetime,
	A.[transaction_amount],
	CAST(A.valid_device AS BIT) as valid_device,
	CAST(A.[has_cbk] AS BIT) as has_cbk,
	A.valid_device_and_has_cbk_id,
	A.valid_device_and_has_cbk,
	DATEDIFF(second, B.first_user_transaction, A.transaction_datetime) as seconds_elapsed_since_first_transaction
INTO #TEMP4
FROM #TEMP2 AS A
	INNER JOIN #TEMP3 AS B
		ON A.user_id = B.user_id
	INNER JOIN cloudwalk_users_overview AS C
		ON A.user_id = C.user_id AND C.total_transactions > 1
	ORDER BY A.user_id ASC, A.transaction_datetime ASC

SELECT
	A.transaction_id,
	A.seconds_elapsed_since_first_transaction as current_transaction,
	ISNULL(LAG(A.transaction_id, 1) OVER(ORDER BY A.user_id ASC, A.this_transaction_datetime ASC),0) as last_transaction,
	ISNULL(LAG(A.seconds_elapsed_since_first_transaction, 1) OVER (ORDER BY A.user_id ASC, A.this_transaction_datetime ASC),0) AS previous_transaction
INTO #TEMP5
FROM #TEMP4 AS A
ORDER BY A.user_id ASC, A.this_transaction_datetime ASC


SELECT
	A.*,
	CASE
		WHEN B.current_transaction - B.previous_transaction < 0
		THEN 0
		ELSE B.last_transaction
	END AS last_transaction,
	CASE
		WHEN B.current_transaction - B.previous_transaction < 0
		THEN 0
		ELSE B.current_transaction - B.previous_transaction
	END AS seconds_elapsed_since_last_transaction
INTO all_multiple_transactions_with_elapsed_time
FROM #TEMP4 AS A
	INNER JOIN #TEMP5 AS B
		ON A.transaction_id = B.transaction_id
ORDER BY A.user_id ASC, A.this_transaction_datetime ASC

--------------------------------------------------------------
-- ALL SINGLE TRANSACTIONS
SELECT
	A.[transaction_id],
	A.[merchant_id],
	A.[user_id],
	CAST(B.first_user_transaction AS DATE) AS first_transaction_date,
	CAST(B.first_user_transaction AS TIME) AS first_transaction_time,
	B.first_user_transaction AS first_transaction_datetime,
	A.[transaction_date],
	A.[transaction_time],
	A.[transaction_datetime] AS this_transaction_datetime,
	A.[transaction_amount],
	CAST(A.valid_device AS BIT) as valid_device,
	CAST(A.[has_cbk] AS BIT) as has_cbk,
	A.valid_device_and_has_cbk_id,
	A.valid_device_and_has_cbk,
	DATEDIFF(second, B.first_user_transaction, A.transaction_datetime) as seconds_elapsed_since_first_transaction
INTO all_single_transactions_with_elapsed_time
FROM #TEMP2 AS A
	INNER JOIN #TEMP3 AS B
		ON A.user_id = B.user_id
	INNER JOIN cloudwalk_users_overview AS C
		ON A.user_id = C.user_id AND C.total_transactions <= 1
	ORDER BY A.user_id ASC, A.transaction_datetime ASC


