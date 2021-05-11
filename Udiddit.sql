

-- a. Allow new users to register:

CREATE TABLE "users" (
    "user_id" SERIAL PRIMARY KEY ,
    "username" VARCHAR(25) UNIQUE NOT NULL CHECK (LENGTH(TRIM("username"))> 0),
    "last_login" TIMESTAMP)
;

CREATE INDEX ON "users" ("username")
;


-- b. Allow registered users to create new topics:

CREATE TABLE "topics" (
    "topic_id" SERIAL PRIMARY KEY ,
    "topic_name" VARCHAR(30) UNIQUE NOT NULL CHECK (LENGTH(TRIM("topic_name"))> 0),
    "topic_desc" VARCHAR(500)
)
;

CREATE INDEX ON "topics" ("topic_name")
;


-- c. Allow registered users to create new posts on existing topics:

CREATE TABLE "posts" (
    "post_id" SERIAL PRIMARY KEY ,
    "post_title" VARCHAR(100) NOT NULL CHECK (LENGTH(TRIM("post_title"))> 0),
    "topic_id" INT REFERENCES "topics" ("topic_id") ON DELETE CASCADE,
    "user_id" INT REFERENCES "users" ("user_id") ON DELETE SET NULL,
    "url" VARCHAR(500),
    "text_content" TEXT,
    CONSTRAINT url_text CHECK (("url" IS NULL AND "text_content" IS NOT NULL) OR
    ("url" IS NOT NULL AND "text_content" IS NULL)))
;

CREATE INDEX ON "posts" ("url")
;


-- d. Allow registered users to comment on existing posts:


CREATE TABLE "comments" (
    "comment_id" SERIAL PRIMARY KEY,
    "parent_comment_id" INT REFERENCES "comments" ("comment_id") ON DELETE CASCADE,
    "post_id" INT REFERENCES "posts" ("post_id") ON DELETE CASCADE,
    "user_id" INT REFERENCES "users" ("user_id") ON DELETE SET NULL,
    "text" TEXT NOT NULL)
;


-- e. Make sure that a given user can only vote once on a given post:

CREATE TABLE "votes" (
    "vote_id" SERIAL PRIMARY KEY,
    "post_id" INT REFERENCES "posts" ("post_id") ON DELETE CASCADE,
    "user_id" INT REFERENCES "users" ("user_id") ON DELETE SET NULL,
    "vote" SMALLINT CHECK ( "vote" = 1 OR "vote" = -1 ),
    CONSTRAINT "unique_vote" UNIQUE ("user_id", "post_id"))
;




-- Migration of users from the bad_posts and bad_comments tables to the users table

INSERT INTO "users" ("username")
    SELECT DISTINCT "username" FROM "bad_posts"
    UNION
    SELECT DISTINCT "username" FROM "bad_comments"
    UNION
    SELECT DISTINCT REGEXP_SPLIT_TO_TABLE("upvotes" , ',') FROM "bad_posts"
    UNION
    SELECT DISTINCT REGEXP_SPLIT_TO_TABLE("downvotes" , ',') FROM "bad_posts"
;



-- Migration of topics from bad_posts to the topics table

INSERT INTO "topics" ("topic_name")
    SELECT DISTINCT "topic"
    FROM "bad_posts"
;


-- Migration of posts from bad_posts to posts table

INSERT INTO "posts" ("post_title", "topic_id", "user_id", "url", "text_content")
    SELECT SUBSTRING ("bp" . "title" , 1, 100), "ts" . "topic_id" , "u" . "user_id",
        "bp" . "url" , "bp" . "text_content"
    FROM "bad_posts" "bp"
    JOIN "topics" "ts"
        ON "bp" . "topic" = "ts" . "topic_name"
    JOIN "users" "u"
        ON "bp" . "username" = "u" . "username"
;

-- Migration of comments from bad_comments to comments table

INSERT INTO "comments" ("post_id", "user_id", "text")
    SELECT "po" . "post_id" , "u" . "user_id" , "bc" . "text_content"
    FROM "bad_comments" "bc"
    JOIN "posts" "po"
        ON "bc" . "post_id" = "po" . "post_id"
    JOIN "users" "u"
        ON "bc" . "username" = "u" . "username"
;


-- Migration of up- and downvotes from bad_posts to votes table

--- upvotes

INSERT INTO "votes" ("post_id", "user_id", "vote")
    SELECT "bp" . "id", "u" . "user_id", 1 AS "up_vote"
    FROM (
        SELECT "id" , REGEXP_SPLIT_TO_TABLE("upvotes" , ',') AS "upvotes"
        FROM "bad_posts") "bp"
        JOIN "users" "u"
            ON "bp" . "upvotes" = "u" . "username"
;


--- downvotes

INSERT INTO "votes" ("post_id", "user_id", "vote")
    SELECT "bp" . "id" , "u" . "user_id" , -1 AS "downvote"
    FROM (
        SELECT "id" , REGEXP_SPLIT_TO_TABLE("downvotes" , ',') AS "downvotes"
        FROM "bad_posts" ) "bp"
            JOIN "users" "u"
                ON "bp" . "downvotes" = "u" . "username"
 ;


















