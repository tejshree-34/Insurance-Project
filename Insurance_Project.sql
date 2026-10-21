USE insurance;

#Retrieve customer information

SELECT * FROM customers;

#Analyze policy performance

SELECT 
    Policy_Type,
    COUNT(Policy_ID) AS Total_Policies,
    SUM(CASE WHEN Policy_Status = 'Active' THEN 1 ELSE 0 END) AS Active_Policies,
    SUM(CASE WHEN Policy_Status = 'Expired' THEN 1 ELSE 0 END) AS Expired_Policies,
    SUM(CASE WHEN Policy_Status = 'Cancelled' THEN 1 ELSE 0 END) AS Cancelled_Policies,
    SUM(Premium_Amount) AS Total_Premium_Revenue,
    ROUND(AVG(Premium_Amount), 2) AS Avg_Premium,
    ROUND(AVG(Coverage_Amount), 2) AS Avg_Coverage
FROM Policies
GROUP BY Policy_Type
ORDER BY Total_Premium_Revenue DESC;

# From this we will be getting total number of policies based on there types(Health,Life,Motar,Travel & Life) also we can see the number of active expired and cancelled policies 
# total premium revenue based on the policy type , mostly we got more premium from Health type policies, Avg Premium, Avg Coverage
# of the polices by using AVG function. Most highest coverage is of Health type policies.

SELECT 
    Payment_Frequency,
    COUNT(Policy_ID) AS Policy_Count,
    SUM(Premium_Amount) AS Total_Revenue,
    ROUND(AVG(Premium_Amount), 2) AS Avg_Premium,
    ROUND((SUM(CASE WHEN Policy_Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(Policy_ID)), 2) AS Cancellation_Rate_Pct
FROM Policies
GROUP BY Payment_Frequency
ORDER BY Total_Revenue DESC;

# This query will tell us that which premium mode customer is cancelling the policies and which premium mode customer choice mostly.
-- ROUND((SUM(CASE WHEN Policy_Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(Policy_ID)), 2) AS Cancellation_Rate_Pct 
-- It will check all the records of the polices and write 1 if the policies is 'Cancelled' otherwise for active and expired it will write 0.
-- Then it will add all the 0 and 1 and give the cancellation rate pct
-- Total Cancelled policies / Total Policies * 100 = Cancllation rate pct


#Identify profitable and loss-making policy types
WITH Policy_Financials AS (
    SELECT 
        p.Policy_Type,
        COUNT(DISTINCT p.Policy_ID) AS Total_Policies_Issued,
        SUM(p.Premium_Amount) AS Total_Premium_Revenue,
        COALESCE(SUM(CASE WHEN cl.Claim_Status = 'Approved' THEN cl.Claim_Amount ELSE 0 END), 0) AS Total_Claims_Paid
    FROM Policies p
    LEFT JOIN Claims cl ON p.Policy_ID = cl.Policy_ID
    GROUP BY p.Policy_Type
)
SELECT 
    Policy_Type,
    Total_Policies_Issued,
    Total_Premium_Revenue,
    Total_Claims_Paid,
    (Total_Premium_Revenue - Total_Claims_Paid) AS Net_Profit,
    ROUND((Total_Claims_Paid / NULLIF(Total_Premium_Revenue, 0)) * 100, 2) AS Loss_Ratio_Percentage,
    CASE 
        WHEN (Total_Premium_Revenue - Total_Claims_Paid) > 0 THEN 'Profitable'
        ELSE 'Loss-Making'
    END AS Profitability_Status
FROM Policy_Financials
ORDER BY Net_Profit DESC;

-- This query will show the analysis of policy type which is profitable and loss making percentage.
-- First it will create a temporary table in which Total_Premium_Revenue and Total_Claims_Paid will get calculated then 
-- Net profit will get calculated as (Total_Premium_Revenue - Total_Claims_Paid) 
-- Loss Ratio Percentage = Total Claims Paid / Total Premium Revenue * 100 
-- If Net Profit is greater than 0 then it will tag as Profitable or else it will tag as Loss-Making
-- NULLIF(Total_Premium_Revenue, 0) = > If we divide any number by 0 in sql then 
-- we face Division by zero error and query will get crash so if Total premium Revenue is 0 then Nullif will write the record as 0.
-- ROUND(..., 2) ==> Round 2 will give the perfect 2 digit after the point. 
-- This company is in the loss making because Total premium paid by the customer is less than the Claims they got from the company

WITH Policy_Totals AS (
    SELECT 
        Policy_Type,
        COUNT(Policy_ID) AS Total_Policies,
        SUM(Premium_Amount) AS Revenue
    FROM Policies
    GROUP BY Policy_Type
)
SELECT 
    Policy_Type,
    Total_Policies,
    Revenue,
    ROUND((Revenue / SUM(Revenue) OVER()) * 100, 2) AS Revenue_Share_Percentage,
    DENSE_RANK() OVER (ORDER BY Revenue DESC) AS Performance_Rank
FROM Policy_Totals;

-- #This query will show the revenue share as per the market value and rates them
-- Revenue share Percentage = Policy revenue / total revenue * 100 (Upto 2 decimals )
-- Dense rank will assign the rank based on the revenue share percentage. Higher revenue will be assigned as '1' rank

# Analyze claim performance
-- Claim Approval Rate & Rejection Analysis
-- Write a query to calculate the Total Claims, Approved Claims Count, Rejected Claims Count, Pending Claims Count, 
-- and the Approval Rate Percentage for each Claim_Type. Sort the output by the highest total claims.

SELECT Claim_Type,
count(Claim_ID) as Total_Claims,
SUM(CASE WHEN Claim_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved_Claims_Count,
SUM(CASE WHEN Claim_Status = 'Pending' THEN 1 ELSE 0 END) AS PENDING_CLAIMS_COUNT,
SUM(CASE WHEN Claim_Status = 'Rejected' THEN 1 ELSE 0 END) AS REJECTED_CLAIMS_COUNT,
ROUND((SUM(CASE WHEN Claim_Status = 'Approved' THEN 1 ELSE 0 END) * 100.0 / COUNT(Claim_Type)), 2) AS Approval_Rate_Percentage
From claims group by Claim_Type
ORDER BY Total_Claims DESC;

-- Question 2: Claim Settlement Efficiency
-- Write a query to calculate the Average Claim Processing Days and 
-- Total Claim Amount for each Claim_Status (Approved, Rejected, Pending).

SELECT 
    Claim_Status,
    COUNT(Claim_ID) AS Total_Claims_Count,
    ROUND(AVG(Claim_Processing_Days), 2) AS Avg_Processing_Days,
    SUM(Claim_Amount) AS Total_Claim_Amount
FROM Claims
GROUP BY Claim_Status
ORDER BY Total_Claim_Amount DESC;

-- Question 3: High-Claim Customers (Top Claimants)
-- Write a query using a JOIN to find the Top 5 customers who have received the highest Total Approved Claim Amount. 
-- Display their Customer_Name, City, Risk_Level, and their total approved amount.
SELECT 
    c.Customer_Name,
    c.City,
    r.Risk_Level,
    SUM(cl.Claim_Amount) AS Total_Approved_Amount
FROM Customers c
JOIN Policies p ON c.Customer_ID = p.Customer_ID
JOIN Claims cl ON p.Policy_ID = cl.Policy_ID
JOIN risk_info r ON c.Customer_ID = r.Customer_ID
WHERE cl.Claim_Status = 'Approved'
GROUP BY c.Customer_ID, c.Customer_Name, c.City, r.Risk_Level
ORDER BY Total_Approved_Amount DESC
LIMIT 5;


-- Question 4: Monthly Claim Trends
-- Write a query to aggregate claim activity by month. Extract the Year and Month from Claim_Date to 
-- calculate the Total Claims Filed and Total Claim Amount Requested for each month, ordered chronologically.

SELECT 
DATE_FORMAT(Claim_Date, '%Y') as Claim_Year,
DATE_FORMAT(Claim_Date, '%m') as Claim_Month,
Count(Claim_ID) as Total_Claims_filed,
SUM(Claim_Amount) as Total_Claim_Amount_Reqested
From Claims
group by Claim_Year,claim_month
order by Claim_Year,Claim_month asc;

-- Question 5: High-Risk vs Low-Risk Claim Behavior
-- Write a query joining Claims, Policies, and Risk_Info to compare High Risk, Medium Risk, and Low Risk customers on:
-- Total Approved Claims Count
-- Total Claim Amount Paid (Approved claims only)
-- Average Claim Amount per Approved Claim

SELECT 
    r.Risk_Level,
    COUNT(cl.Claim_ID) AS Total_Approved_Claims_Count,
    SUM(cl.Claim_Amount) AS Total_Claim_Amount_Paid,
    ROUND(AVG(cl.Claim_Amount), 2) AS Avg_Claim_Amount_Per_Approved_Claim
FROM Claims cl
JOIN Policies p ON cl.Policy_ID = p.Policy_ID
JOIN risk_info r ON p.Customer_ID = r.Customer_ID
WHERE cl.Claim_Status = 'Approved'
GROUP BY r.Risk_Level
ORDER BY Total_Claim_Amount_Paid DESC;

-- # Calculate premium and claim metrics
-- Question 1: Premium vs. Claim Metrics by Risk Category
-- Write a query using JOINs across Policies, Claims, and risk_info 
-- (or Insurance_Transactions) to compare risk tiers (High, Medium, Low). Display:Risk_LevelAverage Premium Amount paid per 
-- policy Average Claim Amount requested per claim Claim Severity Ratio ({Average Claim Amount}\{Average Premium Amount}) rounded to 
-- 2 decimal places

Select r.risk_level,
ROUND(AVG(p.Premium_Amount),2) as Average_Premium_Amount,
ROUND(AVG(cl.Claim_Amount),2) as Average_Claim_Amount,
ROUND(AVG(cl.Claim_Amount) / NULLIF(AVG(p.Premium_Amount), 0), 2) AS Claim_Severity_Ratio
from Claims cl JOIN  Policies p on cl.Policy_ID = p.Policy_ID
JOIN risk_info r on p.Customer_ID = r.Customer_ID
GROUP BY r.Risk_Level
ORDER BY Claim_Severity_Ratio DESC;

-- Write a query using a LEFT JOIN between Policies and Claims (or using CTEs) to aggregate monthly totals based on dates. Display:
-- Year and Month (YYYY-MM format)
-- Total Premium Collected in that month (based on policy date / Start_Date)
-- Total Claims Paid in that month (based on Claim_Date for approved claims)
-- Monthly Net Profit (Premium Collected minus Claims Paid)
-- Ordered chronologically.

WITH Monthly_Premiums AS (
    SELECT 
        DATE_FORMAT(Policy_Start_Date, '%Y-%m') AS YearMonth, 
        SUM(Premium_Amount) AS Total_Premium_Collected
    FROM Policies
    GROUP BY DATE_FORMAT(Policy_Start_Date, '%Y-%m')
),
Monthly_Claims AS (
    SELECT 
        DATE_FORMAT(Claim_Date, '%Y-%m') AS YearMonth,
        SUM(Claim_Amount) AS Total_Claims_Paid
    FROM Claims
    WHERE Claim_Status = 'Approved'
    GROUP BY DATE_FORMAT(Claim_Date, '%Y-%m')
)
SELECT 
    p.YearMonth,
    COALESCE(p.Total_Premium_Collected, 0) AS Total_Premium_Collected,
    COALESCE(c.Total_Claims_Paid, 0) AS Total_Claims_Paid,
    ROUND(COALESCE(p.Total_Premium_Collected, 0) - COALESCE(c.Total_Claims_Paid, 0), 2) AS Monthly_Net_Profit
FROM Monthly_Premiums p
LEFT JOIN Monthly_Claims c ON p.YearMonth = c.YearMonth
ORDER BY p.YearMonth ASC;


