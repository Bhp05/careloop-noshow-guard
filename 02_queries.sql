CREATE DATABASE noshowguard;
USE noshowguard;

CREATE TABLE clinics (
  clinic_id VARCHAR(5) PRIMARY KEY, 
  clinic_name VARCHAR(40) NOT NULL, 
  city VARCHAR(20) NOT NULL,
  tier VARCHAR(10), 
  latitude DECIMAL(8,4), 
  longitude DECIMAL(8,4), 
  temp_c DECIMAL(5,1)
);

CREATE TABLE appointments (
  appointment_id VARCHAR(8) PRIMARY KEY, 
  patient_id VARCHAR(8) NOT NULL, 
  clinic_id VARCHAR(5) NOT NULL,
  booked_on DATE, 
  appt_date DATE, 
  age INT, 
  gender VARCHAR(1), 
  distance_km DECIMAL(5,1), 
  fee_inr INT,
  booking_channel VARCHAR(10), 
  visit_type VARCHAR(12), 
  reminder_sent VARCHAR(3), 
  prior_no_shows INT,
  status VARCHAR(10), 
  lead_days INT, 
  no_show INT,
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
);



-- Total appointments 
SELECT COUNT(*) AS total_appointments FROM appointments;

-- Total no-shows 
SELECT SUM(no_show) AS total_noshows FROM appointments;

INSERT INTO appointments VALUES ('A0001', 'P999', 'C01', '2025-01-01', '2025-01-02', 30, 'M', 5.0, 500, 'App', 'Consultation', 'Yes', 0, 'Attended', 1, 0);

-- Task 2.2 — No-Show Rate by Clinic

SELECT c.clinic_name, c.city, 
       COUNT(a.appointment_id) AS appointments, 
       SUM(a.no_show) AS no_shows, 
       ROUND(SUM(a.no_show) * 100.0 / COUNT(a.appointment_id), 1) AS no_show_pct
FROM clinics c
JOIN appointments a ON c.clinic_id = a.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
HAVING appointments >= 95
ORDER BY no_show_pct DESC;


-- Task 2.3 — Does Booking Far Ahead Matter? (Lead Time Bands)
SELECT 
    CASE 
        WHEN lead_days BETWEEN 1 AND 7 THEN '1-7'
        WHEN lead_days BETWEEN 8 AND 14 THEN '8-14'
        WHEN lead_days BETWEEN 15 AND 30 THEN '15-30'
        ELSE '31+'
    END AS lead_band,
    COUNT(*) AS appointments,
    SUM(no_show) AS no_shows,
    ROUND(SUM(no_show) * 100.0 / COUNT(*), 1) AS no_show_pct
FROM appointments
GROUP BY lead_band
ORDER BY MIN(lead_days);

-- Task 2.4 — Month-by-Month Trend

WITH monthly AS (
    SELECT SUBSTR(appt_date, 1, 7) AS month,
           COUNT(*) AS appointments,
           ROUND(SUM(no_show) * 100.0 / COUNT(*), 1) AS no_show_pct
    FROM appointments
    GROUP BY month
)
SELECT month, appointments, no_show_pct,
       ROUND(no_show_pct - LAG(no_show_pct, 1) OVER (ORDER BY month), 1) AS change_pts
FROM monthly;

-- Task 2.5 — Rank Clinics Inside Each City
WITH overall AS (
    SELECT ROUND(SUM(no_show) * 100.0 / COUNT(*), 2) AS overall_rate FROM appointments
),
clinic_rates AS (
    SELECT c.clinic_name AS clinic, c.city,
           ROUND(SUM(a.no_show) * 100.0 / COUNT(a.appointment_id), 1) AS no_show_pct
    FROM clinics c
    JOIN appointments a ON c.clinic_id = a.clinic_id
    GROUP BY c.clinic_id, c.clinic_name, c.city
)
SELECT cr.city, cr.clinic, cr.no_show_pct,
       RANK() OVER (PARTITION BY cr.city ORDER BY cr.no_show_pct DESC) AS rank_in_city,
       CASE 
           WHEN cr.no_show_pct > (SELECT overall_rate FROM overall) THEN 'above'
           WHEN cr.no_show_pct < (SELECT overall_rate FROM overall) THEN 'below'
           ELSE 'equal'
       END AS vs_overall
FROM clinic_rates cr
ORDER BY cr.city, rank_in_city;





