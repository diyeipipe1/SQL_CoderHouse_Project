USE ciudadela_universitaria;

/*
	De acuerdo con el número de personas que deseen ingresar a la ciudadela, la función retorna el número de 
    apartamentos totales entre todas las acomodaciones para ese número de personas o un número mayor.
    Asume que el nombre de columna será uno válido.
*/
DELIMITER $
CREATE FUNCTION `fnum_aptos_x_gente`  (numPersonas INT)
RETURNS INT
DETERMINISTIC

BEGIN
	DECLARE numAptos INT;
    SET numAptos = (SELECT SUM(acom.totales)-COUNT(contr.acomoda_id) AS restantes 
					FROM acomodacion as acom
					LEFT JOIN contratos as contr ON acom.acomoda_id = contr.acomoda_id
					WHERE num_cuartos>= numPersonas);
    RETURN numAptos;
END
$
DELIMITER ;


/*
	Retorna el número de residentes con un puntaje de gravedad mayor o igual al ingresado por parámetro
*/
DELIMITER $
CREATE FUNCTION `fnum_gente_grave`  (puntajeGrav INT)
RETURNS INT
DETERMINISTIC

BEGIN
	DECLARE numPersona INT;
    SET numPersona = (SELECT COUNT(*) 
					  FROM (
						SELECT IFNULL(SUM(anot.gravedad), 0) AS suma_anots
						FROM vbase_datos_lookat as vbd
						LEFT JOIN anotaciones as anot ON vbd.resident_id = anot.resident_id
						GROUP BY vbd.resident_id) AS t
					  WHERE suma_anots>=puntajeGrav);
    RETURN numPersona;
END
$
DELIMITER ;