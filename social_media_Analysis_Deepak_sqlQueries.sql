/* =====================================================================
   SOCIAL MEDIA (IG CLONE) — STUDENT ANSWER TEMPLATE
   ===================================================================== */

USE ig_clone;


/* =====================================================================
   OBJECTIVE QUESTIONS
   ===================================================================== */

-- O1.
-- Are there any tables with duplicate or missing null values? If so, how
-- would you handle them?

-- Checking for DUPLICATE values

SELECT username, COUNT(*) AS `count`
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

SELECT image_url, user_id, COUNT(*) AS `count`
FROM photos
GROUP BY image_url, user_id
HAVING COUNT(*) > 1;

SELECT comment_text, user_id, photo_id, COUNT(*) AS `count`
FROM comments
GROUP BY comment_text, user_id, photo_id
HAVING COUNT(*) > 1;

SELECT user_id, photo_id, COUNT(*) AS `count`
FROM likes
GROUP BY user_id, photo_id
HAVING COUNT(*) > 1;

SELECT follower_id, followee_id, COUNT(*) AS `count`
FROM follows
GROUP BY follower_id, followee_id
HAVING COUNT(*) > 1;

-- Checking for Null values

SELECT id, username, created_at
FROM users
WHERE username IS NULL;

SELECT id, image_url, user_id, created_dat
FROM photos
WHERE image_url IS NULL 
OR user_id IS NULL 
OR created_dat IS NULL;

SELECT id, comment_text, photo_id, user_id, created_at
FROM comments
WHERE comment_text IS NULL 
OR user_id IS NULL 
OR photo_id IS NULL OR created_at IS NULL;

SELECT user_id, photo_id, created_at
FROM likes
WHERE user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;

SELECT follower_id, followee_id, created_at
FROM follows
WHERE follower_id IS NULL OR followee_id IS NULL 
OR created_at IS NULL;


-- O2.
-- What is the distribution of user activity levels (e.g., number of posts,
-- likes, comments) across the user base?

 SELECT u.id AS user_id, u.username,
       COUNT(DISTINCT p.id) AS Total_posts,
       COUNT(DISTINCT l.photo_id) AS Total_likes_Given,
       COUNT(DISTINCT c.id) AS total_comments_made
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username;

-- Users Category Distribution
SELECT CASE WHEN score < 20 THEN 'Inactive'
            WHEN score <= 200 THEN 'Moderately Active'
            ELSE 'Highly Active' END AS category,
       COUNT(*) AS total_users
FROM (SELECT u.id,
        (SELECT COUNT(*) FROM photos p WHERE p.user_id = u.id)
      + (SELECT COUNT(*) FROM likes l WHERE l.user_id = u.id)
      + (SELECT COUNT(*) FROM comments c WHERE c.user_id = u.id) AS score
      FROM users u) t
GROUP BY category;

-- O3.
-- Calculate the average number of tags per post (photo_tags and photos
-- tables).

SELECT AVG(tag_count) AS AverageTags
FROM (
    SELECT p.id, COUNT(pt.tag_id) AS tag_count
    FROM photos p
    LEFT JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.id
) AS t;

-- O4.
-- Identify the top users with the highest engagement rates (likes, comments)
-- on their posts and rank them.

WITH photo_stats AS (
    SELECT p.user_id,
           (SELECT COUNT(*) FROM likes l WHERE l.photo_id = p.id) AS lk,
           (SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id) AS cm
    FROM photos p
),
owner_total AS (
    SELECT user_id, SUM(lk) + SUM(cm) AS Total
    FROM photo_stats
    GROUP BY user_id
    HAVING SUM(lk) > 0 AND SUM(cm) > 0
)
SELECT user_id, Total, RANK() OVER (ORDER BY Total DESC) AS rnk
FROM owner_total
ORDER BY rnk, user_id;

-- O5.
-- Which users have the highest number of followers and followings?

select
    u.id as user_id,
    u.username,
    coalesce(f.followers_count, 0) as followers,
    coalesce(fl.following_count, 0) as following
from users u
left join (
    select
        followee_id,
        count(*) as followers_count
    from follows
    group by followee_id
) f
    on u.id = f.followee_id
left join (
    select
        follower_id,
        count(*) as following_count
    from follows
    group by follower_id
) fl
    on u.id = fl.follower_id
order by followers desc,
         following desc;

-- O6.
-- Calculate the average engagement rate (likes, comments) per post for each
-- user.

WITH photo_eng AS (
    SELECT p.id AS photo_id,
           p.user_id,
           (SELECT COUNT(*) FROM likes l WHERE l.photo_id = p.id)
         + (SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id) AS eng
    FROM photos p
)
SELECT u.id,
       u.username,
       ROUND(AVG(pe.eng), 2) AS avg_engagement
FROM users u
JOIN photo_eng pe ON pe.user_id = u.id
GROUP BY u.id, u.username
ORDER BY avg_engagement DESC;

-- O7.
-- Get the list of users who have never liked any post (users and likes
-- tables)

SELECT
	u.id,
    u.username
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;

-- O8.
-- How can you leverage user-generated content (posts, hashtags, photo tags)
-- to create more personalized and engaging ad campaigns?

WITH photo_likes AS (
    SELECT photo_id, COUNT(*) AS likes_cnt FROM likes GROUP BY photo_id
),
photo_comments AS (
    SELECT photo_id, COUNT(*) AS comments_cnt FROM comments GROUP BY photo_id
)
SELECT u.id AS user_id,
       u.username,
       t.tag_name,
       COUNT(*) AS tag_usage,
       SUM(COALESCE(pl.likes_cnt, 0)) AS total_likes_received,
       SUM(COALESCE(pc.comments_cnt, 0)) AS total_comments_received,
       SUM(COALESCE(pl.likes_cnt, 0) + COALESCE(pc.comments_cnt, 0)) AS total_engagement
FROM users u
JOIN photos p ON p.user_id = u.id
JOIN photo_tags pt ON pt.photo_id = p.id
JOIN tags t ON t.id = pt.tag_id
LEFT JOIN photo_likes pl ON pl.photo_id = p.id
LEFT JOIN photo_comments pc ON pc.photo_id = p.id
GROUP BY u.id, u.username, t.tag_name
ORDER BY total_engagement DESC, u.id;

-- O9.
-- Are there any correlations between user activity levels and specific
-- content types (e.g., photos, videos, reels)? How can this information
-- guide content creation and curation strategies?

WITH photo_stats AS (
    SELECT p.user_id,
           (SELECT COUNT(*) FROM likes l WHERE l.photo_id = p.id) AS lk,
           (SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id) AS cm
    FROM photos p
)
SELECT user_id,
       COUNT(*) AS total_posts,
       SUM(lk) AS total_likes,
       SUM(cm) AS total_comments,
       SUM(lk + cm) AS total_engagement
FROM photo_stats
GROUP BY user_id
ORDER BY total_engagement DESC;

-- O10.
-- Calculate the total number of likes, comments, and photo tags for each
-- user.

SELECT u.id AS user_id,
       u.username,
       COALESCE(l.total_likes, 0)    AS total_likes,
       COALESCE(c.total_comments, 0) AS total_comments,
       COALESCE(t.total_tags, 0)     AS total_tags
FROM users u
LEFT JOIN (SELECT user_id, COUNT(*) AS total_likes FROM likes GROUP BY user_id) l
       ON u.id = l.user_id
LEFT JOIN (SELECT user_id, COUNT(*) AS total_comments FROM comments GROUP BY user_id) c
       ON u.id = c.user_id
LEFT JOIN (SELECT p.user_id, COUNT(*) AS total_tags
           FROM photo_tags pt
           JOIN photos p ON p.id = pt.photo_id
           GROUP BY p.user_id) t
       ON u.id = t.user_id
ORDER BY u.id;

-- O11.
-- Rank users based on their total engagement (likes, comments, shares) over a
-- month.

WITH monthly_likes AS (
    SELECT user_id, COUNT(*) AS likes_given
    FROM likes
    WHERE DATE_FORMAT(created_at, '%Y-%m') = (SELECT DATE_FORMAT(MAX(created_at), '%Y-%m') FROM likes)
    GROUP BY user_id
),
monthly_comments AS (
    SELECT user_id, COUNT(*) AS comments_made
    FROM comments
    WHERE DATE_FORMAT(created_at, '%Y-%m') = (SELECT DATE_FORMAT(MAX(created_at), '%Y-%m') FROM comments)
    GROUP BY user_id
),
monthly_engagement AS (
    SELECT u.id AS user_id,
           u.username,
           COALESCE(ml.likes_given, 0) AS likes_given,
           COALESCE(mc.comments_made, 0) AS comments_made,
           COALESCE(ml.likes_given, 0) + COALESCE(mc.comments_made, 0) AS total_engagement
    FROM users u
    LEFT JOIN monthly_likes ml    ON u.id = ml.user_id
    LEFT JOIN monthly_comments mc ON u.id = mc.user_id
)
SELECT user_id, username, likes_given, comments_made, total_engagement,
       RANK() OVER (ORDER BY total_engagement DESC) AS engagement_rank
FROM monthly_engagement
ORDER BY engagement_rank, user_id;

-- month wise total engagement
SELECT DATE_FORMAT(created_at, '%b-%y') AS month,
       COUNT(*) AS total_engagement
FROM (
    SELECT created_at FROM likes
    UNION ALL
    SELECT created_at FROM comments
) t
GROUP BY DATE_FORMAT(created_at, '%Y-%m'), DATE_FORMAT(created_at, '%b-%y')
ORDER BY DATE_FORMAT(created_at, '%Y-%m');

-- O12.
-- Retrieve the hashtags that have been used in posts with the highest average
-- number of likes. Use a CTE to calculate the average likes for each
-- hashtag first.

WITH hashtag_avg AS (
    SELECT t.id AS tag_id,
           t.tag_name,
           COUNT(l.photo_id) AS total_likes,
           COUNT(DISTINCT p.id) AS total_photos
    FROM tags t
    JOIN photo_tags pt ON pt.tag_id = t.id
    JOIN photos p ON p.id = pt.photo_id
    LEFT JOIN likes l ON l.photo_id = p.id
    GROUP BY t.id, t.tag_name
)
SELECT tag_id,
       tag_name,
       ROUND(total_likes / total_photos, 2) AS avg_likes_per_photo,
       total_likes,
       total_photos
FROM hashtag_avg
ORDER BY avg_likes_per_photo DESC
LIMIT 10;

-- O13.
-- Retrieve the users who have started following someone after being followed
-- by that person.

SELECT DISTINCT u.id, u.username
FROM users u
JOIN follows f1 ON f1.follower_id = u.id
JOIN follows f2 ON f2.follower_id = f1.followee_id
               AND f2.followee_id = f1.follower_id
ORDER BY u.id;


/* =====================================================================
   SUBJECTIVE QUESTIONS
   ===================================================================== */

-- S1.
-- Based on user engagement and activity levels, which users would you
-- consider the most loyal or valuable? How would you reward or incentivize
-- these users?

WITH photo_stats AS (
    SELECT p.user_id,
           (SELECT COUNT(*) FROM likes    l WHERE l.photo_id = p.id) AS lk,
           (SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id) AS cm
    FROM photos p
),
received AS (
    SELECT user_id, COUNT(*) AS total_posts, SUM(lk) AS likes_received, SUM(cm) AS comments_received
    FROM photo_stats
    GROUP BY user_id
),
followers AS (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
)
SELECT u.id AS user_id,
       u.username,
       r.total_posts,
       r.likes_received,
       r.comments_received,
       r.likes_received + r.comments_received AS engagement_received,
       (SELECT COUNT(*) FROM likes    l WHERE l.user_id = u.id) AS likes_given,
       (SELECT COUNT(*) FROM comments c WHERE c.user_id = u.id) AS comments_made,
       COALESCE(f.total_followers, 0) AS total_followers
FROM users u
JOIN received r        ON r.user_id = u.id
LEFT JOIN followers f  ON f.user_id = u.id
ORDER BY engagement_received DESC, total_followers DESC
LIMIT 10;

-- S2.
-- For inactive users, what strategies would you recommend to re-engage them
-- and encourage them to start posting or engaging again?

select
    u.id,
    u.username
from users u
left join photos p
    on u.id = p.user_id
left join likes l
    on u.id = l.user_id
left join comments c
    on u.id = c.user_id
where p.user_id is null
  and l.user_id is null
  and c.user_id is null;
  
  -- To check Whether the user is active or inactive
  SELECT 
    CASE WHEN p.user_id IS NULL AND l.user_id IS NULL AND c.user_id IS NULL 
         THEN 'Inactive' ELSE 'Active' END AS user_status,
    COUNT(*) AS total_users
FROM users u
LEFT JOIN (SELECT DISTINCT user_id FROM photos)   p ON u.id = p.user_id
LEFT JOIN (SELECT DISTINCT user_id FROM likes)    l ON u.id = l.user_id
LEFT JOIN (SELECT DISTINCT user_id FROM comments) c ON u.id = c.user_id
GROUP BY user_status;

-- S3.
-- Which hashtags or content topics have the highest engagement rates? How can
-- this information guide content strategy and ad campaigns?

select
    t.tag_name as hashtag,
    count(distinct l.user_id, l.photo_id) as total_likes,
    count(distinct c.id) as total_comments,
    count(distinct l.user_id, l.photo_id) + count(distinct c.id) as total_engagement
from tags t
join photo_tags pt
    on t.id = pt.tag_id
join photos p
    on pt.photo_id = p.id
left join likes l
    on p.id = l.photo_id
left join comments c
    on p.id = c.photo_id
group by t.tag_name
order by total_engagement desc
limit 10;

SELECT t.id, t.tag_name,
    (SELECT COUNT(*) FROM photo_tags pt WHERE pt.tag_id = t.id) AS tag_usage,
    (SELECT COUNT(*) FROM likes l
       JOIN photo_tags pt ON pt.photo_id = l.photo_id
      WHERE pt.tag_id = t.id)
  + (SELECT COUNT(*) FROM comments c
       JOIN photo_tags pt ON pt.photo_id = c.photo_id
      WHERE pt.tag_id = t.id) AS total_engagement
FROM tags t
ORDER BY t.id;

-- S4.
-- Are there any patterns or trends in user engagement based on demographics
-- (age, location, gender) or posting times? How can these insights inform
-- targeted marketing campaigns?

SELECT 
    HOUR(p.created_dat) AS post_hour,
    DAYOFWEEK(p.created_dat) AS post_day,
    COUNT(DISTINCT p.id) AS total_photos_posted,
    COUNT(DISTINCT l.user_id, l.photo_id) AS total_likes_received,
    COUNT(DISTINCT c.id) AS total_comments_received
FROM photos p
JOIN likes l ON p.id = l.photo_id
JOIN comments c ON p.id = c.photo_id
GROUP BY post_hour, post_day
ORDER BY post_hour, post_day;

-- S5.
-- Based on follower counts and engagement rates, which users would be ideal
-- candidates for influencer marketing campaigns? How would you approach
-- and collaborate with these influencers?

WITH photo_stats AS (
    SELECT p.user_id,
           (SELECT COUNT(*) FROM likes    l WHERE l.photo_id = p.id)
         + (SELECT COUNT(*) FROM comments c WHERE c.photo_id = p.id) AS eng
    FROM photos p
),
received AS (
    SELECT user_id, COUNT(*) AS total_posts, SUM(eng) AS total_engagement
    FROM photo_stats
    GROUP BY user_id
),
followers AS (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
)
SELECT u.id AS user_id,
       u.username,
       r.total_posts,
       r.total_engagement,
       f.total_followers,
       ROUND(r.total_engagement / r.total_posts, 2) AS engagement_rate_per_post
FROM users u
JOIN received r  ON r.user_id = u.id
JOIN followers f ON f.user_id = u.id
ORDER BY engagement_rate_per_post DESC, total_followers DESC
LIMIT 10;

-- S6.
-- Based on user behavior and engagement data, how would you segment the user
-- base for targeted marketing campaigns or personalized recommendations?

SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) AS total_engagement,
    CASE
		WHEN COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) > 150 THEN 'Highly Engaged'
		WHEN COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) BETWEEN 100 AND 150 THEN 'Moderately Engaged'
		ELSE 'Less Engaged' END AS user_category,
    CASE 
	WHEN YEAR(u.created_at) >= 2017 THEN 'New_User'
	ELSE 'Old_User' END AS user_join_status
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_likes
    FROM ig_clone.likes
    GROUP BY user_id) l ON u.id = l.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id) c ON u.id = c.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id) p ON u.id = p.user_id
GROUP BY u.id
HAVING total_posts > 0 
ORDER BY total_engagement DESC, user_category;

-- S7.
-- If data on ad campaigns (impressions, clicks, conversions) is available,
-- how would you measure their effectiveness and optimize future campaigns?

-- ****** Answered in Documented pdf file ******

-- S8.
-- How can you use user activity data to identify potential brand ambassadors
-- or advocates who could help promote Instagram's initiatives or events?

-- ****** Answered in Documented pdf file ******

-- S9.
-- How would you approach this problem, if the objective and subjective
-- questions weren't given?

-- ****** Answered in Documented pdf file ******

-- S10.
-- Assuming there's a "User_Interactions" table tracking user engagements, how
-- can you update the "Engagement_Type" column to change all instances of
-- "Like" to "Heart" to align with Instagram's terminology?

CREATE TABLE User_Interactions(
	id INT AUTO_INCREMENT UNIQUE PRIMARY KEY,
	username VARCHAR(250) NOT NULL,
	Engagement_Type varchar(250) not null
);

INSERT INTO User_Interactions (username,Engagement_Type ) VALUES 
('Kenton_Kirlin', 'Like'),
('Andre_Purdy85', 'Comments'), 
('Harley_Lind18', 'Comments'),
 ('Arely_Bogan63', 'Comments'), 
 ('Aniya_Hackett', 'Like'), 
 ('Travon.Waters', 'Like'), 
 ('Kasandra_Homenick', 'Comments'), 
 ('Tabitha_Schamberger11', 'Comments'),
 ('Gus93', 'Like'), 
 ('Presley_McClure', 'Comments'), 
 ('Justina.Gaylord27', 'Like'), 
 ('Dereck65', 'Comments'), 
 ('Alexandro35', 'Comments'), 
 ('Jaclyn81', 'Comments'), 
 ('Billy52', 'Like'), 
 ('Annalise.McKenzie16', 'Comments'), 
 ('Norbert_Carroll35', 'Like'), 
 ('Odessa2', 'Comments'), 
 ('Hailee26', 'Comments'), 
 ('Delpha.Kihn', 'Like'), 
 ('Rocio33', 'Like'), 
 ('Kenneth64', 'Like'), 
 ('Eveline95', 'Like'),
 ('Maxwell.Halvorson', 'Like'), 
 ('Tierra.Trantow', 'Like'),
 ('Josianne.Friesen', 'Like'), 
 ('Darwin29', 'Like'), 
 ('Dario77', 'Like'),
 ('Jaime53', 'Comments'),
 ('Kaley9', 'Comments'), 
 ('Aiyana_Hoeger', 'Like'), 
 ('Irwin.Larson', 'Like'), 
 ('Yvette.Gottlieb91', 'Comments'), 
 ('Pearl7', 'Like'), 
 ('Lennie_Hartmann40', 'Comments'), 
 ('Ollie_Ledner37', 'Like'), 
 ('Yazmin_Mills95', 'Comments'), 
 ('Jordyn.Jacobson2', 'Like'), 
 ('Kelsi26', 'Like'), 
 ('Rafael.Hickle2', 'Comments'), 
 ('Mckenna17', 'Like'), 
 ('Maya.Farrell', 'Comments'), 
 ('Janet.Armstrong', 'Like'), 
 ('Seth46', 'Comments'), 
 ('David.Osinski47', 'Like'), 
 ('Malinda_Streich', 'Comments'), 
 ('Harrison.Beatty50', 'Like'), 
 ('Granville_Kutch', 'Comments'), 
 ('Morgan.Kassulke', 'Like'), 
 ('Gerard79', 'Comments'), 
 ('Mariano_Koch3', 'Comments'), 
 ('Zack_Kemmer93', 'Like'), 
 ('Linnea59', 'Comments'), 
 ('Duane60', 'Comments'), 
 ('Meggie_Doyle', 'Like'), 
 ('Peter.Stehr0', 'Comments'), 
 ('Julien_Schmidt', 'Like'), 
 ('Aurelie71', 'Comments'), 
 ('Cesar93', 'Comments'), 
 ('Sam52', 'Like'), 
 ('Jayson65', 'Comments'), 
 ('Ressie_Stanton46', 'Like'), 
 ('Elenor88', 'Comments'), 
 ('Florence99', 'Like'), 
 ('Adelle96', 'Comments'), 
 ('Mike.Auer39', 'Comments'), 
 ('Emilio_Bernier52', 'Like'), 
 ('Franco_Keebler64', 'Comments'), 
 ('Karley_Bosco', 'Like'), 
 ('Erick5', 'Comments'), 
 ('Nia_Haag', 'Like'), 
 ('Kathryn80', 'Comments'), 
 ('Jaylan.Lakin', 'Like'), 
 ('Hulda.Macejkovic', 'Comments'), 
 ('Leslie67', 'Comments'), 
 ('Janelle.Nikolaus81', 'Like'), 
 ('Donald.Fritsch', 'Comments'), 
 ('Colten.Harris76', 'Like'), 
 ('Katarina.Dibbert', 'Comments'), 
 ('Darby_Herzog', 'Comments'), 
 ('Esther.Zulauf61', 'Like'), 
 ('Aracely.Johnston98', 'Comments'), 
 ('Bartholome.Bernhard', 'Comments'), 
 ('Alysa22', 'Comments'), 
 ('Milford_Gleichner42', 'Like'), 
 ('Delfina_VonRueden68', 'Comments'), 
 ('Rick29', 'Like'), 
 ('Clint27', 'Comments'), 
 ('Jessyca_West', 'Comments'), 
 ('Esmeralda.Mraz57', 'Like'), 
 ('Bethany20', 'Comments'), 
 ('Frederik_Rice', 'Comments'), 
 ('Willie_Leuschke', 'Like'), 
 ('Damon35', 'Comments'), 
 ('Nicole71', 'Comments'), 
 ('Keenan.Schamberger60', 'Like'), 
 ('Tomas.Beatty93', 'Comments'), 
 ('Imani_Nicolas17', 'Like'), 
 ('Alek_Watsica', 'Comments'), 
 ('Javonte83', 'Like');
 
 SET SQL_SAFE_UPDATES = 0;
 
 update  User_Interactions 
 set  Engagement_Type = "Heart" 
 where Engagement_Type= "Like";
 
select * from User_Interactions; 

/* ===================================== END OF FILE ===================================== */
