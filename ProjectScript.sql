/*Create & Populate Database*/
@C:\prjScript.sql

/*Task 1.1*/
SELECT CONSTRAINT_NAME, TABLE_NAME
FROM USER_CONSTRAINTS
WHERE TABLE_NAME = 'FILM'
OR TABLE_NAME = 'FILM_CATEGORY' 
OR TABLE_NAME = 'FILM_ACTOR'  
OR TABLE_NAME = 'ACTOR' OR TABLE_NAME = 'CATEGORY' 
OR TABLE_NAME = 'FILM_CATEGORY'
OR TABLE_NAME = 'LANGUAGE';

/*Task 1.2*/
ALTER TABLE category 
ADD CONSTRAINT PK_CATEGORYID PRIMARY KEY (category_id); 

ALTER TABLE language 
ADD CONSTRAINT PK_LANGUAGEID PRIMARY KEY (language_id);

ALTER TABLE film 
ADD CONSTRAINT UN_DESCRIPTION UNIQUE (description); 

ALTER TABLE actor 
ADD CONSTRAINT CK_FNAME CHECK (first_name IS NOT NULL); 

ALTER TABLE actor 
ADD CONSTRAINT CK_LNAME CHECK (last_name IS NOT NULL); 

ALTER TABLE category 
ADD CONSTRAINT CK_CATNAME CHECK (name IS NOT NULL);

ALTER TABLE language
ADD CONSTRAINT CK_LANNAME CHECK (name IS NOT NULL);

ALTER TABLE film ADD CONSTRAINT CK_TITLE CHECK (title IS NOT NULL);

ALTER TABLE film ADD CONSTRAINT CK_RELEASEYR CHECK (release_year <= 2020);

ALTER TABLE film 
ADD CONSTRAINT CK_RATING CHECK (rating IN ('G', 'PG', 'PG-13', 'R', 'NC-17'));

ALTER TABLE film 
ADD CONSTRAINT CK_SPLFEATURES CHECK (special_features IN (NULL, 'Trailers', 'Commentaries', 'Deleted Scenes', 'Behind the Scenes'));

ALTER TABLE film 
ADD CONSTRAINT FK_LANGUAGEID FOREIGN KEY (language_id) 
REFERENCES language (language_id); 

ALTER TABLE film
ADD CONSTRAINT FK_ORLANGUAGEID FOREIGN KEY (original_language_id) 
REFERENCES language (language_id); 

ALTER TABLE film_actor 
ADD CONSTRAINT FK_ACTORID FOREIGN KEY (actor_id) 
REFERENCES actor (actor_id); 

ALTER TABLE film_category 
ADD CONSTRAINT FK_CATEGORYID FOREIGN KEY (category_id) 
REFERENCES category (category_id); 

ALTER TABLE film_category 
ADD CONSTRAINT FK_FILMID2 FOREIGN KEY (film_id) REFERENCES film (film_id);

/*Task 2.1*/
CREATE SEQUENCE "FILM_ID_SEQ"
INCREMENT BY 10 START WITH 20010; 

/*Task 2.2*/
CREATE OR REPLACE TRIGGER "BI_FILM_ID"
	BEFORE INSERT ON "FILM"
	FOR EACH ROW
BEGIN
	SELECT "FILM_ID_SEQ".NEXTVAL INTO :NEW.film_id FROM DUAL;
END;
/

/*Task 2.3*/

CREATE OR REPLACE TRIGGER "BI_FILM_DESP"
	BEFORE INSERT ON "FILM"
	FOR EACH ROW
DECLARE
	fid NUMBER(5);
	dscrt varchar2(255);
	rate varchar2(8);
	lang varchar2(25);
	lang_id NUMBER(3);
	ori_lang_id NUMBER(3);
	ori_lang varchar2(25);
	seq INTEGER;
	result varchar2(255);
BEGIN
	SELECT :NEW.film_id INTO fid FROM DUAL;
	SELECT :NEW.description INTO dscrt FROM DUAL;
	SELECT :NEW.rating INTO rate FROM DUAL;
	SELECT :NEW.language_id INTO lang_id FROM DUAL;
	SELECT :NEW.original_language_id INTO ori_lang_id FROM DUAL;
	
	
	IF ((rate IS NOT NULL) AND (ori_lang_id IS NOT NULL) AND (lang_id IS NOT NULL)) THEN 
	
		SELECT COUNT(*) INTO seq FROM FILM WHERE rating = rate;
		SELECT L.name INTO lang FROM LANGUAGE L WHERE lang_id = L.language_id;
		SELECT L.name INTO ori_lang FROM LANGUAGE L WHERE ori_lang_id = L.language_id;
	
		seq:= seq + 1;
		result:= CONCAT(
				CONCAT(
					CONCAT
						(CONCAT
							(CONCAT
								(CONCAT
									(CONCAT
										(CONCAT
											(CONCAT(dscrt ,'.'),rate)
												, '-'), TO_CHAR(seq))
													, ': Originally in ')
														, lang)
															,'. Re-released in ')
																, ori_lang), '.'); 
		SELECT result INTO :NEW.description FROM DUAL;
	END IF;
END;
/

/*Task 3.1*/
SELECT title, length
FROM FILM F, FILM_CATEGORY F1, CATEGORY C1
WHERE F.film_id = F1.film_id AND C1.category_id = C1.category_id
AND C1.name = 'Action' AND F.length =
	(SELECT MIN(length)
	FROM FILM F, FILM_CATEGORY F1, CATEGORY C1
	WHERE F.film_id = F1.film_id AND F1.category_id = C1.category_id
	AND C1.name = 'Action');

/*Task 3.2*/
CREATE VIEW MIN_ACTION_ACTORS AS
SELECT DISTINCT(A.actor_id),A.first_name, A.last_name
FROM actor A, film_actor F1
WHERE A.actor_id = F1.actor_id 
AND F1.film_id IN (SELECT F.film_id
	FROM FILM F, FILM_CATEGORY F1, CATEGORY C1
	WHERE F.film_id = F1.film_id AND F1.category_id = C1.category_id
	AND C1.name = 'Action' AND F.length =
		(SELECT MIN(length)
		FROM FILM F, FILM_CATEGORY F1, CATEGORY C1
		WHERE F.film_id = F1.film_id AND F1.category_id = C1.category_id
		AND C1.name = 'Action'));
	
/*Task 3.3*/
CREATE VIEW V_ACTION_ACTORS_2012 AS 
SELECT DISTINCT(A.actor_id), A.first_name, A.last_name
FROM actor A, film_actor FA, film F, film_category F1, category C
WHERE A.actor_id = FA.actor_id AND FA.film_id = F.film_id AND F.release_year = 2012 
AND F.film_id = F1.film_id AND F1.category_id = C.category_id AND C.name = 'Action';

/*Task 3.4*/
CREATE MATERIALIZED VIEW MV_ACTION_ACTORS_2012
BUILD IMMEDIATE
AS
SELECT DISTINCT(A.actor_id), A.first_name, A.last_name
FROM actor A, film_actor FA, film F, film_category F1, category C
WHERE A.actor_id = FA.actor_id AND FA.film_id = F.film_id AND F.release_year = 2012 
AND F.film_id = F1.film_id AND F1.category_id = C.category_id AND C.name = 'Action';

/*Task 3.5*/
SET TIMING ON;

SELECT * FROM V_ACTION_ACTORS_2012;
SELECT * FROM MV_ACTION_ACTORS_2012;

EXPLAIN PLAN FOR SELECT * FROM V_ACTION_ACTORS_2012;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR SELECT * FROM MV_ACTION_ACTORS_2012;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);


/*Task 4.1*/
SELECT title
FROM film F
WHERE INSTR(F.description, 'Boat') > 0
ORDER BY title ASC
FETCH FIRST 100 ROWS ONLY;

/*Task 4.2*/
CREATE INDEX IDX_BOAT ON film(INSTR(description, 'Boat'));

/*Task 4.3*/
EXPLAIN PLAN FOR SELECT title
FROM film F
WHERE INSTR(F.description, 'Boat') > 0
ORDER BY title ASC
FETCH FIRST 100 ROWS ONLY;
SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);

/*Task 4.4*/
SELECT SUM(COUNT(*))
FROM film
GROUP BY release_year, rating, special_features
HAVING COUNT(*) >= 40;

/*Task 5.1*/
ANALYZE INDEX PK_FILMID VALIDATE STRUCTURE;
SELECT HEIGHT, LF_BLKS, BLKS_GETS_PER_ACCESS FROM INDEX_STATS;

ANALYZE TABLE film VALIDATE STRUCTURE;
SELECT TABLE_NAME, BLOCKS FROM USER_TABLES WHERE TABLE_NAME = 'FILM';

/*Task 5.2*/
EXPLAIN PLAN FOR SELECT /*+RULE*/* FROM FILM WHERE FILM_ID > 100;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);

/*Task 5.3*/
EXPLAIN PLAN FOR SELECT * FROM FILM WHERE FILM_ID > 100;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);

/*Task 5.4*/
EXPLAIN PLAN FOR SELECT * FROM FILM WHERE FILM_ID > 19990;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);

/*Task 5.5*/
EXPLAIN PLAN FOR SELECT * FROM FILM WHERE FILM_ID = 100;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY);
