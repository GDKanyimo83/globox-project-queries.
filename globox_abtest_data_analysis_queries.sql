-- * Data Extraction and Analysis:

-- Q: What are the start and end dates of the experiment?
-- A: 2023-01-25 to 2023-02-06
SELECT MIN(join_dt), MAX(join_dt)
FROM groups;

-- Q: How many total users were in the experiment?
-- A: 48,943
SELECT COUNT(uid)
FROM groups;

-- Q: How many users were in the control and treatment groups?
-- A: Control (A): 24,343, Treatment (B): 24,600
SELECT "group",
        COUNT(uid)
FROM groups
GROUP BY "group";

-- Q: What was the conversion rate of all users?
-- A: 4.28%
SELECT
      ROUND(CAST(COUNT(DISTINCT a.uid) AS DECIMAL(10,2))/CAST(COUNT(DISTINCT u.id) AS DECIMAL(10,2)) * 100, 2) AS conversion_rate
FROM users AS u
LEFT JOIN activity AS a ON u.id = a.uid;

-- Q: What is the user conversion rate for the control and treatment groups?
-- A: Control: 3.92%, Treatment: 4.63%
SELECT
   g.group, ROUND(CAST(COUNT(DISTINCT a.uid) AS DECIMAL(10,2))/CAST(COUNT(DISTINCT u.id) AS DECIMAL(10,2)) * 100, 2) AS conversion_rate
FROM users AS u
LEFT JOIN groups AS g ON u.id = g.uid
LEFT JOIN activity AS a ON u.id = a.uid
GROUP BY g.group;

-- Q: What is the average amount spent per user for the control and treatment groups, including users who did not convert?
-- A: Control: $3.375, Treatment: $3.391
SELECT n.group,
       CAST(SUM(n.spent_usd)/COUNT(DISTINCT n.user_id) AS DECIMAL(100,3))
FROM (
      SELECT
           u.id AS user_id, u.country, u.gender, g.device, g.group, 
           g.join_dt AS join_date, a.dt AS purchase_date, COALESCE(a.spent, 0) AS spent_usd
      FROM users AS u
      LEFT JOIN groups AS g ON u.id = g.uid
      LEFT JOIN activity AS a ON u.id = a.uid
      ) AS n
GROUP BY n.group;

-- *The following query has been used for the test statistics
SELECT
      u.id AS user_id, u.country, u.gender, g.device,g.group,
      SUM(COALESCE(a.spent, 0)) AS total_spent_usd
FROM
    users AS u
LEFT JOIN groups AS g ON u.id = g.uid
LEFT JOIN activity AS a ON u.id = a.uid
GROUP BY
        u.id, u.country, u.gender, g.device, g.group;
        
        

-- * Novelty Effect Analysis:

-- Converted Users Average Amount Spent Over Join Date:
SELECT 
      g.join_dt AS join_date, 
      g.group,
      COUNT(DISTINCT g.uid) AS total_users,
      COUNT(DISTINCT a.uid) AS paid_users,
      SUM(a.spent) AS total_spent
FROM 
    groups AS g
LEFT JOIN activity AS a ON g.uid = a.uid
GROUP BY 
        g.group,
        g.join_dt
ORDER BY 1;

-- All Users’ Metrics Over Join Date:
SELECT 
      n.join_date,
      n.group,
      ROUND(CAST(SUM(n.paid_users) / MAX(n.total_users) * 100 AS
      DECIMAL(10,2)), 2) AS conversion_rate,
      ROUND(CAST(SUM(n.total_spent)/MAX(n.total_users) AS DECIMAL(10,2)),2) AS 
      average_spent
FROM(SELECT 
           g.join_dt AS join_date, 
           g.group,
           COUNT(DISTINCT g.uid) AS total_users,
           COUNT(DISTINCT a.uid) AS paid_users,
           SUM(a.spent) AS total_spent
      FROM 
           groups AS g
      LEFT JOIN activity AS a ON g.uid = a.uid
      GROUP BY 
              g.group,
              g.join_dt
      ORDER BY 1) AS n
GROUP BY 1, 2;

-- Date Difference and Converted Users:
SELECT n.group, COUNT(n.user_id), n.date_difference
FROM(SELECT 
           a.uid AS user_id, 
     g.group,
     g.join_dt AS date_registered,
     a.dt AS date_converted,
     SUM(COALESCE(a.spent, 0)) AS total_spent_usd,
     a.dt - g.join_dt AS date_difference
      FROM groups AS g
JOIN activity AS a
ON g.uid = a.uid
GROUP BY 1,2,3,4) AS n
GROUP BY 1,3
ORDER BY 3;
