USE ciudadela_universitaria;

/*
	Estos SP se crean siguiendo las instrucciones de la asignación de la semana.
    Se pide que el primer SP reciba un parámetro de acuerdo con el cual ordenar una tabla
    y un segundo parámetro que indique si será ascendiente o descendiente. 
    Asume que el nombre de columna ingresado será válido.
*/
DELIMITER $
CREATE PROCEDURE `sp_ordenar_residentes` (IN columnName VARCHAR(50), IN determOrder VARCHAR(10))
BEGIN
	-- Si los parámetros son diferentes a nulo, genere error y retorne eso mismo
	IF columnName<>'' AND (determOrder IN ('ASC','DESC')) THEN
		SET @params = 1;
	ELSE
		SET @params = 0;
        SET @mensajeError = "SELECT \'Revise los parámetros ingresados' AS Error";
        PREPARE querySQL FROM @mensajeError;
        EXECUTE querySQL;
        DEALLOCATE PREPARE querySQL;
	END IF;
    
    -- Consulta armada, asume que 
    IF @params = 1 THEN
		SET @mensajeQuery = CONCAT('SELECT * FROM ciudadela_universitaria.residentes ORDER BY ',columnName,' ',determOrder);
        PREPARE querySQL FROM @mensajeQuery;
        EXECUTE querySQL;
        DEALLOCATE PREPARE querySQL;
	END IF;
END $
DELIMITER ;

/*
	Se solicita que el segundo SP pueda ingresar datos en una tabla
*/
DELIMITER $
CREATE PROCEDURE `sp_insertar_anotacion` (IN resident_id INT, IN gravedad INT, IN descripcion VARCHAR(250), IN mentor_id INT)
BEGIN
	SET @mentor_id_max = (SELECT MAX(mentor_id) FROM mentores);
	IF resident_id<>'' AND (gravedad BETWEEN 0 AND 10) AND descripcion<>'' AND (mentor_id BETWEEN 1 AND @mentor_id_max) THEN
		SET @mensajeQuery = CONCAT('INSERT INTO ciudadela_universitaria.anotaciones(resident_id, gravedad, descripcion, mentor_id, fecha) VALUES(',resident_id,', ',gravedad,',"',descripcion,'",',mentor_id,', CURRENT_TIMESTAMP)');
        PREPARE querySQL FROM @mensajeQuery;
        EXECUTE querySQL;
        DEALLOCATE PREPARE querySQL;
    ELSE
		SET @mensajeError = "SELECT \'Revise los parámetros ingresados' AS Error";
        PREPARE querySQL FROM @mensajeError;
        EXECUTE querySQL;
        DEALLOCATE PREPARE querySQL;
    END IF;
END $
DELIMITER ;