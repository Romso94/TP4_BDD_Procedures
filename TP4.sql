DROP PROCEDURE IF EXISTS generer_rapport_etudiant;
DROP PROCEDURE IF EXISTS liste_cours_etudiant;

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

CALL generer_rapport_etudiant(2);

CALL liste_cours_etudiant(4);

