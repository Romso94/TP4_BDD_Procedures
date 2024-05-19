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

CREATE TABLE resultats_changements_log (
    num_eleve INT,
    num_cours INT,
    ancienne_valeur INT,
    nouvelle_valeur INT,
    date_changement DATE
);


DELIMITER //
CREATE TRIGGER audit_résultats_changements
BEFORE UPDATE ON RESULTATS
FOR EACH ROW
BEGIN
    INSERT INTO resultats_changements_log (num_eleve, num_cours, ancienne_valeur, nouvelle_valeur, date_changement)
    VALUES (OLD.NUM_ELEVE, OLD.NUM_COURS, OLD.POINTS, NEW.POINTS, CURDATE());
END //
DELIMITER ;
DELIMITER //
CREATE TRIGGER empecher_suppression_prof
BEFORE DELETE ON PROFESSEURS
FOR EACH ROW
BEGIN
    IF (EXISTS (SELECT 1 FROM CHARGE WHERE NUM_PROF = OLD.NUM_PROF)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Impossible de supprimer le professeur car il est encore affecté à un cours.';
    END IF;
END //

DELIMITER ;
DELIMITER //
CREATE TRIGGER limite_inscriptions_cours
BEFORE INSERT ON RESULTATS
FOR EACH ROW
BEGIN
    DECLARE total_inscriptions INT;
    SELECT COUNT(*)
    INTO total_inscriptions
    FROM RESULTATS
    WHERE NUM_COURS = NEW.NUM_COURS;
    IF total_inscriptions >= 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Limite d\'inscription pour ce cours  atteinte.';
    END IF;
END //
DELIMITER ;

UPDATE RESULTATS
SET POINTS = 18
WHERE NUM_ELEVE = 1 AND NUM_COURS = 1;




INSERT INTO RESULTATS (NUM_ELEVE, NUM_COURS, POINTS) VALUES (1, 1, 12);
CALL generer_rapport_etudiant(2);
CALL liste_cours_etudiant(4);
CALL liste_cours_etudiants_unifies(4);
SELECT etudiant_a_réussi(4);
SELECT * FROM resultats_changements_log;
DELETE FROM PROFESSEURS WHERE NUM_PROF = 1;
