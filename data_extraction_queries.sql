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
