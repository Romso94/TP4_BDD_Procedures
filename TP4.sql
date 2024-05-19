DROP PROCEDURE IF EXISTS generer_rapport_etudiant;
DROP PROCEDURE IF EXISTS liste_cours_etudiant;
DROP PROCEDURE IF EXISTS liste_cours_etudiant2;
DROP PROCEDURE IF EXISTS liste_cours_etudiants_unifies;
DELIMITER //
CREATE PROCEDURE generer_rapport_etudiant (IN sid INT)
BEGIN    
    -- Récupérer les infos de l'étudiant
    SELECT CONCAT('Etudiant : ',ELEVES.NOM, ' ', PRENOM,'- Année : ',ELEVES.ANNEE) AS 'Infos Etudiants' FROM ELEVES WHERE NUM_ELEVE = sid;    
    -- Récuperer les cours professeurs et score pour chaque élèves
    SELECT DISTINCT C.NOM AS "Cours",P.NOM AS "Professeur", R.POINTS AS "Score"
	FROM COURS C
	JOIN CHARGE CH ON C.NUM_COURS = CH.NUM_COURS
	JOIN PROFESSEURS P ON CH.NUM_PROF = P.NUM_PROF
	JOIN RESULTATS R ON C.NUM_COURS = R.NUM_COURS
	WHERE R.NUM_ELEVE = 2;
    -- Récuperer les Activités 
    SELECT NOM As "Activité" FROM activites_pratiquees where NUM_ELEVE= sid;
END//
DELIMITER ;
DELIMITER //
CREATE PROCEDURE liste_cours_etudiant (IN sid INT)
BEGIN    
    DECLARE fin BOOLEAN DEFAULT FALSE;
    DECLARE cours_id INT;
    DECLARE score DECIMAL(5,2);
    DECLARE cur CURSOR FOR
        SELECT C.NUM_COURS, R.POINTS
        FROM COURS C
        LEFT JOIN RESULTATS R ON C.NUM_COURS = R.NUM_COURS AND R.NUM_ELEVE = sid;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin = TRUE;
    OPEN cur;
    courses_loop: LOOP
        FETCH cur INTO cours_id, score;
        IF fin THEN
            LEAVE courses_loop;
        END IF;
        IF score IS NOT NULL THEN
			SELECT C.NOM as 'Cours',score 
			FROM COURS C
			WHERE C.NUM_COURS = cours_id;
        END IF;
    END LOOP;
    CLOSE cur;
END//
DELIMITER ;
DELIMITER //
CREATE TEMPORARY TABLE IF NOT EXISTS temp_results (
    cours INT,
    score DECIMAL(5,2)
);
CREATE PROCEDURE liste_cours_etudiant2 (IN sid INT)
BEGIN    
    DECLARE fin BOOLEAN DEFAULT FALSE;
    DECLARE cours_id INT;
    DECLARE score DECIMAL(5,2);
    DECLARE cur CURSOR FOR
        SELECT C.NUM_COURS, R.POINTS
        FROM COURS C
        LEFT JOIN RESULTATS R ON C.NUM_COURS = R.NUM_COURS AND R.NUM_ELEVE = sid;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin = TRUE;
    OPEN cur;
    courses_loop: LOOP
        FETCH cur INTO cours_id, score;
        IF fin THEN
            LEAVE courses_loop;
        END IF;
        IF score IS NOT NULL THEN
            INSERT INTO temp_results (cours, score) VALUES (cours_id, score);
        END IF;
    END LOOP;
    CLOSE cur;
    SELECT C.NOM AS 'Cours', TR.score
    FROM temp_results TR
    JOIN COURS C ON TR.cours = C.NUM_COURS;
	DROP TEMPORARY TABLE IF EXISTS temp_results;
END//
DELIMITER ;
DELIMITER //
CREATE TEMPORARY TABLE IF NOT EXISTS temp_results2 (
    cours INT,
    score DECIMAL(5,2)
);
CREATE PROCEDURE liste_cours_etudiants_unifies (IN sid INT)
BEGIN
    DECLARE fin BOOLEAN DEFAULT FALSE;
    DECLARE cours_id INT;
    DECLARE score DECIMAL(5,2);
    DECLARE cur CURSOR FOR
        SELECT C.NUM_COURS, R.POINTS
        FROM COURS C
        LEFT JOIN RESULTATS R ON C.NUM_COURS = R.NUM_COURS AND R.NUM_ELEVE = sid;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin = TRUE;
    OPEN cur;
    courses_loop: LOOP
        FETCH cur INTO cours_id, score;
        IF fin THEN
            LEAVE courses_loop;
        END IF;
        IF score IS NOT NULL THEN
            INSERT INTO temp_results2 (cours, score) VALUES (cours_id, score);
        END IF;
    END LOOP;
    CLOSE cur;
    SELECT C.NOM AS 'Cours', TR.score
    FROM temp_results2 TR
    JOIN COURS C ON TR.cours = C.NUM_COURS;
    DROP TEMPORARY TABLE IF EXISTS temp_results2;
END//
DELIMITER ;
DELIMITER //
CREATE FUNCTION etudiant_a_réussi(sid INT)
RETURNS VARCHAR(3)
DETERMINISTIC
BEGIN
    DECLARE moyenne FLOAT;
    DECLARE resultat VARCHAR(3);
    SELECT AVG(points) INTO moyenne
    FROM RESULTATS
    WHERE NUM_ELEVE = sid;
    IF moyenne >= 10 THEN
        SET resultat = 'Oui';
    ELSE
        SET resultat = 'Non';
    END IF;

    RETURN resultat;
END //
DELIMITER ;



CALL generer_rapport_etudiant(2);
CALL liste_cours_etudiant(4);
CALL liste_cours_etudiant2(4);
CALL liste_cours_etudiants_unifies(4);
SELECT etudiant_a_réussi(4);
