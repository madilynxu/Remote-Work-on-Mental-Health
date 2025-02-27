
-- How can remote work influence employee's mental health status?
SELECT W.Work_Location, M.Mental_Health_Condition,
COUNT(*) AS Employee_Count,
ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER (PARTITION BY W.Work_Location),2) AS Percentage
FROM WorkEnvironment W
JOIN EmployeeInfo E ON W.Employee_ID = E.Employee_ID
JOIN MentalHealth M ON M.Employee_ID = E.Employee_ID
GROUP BY W.Work_Location, M.Mental_Health_Condition
ORDER BY W.Work_Location, Employee_Count DESC;



-- Does the number of virtual meetings affect work-life balance ratings?
SELECT Number_of_Virtual_Meetings, ROUND(AVG(Work_Life_Balance_Rating),2) AS AvgRating
FROM WorkEnvironment W
JOIN EmployeeInfo E ON W.Employee_ID = E.Employee_ID
JOIN Satis_Prod S ON E.Employee_ID = S.Employee_ID
GROUP BY Number_of_Virtual_Meetings
ORDER BY Number_of_Virtual_Meetings DESC;



-- Which industries provide the most support for remote work? And how does satisfaction with remote work vary across different industries?
SELECT C.Industry, AVG(C.Company_Support_for_Remote_Work) AS SupportForRemote,
ROUND(SUM(IF(S.Satisfaction_with_Remote_Work = 'Satisfied',1,0))*100/COUNT(S.Satisfaction_with_Remote_Work),2) AS SatisfactionLevel
FROM CompanyInfo C 
JOIN EmployeeInfo E ON C.Employee_ID = E.Employee_ID
JOIN Satis_Prod S ON E.Employee_ID = S.Employee_ID
GROUP BY C.Industry
ORDER BY AVG(C.Company_Support_for_Remote_Work) DESC;



-- Do employees with more years of experience have higher satisfaction with remote work?
SELECT E.Years_of_Experience, 
ROUND(SUM(IF(S.Satisfaction_with_Remote_Work = 'Satisfied',1,0))*100/COUNT(S.Satisfaction_with_Remote_Work),2) AS SatisfactionLevel
FROM EmployeeInfo E
JOIN Satis_Prod S ON E.Employee_ID = S.Employee_ID
GROUP BY E.Years_of_Experience
ORDER BY E.Years_of_Experience ASC;

-- Classify employees to get more insights
WITH EmployeeClass AS (
SELECT E.Years_of_Experience, ROUND(SUM(IF(S.Satisfaction_with_Remote_Work = 'Satisfied',1,0))*100/COUNT(S.Satisfaction_with_Remote_Work),2) AS SatisfactionLevel,
CASE
WHEN E.Years_of_Experience <= 5 THEN 'Entry'
WHEN E.Years_of_Experience <= 10 THEN 'Junior'
WHEN E.Years_of_Experience <= 15 THEN 'Senior I'
WHEN E.Years_of_Experience <= 20 THEN 'Senior II'
ELSE 'Expert'
END AS ExpClassification
FROM EmployeeInfo E
JOIN Satis_Prod S ON E.Employee_ID = S.Employee_ID
GROUP BY E.Years_of_Experience
ORDER BY E.Years_of_Experience ASC)
SELECT ExpClassification, ROUND(AVG(SatisfactionLevel),2) AS SatisLevel
FROM EmployeeClass
GROUP BY ExpClassification;



-- Is there a relationship between stress levels, social isolation ratings and satisfaction with remote work?
SELECT M.Stress_Level, AVG(M.Social_Isolation_Rating) AS AvgIsolationRating,
ROUND(SUM(IF(S.Satisfaction_with_Remote_Work = 'Satisfied', 1, 0)) * 100 / COUNT(S.Satisfaction_with_Remote_Work), 2) AS SatisfiedPercent,
ROUND(SUM(IF(S.Satisfaction_with_Remote_Work = 'UnSatisfied', 1, 0)) * 100 / COUNT(S.Satisfaction_with_Remote_Work), 2) AS UnSatisfiedPercent,
ROUND(SUM(IF(S.Satisfaction_with_Remote_Work = 'Neutral', 1, 0)) * 100 / COUNT(S.Satisfaction_with_Remote_Work), 2) AS NeutralPercent
FROM MentalHealth M
JOIN EmployeeInfo E ON E.Employee_ID = M.Employee_ID
JOIN Satis_Prod S ON S.Employee_ID = E.Employee_ID
GROUP BY Stress_Level;



-- Can stress levels and work hours predict changes in productivity?
SELECT DISTINCT S.Productivity_Change, M.Stress_Level, 
ROUND(AVG(W.Hours_Worked_Per_Week) OVER (PARTITION BY S.Productivity_Change ORDER BY M.Stress_Level),2) AS AvgWorkHrs
FROM EmployeeInfo E
JOIN MentalHealth M ON E.Employee_ID = M.Employee_ID
JOIN WorkEnvironment W ON E.Employee_ID = W.Employee_ID
JOIN Satis_Prod S ON E.Employee_ID = S.Employee_ID;



-- How can physical well-being have a impact on the employees' stress level?
SELECT DISTINCT M.Stress_Level, S.Physical_Activity, S.Sleep_Quality, COUNT(*) AS EmployeeCount,
ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER (),2) AS Percentage
FROM MentalHealth M
JOIN (SELECT 
P.Physical_Activity, P.Sleep_Quality, P.Employee_ID
FROM PhysicalWellBeing P
JOIN EmployeeInfo E ON P.Employee_ID = E.Employee_ID
) AS S
ON M.Employee_ID = S.Employee_ID
GROUP BY S.Physical_Activity, S.Sleep_Quality, M.Stress_Level
ORDER BY COUNT(*) DESC;



-- How does the work environment influence work-life balance ratings across different job roles?
WITH DetailedData AS (
SELECT DISTINCT E.Job_Role, W.Work_Location,
FORMAT(AVG(W.Hours_Worked_Per_Week) OVER (PARTITION BY W.Work_Location, E.Job_Role),2) AS AvgWorkHRS,
FORMAT(AVG(W.Number_of_Virtual_Meetings) OVER (PARTITION BY W.Work_Location, E.Job_Role),2) AS AvgMeeting,
FORMAT(AVG(S.Work_Life_Balance_Rating) OVER (PARTITION BY W.Work_Location, E.Job_Role),2) AS WLB_Rating
FROM EmployeeInfo E
JOIN WorkEnvironment W ON E.Employee_ID = W.Employee_ID
JOIN Satis_Prod S ON E.Employee_ID = S.Employee_ID
)
SELECT Job_Role, Work_Location,
ROUND(AVG(AvgWorkHRS),2) AS AvgWorkHRS,
ROUND(AVG(AvgMeeting),2) AS AvgMeeting,
ROUND(AVG(WLB_Rating),2) AS AvgWLB_Rating
FROM DetailedData
GROUP BY ROLLUP(Job_Role, Work_Location)
HAVING Job_Role IS NOT NULL
ORDER BY Job_Role, Work_Location DESC;


