-- =====================================================================
-- Delivery Health Analysis (SQLite)
-- Author: Wilson Joel
-- Data: fictional sample data, 4 FinTech teams, 12 two-week sprints (2025)
-- Tables: sprints (48 rows), work_items (444 rows), defects (227 rows)
-- Companion to the Delivery Health Power BI dashboard
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Overall predictability
-- Question: Do teams deliver what they commit to?
-- Result: 1,688 points committed, 1,463 completed, Say/Do = 86.7%
-- ---------------------------------------------------------------------
SELECT
  SUM(CommittedPoints) AS committed,
  SUM(CompletedPoints) AS completed,
  ROUND(SUM(CompletedPoints) * 100.0 / SUM(CommittedPoints), 1) AS say_do_pct
FROM sprints;


-- ---------------------------------------------------------------------
-- 2. Predictability by team
-- Question: Which teams are most and least predictable?
-- Result: Lending 90.2%, Payments 87.2%, Digital Banking 86.1%, Fraud 82.0%
-- ---------------------------------------------------------------------
SELECT
  Team,
  SUM(CommittedPoints) AS committed,
  SUM(CompletedPoints) AS completed,
  ROUND(SUM(CompletedPoints) * 100.0 / SUM(CommittedPoints), 1) AS say_do_pct
FROM sprints
GROUP BY Team
ORDER BY say_do_pct DESC;


-- ---------------------------------------------------------------------
-- 3. Open defects, oldest first
-- Question: Which open defects need attention now?
-- Result: 20 open; the two oldest are 37 days, including a Sev 2 (DEF-695)
-- ---------------------------------------------------------------------
SELECT
  DefectID,
  Team,
  SeverityLabel,
  FoundIn,
  AgeDays
FROM defects
WHERE Status = 'Open'
ORDER BY AgeDays DESC;


-- ---------------------------------------------------------------------
-- 4. Production escape rate by sprint
-- Question: Are fewer defects reaching production over time?
-- Result: No. Escape rate rose from about 4-5% (S01-S03) to 15.8% (S08)
--         and 18.8% (S11). CASE keeps sprints with zero escapes (S09, S12).
-- ---------------------------------------------------------------------
SELECT
  SprintFound,
  COUNT(*) AS total_defects,
  SUM(CASE WHEN FoundIn = 'Production' THEN 1 ELSE 0 END) AS production_escapes,
  ROUND(SUM(CASE WHEN FoundIn = 'Production' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS escape_rate_pct
FROM defects
GROUP BY SprintFound
ORDER BY SprintFound;


-- ---------------------------------------------------------------------
-- 5. Open defects with sprint details (JOIN)
-- Question: When were the open defects found?
-- Result: the oldest open defects were all found in S10 (started 2025-05-12)
-- ---------------------------------------------------------------------
SELECT
  d.DefectID,
  d.Team,
  d.SeverityLabel,
  d.AgeDays,
  s.Sprint,
  s.StartDate
FROM defects d
JOIN sprints s ON d.SprintKey = s.SprintKey
WHERE d.Status = 'Open'
ORDER BY d.AgeDays DESC;


-- ---------------------------------------------------------------------
-- 6. Team scorecard: delivery and quality side by side (CTEs + JOIN)
-- Question: How does each team do on predictability AND quality?
-- Result: Lending leads on both (90.2%, 3 escapes);
--         Digital Banking has the most open defects (7) and escapes (6)
-- ---------------------------------------------------------------------
WITH delivery AS (
  SELECT
    Team,
    ROUND(SUM(CompletedPoints) * 100.0 / SUM(CommittedPoints), 1) AS say_do_pct
  FROM sprints
  GROUP BY Team
),
quality AS (
  SELECT
    Team,
    SUM(CASE WHEN Status = 'Open' THEN 1 ELSE 0 END) AS open_defects,
    SUM(CASE WHEN FoundIn = 'Production' THEN 1 ELSE 0 END) AS production_escapes
  FROM defects
  GROUP BY Team
)
SELECT
  d.Team,
  d.say_do_pct,
  q.open_defects,
  q.production_escapes
FROM delivery d
JOIN quality q ON d.Team = q.Team
ORDER BY d.say_do_pct DESC;
