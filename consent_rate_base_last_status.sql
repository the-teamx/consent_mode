# global_variables contains global variable for the query (date, event_name)
# this query count all the possible values of consent given and calcul a consent rate base on last users's status
WITH
  global_variables AS (
  SELECT
    '20230116' AS start_date,
    '20230131' AS end_date,
    'consent-mode-vsuk-chuk.analytics_304833567.events_*' AS table_A
    ),

specific_for_query as(
SELECT 
 user_pseudo_id,      
       privacy_info.ads_storage as ads_storage,
        privacy_info.analytics_storage as analytics_storage,
        CASE WHEN user_pseudo_id IS NULL THEN GENERATE_UUID() ELSE user_pseudo_id END AS user_pseudo_id_reformed,
        event_timestamp
FROM `consent-mode-vsuk-chuk.analytics_304833567.events_*` , global_variables
where _table_suffix between global_variables.start_date and global_variables.end_date
),
calcul as(
SELECT
  *,
  ROW_NUMBER() OVER(PARTITION BY user_pseudo_id_reformed ORDER BY event_timestamp DESC) AS row_num,
  FROM specific_for_query
  
),
groupement as(
SELECT
analytics_storage,
ads_storage,
#user_pseudo_id_reformed
  count(user_pseudo_id_reformed) user_by_consent_type
  FROM
  calcul
  where row_num=1
  group by 1,2
)

SELECT
  *,
  SAFE_DIVIDE(user_by_consent_type,SUM(user_by_consent_type) OVER()) AS percent_of_total
FROM
  groupement
order by user_by_consent_type DESC
